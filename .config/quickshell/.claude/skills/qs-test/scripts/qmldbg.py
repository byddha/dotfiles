#!/usr/bin/env python3
"""Minimal client for Qt's QML debug protocol (EngineDebugService, "QmlDebugger").

Talks to a Qt app started with a QML debug port (quickshell: `qs --debug PORT`). Based on qtdeclarative 6.11:
src/qmldebug/qqmldebugconnection.cpp, src/plugins/qmltooling/qmldbg_debugger/qqmlenginedebugservice.cpp,
src/plugins/qmltooling/packetprotocol/qpacketprotocol.cpp.

Framing: each packet = little-endian qint32 total size (including these 4 bytes) + QDataStream payload
(big-endian). Control packets start with QString "QDeclarativeDebugServer"/"QDeclarativeDebugClient";
service packets are QString service name + QByteArray message.
"""
import itertools
import socket
import struct

SERVER_ID = "QDeclarativeDebugServer"
CLIENT_ID = "QDeclarativeDebugClient"
SERVICE = "QmlDebugger"
DATASTREAM_VERSION = 20  # QDataStream::Qt_6_0; the server answers with the version both sides use


class Writer:
    def __init__(self):
        self.b = bytearray()

    def int(self, v):
        self.b += struct.pack(">i", v)
        return self

    def bool(self, v):
        self.b += b"\x01" if v else b"\x00"
        return self

    def str(self, s):
        data = s.encode("utf-16-be")
        self.b += struct.pack(">I", len(data)) + data
        return self

    def bytes(self, data):
        self.b += struct.pack(">I", len(data)) + data
        return self

    def strlist(self, items):
        self.b += struct.pack(">I", len(items))
        for s in items:
            self.str(s)
        return self


class Reader:
    def __init__(self, data):
        self.d = data
        self.p = 0

    def take(self, n):
        v = self.d[self.p:self.p + n]
        self.p += n
        return v

    def at_end(self):
        return self.p >= len(self.d)

    def int(self):
        return struct.unpack(">i", self.take(4))[0]

    def uint(self):
        return struct.unpack(">I", self.take(4))[0]

    def bool(self):
        return self.take(1) != b"\x00"

    def double(self):
        return struct.unpack(">d", self.take(8))[0]

    def str(self):
        n = self.uint()
        return "" if n == 0xFFFFFFFF else self.take(n).decode("utf-16-be")

    def bytes(self):
        n = self.uint()
        return b"" if n == 0xFFFFFFFF else self.take(n)

    def strlist(self):
        return [self.str() for _ in range(self.uint())]

    def variant(self):
        # Qt 6 QVariant: quint32 type id, qint8 is-null, then the value. Only the types we ask for.
        type_id = self.uint()
        self.take(1)
        if type_id == 10:  # QString
            return self.str()
        if type_id == 1:  # bool
            return self.bool()
        if type_id == 2:  # int
            return self.int()
        if type_id == 6:  # double
            return self.double()
        if type_id == 0:  # invalid
            return None
        raise ValueError(f"QVariant type {type_id} not handled; stringify the expression")


class QmlDebug:
    def __init__(self, port, host="127.0.0.1", timeout=5):
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.buf = b""
        self.ids = itertools.count(1)
        self._handshake()

    # ---- framing
    def _send(self, payload):
        self.sock.sendall(struct.pack("<i", len(payload) + 4) + payload)

    def _recv(self):
        while True:
            if len(self.buf) >= 4:
                size = struct.unpack("<i", self.buf[:4])[0]
                if len(self.buf) >= size:
                    packet, self.buf = self.buf[4:size], self.buf[size:]
                    return packet
            chunk = self.sock.recv(1 << 20)
            if not chunk:
                raise ConnectionError("debug server closed the connection")
            self.buf += chunk

    def _handshake(self):
        w = Writer().str(SERVER_ID).int(0).int(1).strlist([SERVICE]).int(DATASTREAM_VERSION).bool(True)
        self._send(bytes(w.b))
        r = Reader(self._recv())
        if r.str() != CLIENT_ID or r.int() != 0 or r.int() != 1:
            raise ConnectionError("unexpected handshake answer")
        self.plugins = r.strlist()
        [r.double() for _ in range(r.uint())]  # plugin versions (QList<float>, written as doubles)
        self.stream_version = r.int()
        if SERVICE not in self.plugins:
            raise ConnectionError(f"no {SERVICE} service; server has {self.plugins}")

    # ---- service messages
    def request(self, kind, build=lambda w: w):
        qid = next(self.ids)
        inner = build(Writer().bytes(kind.encode()).int(qid))
        self._send(bytes(Writer().str(SERVICE).bytes(bytes(inner.b)).b))
        want = (kind + "_R").encode()
        while True:
            outer = Reader(self._recv())
            while not outer.at_end():
                name, msg = outer.str(), outer.bytes()
                if name != SERVICE:
                    continue
                r = Reader(msg)
                if r.bytes() == want and r.int() == qid:
                    return r

    def engines(self):
        r = self.request("LIST_ENGINES")
        return [(r.str(), r.int()) for _ in range(r.int())]

    @staticmethod
    def _object(r):
        return {
            "url": r.bytes().decode(), "line": r.int(), "col": r.int(), "id": r.str(),
            "name": r.str(), "type": r.str(), "debugId": r.int(), "contextId": r.int(), "parentId": r.int(),
        }

    def _context(self, r, out):
        r.str()
        r.int()
        for _ in range(r.int()):
            self._context(r, out)
        out.extend(self._object(r) for _ in range(r.int()))

    def find_root(self, type_name="ShellRoot"):
        """Debug id of the root object of that type. LIST_OBJECTS cannot be parsed reliably (Qt counts
        invalid child contexts but does not write them), so find the object's type string in the raw
        answer: the object's debug id follows it."""
        enc = type_name.encode("utf-16-be")
        needle = struct.pack(">I", len(enc)) + enc
        for _, eid in self.engines():
            r = self.request("LIST_OBJECTS", lambda w, e=eid: w.int(e))
            i = r.d.find(needle, r.p)
            if i >= 0:
                return struct.unpack(">i", r.d[i + len(needle):i + len(needle) + 4])[0]
        return None

    def root_objects(self, engine_id):
        r = self.request("LIST_OBJECTS", lambda w: w.int(engine_id))
        out = []
        self._context(r, out)
        return out

    def _dump(self, r):
        obj = self._object(r)
        count, recur = r.int(), r.bool()
        obj["children"] = [self._dump(r) if recur else self._object(r) for _ in range(count)]
        r.int()  # property count (0: we never ask for properties)
        return obj

    def tree(self, debug_id):
        r = self.request("FETCH_OBJECT", lambda w: w.int(debug_id).bool(True).bool(False))
        return self._dump(r)

    def eval(self, debug_id, expr, engine_id=-1):
        r = self.request("EVAL_EXPRESSION", lambda w: w.int(debug_id).str(expr).int(engine_id))
        return r.variant()


if __name__ == "__main__":
    import sys
    dbg = QmlDebug(int(sys.argv[1]) if len(sys.argv) > 1 else 47777)
    print("stream", dbg.stream_version, "plugins", dbg.plugins)
    engines = dbg.engines()
    print("engines", engines)
    roots = dbg.root_objects(engines[0][1])
    print(len(roots), "root objects")
    for o in roots[:10]:
        print(o["type"], o["id"], o["url"].rsplit("/", 1)[-1], o["line"], o["debugId"])
