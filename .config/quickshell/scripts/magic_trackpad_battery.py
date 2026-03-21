#!/usr/bin/env python3
"""Read Apple Magic Trackpad 2 battery via HID feature reports.

Bypasses UPower's broken 4% reading by querying the device firmware directly.
Requires read/write access to /dev/hidrawN (root or a udev rule).

Output: {"percentage": 0-100, "charging": true/false}
"""
import fcntl
import os
import json
import sys


REPORT_ID = 0x90
REPORT_SIZE = 3
HIDIOCGINPUT = 0xC003480A


def find_devices():
    base = "/sys/class/hidraw"
    devices = []
    try:
        for node in os.listdir(base):
            uevent = f"{base}/{node}/device/uevent"
            if os.path.exists(uevent):
                with open(uevent, "r") as f:
                    if "DRIVER=magicmouse" in f.read():
                        devices.append(f"/dev/{node}")
    except Exception:
        pass
    return devices


def get_data():
    for device in find_devices():
        try:
            fd = os.open(device, os.O_RDWR)
            buf = bytearray([REPORT_ID, 0, 0])
            fcntl.ioctl(fd, HIDIOCGINPUT, buf)
            os.close(fd)

            # buf[1] -> (Bit 0x02 indicates if it's charging)
            # buf[2] -> Capacity (0-100)
            return int(buf[2]), bool(buf[1] & 0x02)
        except Exception:
            continue
    return None


def main():
    result = get_data()
    if not result:
        sys.exit(1)

    percent, charging = result
    print(json.dumps({"percentage": percent, "charging": charging}))


if __name__ == "__main__":
    main()
