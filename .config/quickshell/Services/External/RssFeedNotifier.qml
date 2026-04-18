pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Config"
import "../../Utils"

// RSS/Atom parser (_parseRSS, _extractTag, _extractAttr, _cleanText) adapted from
// noctalia-plugins (MIT) — https://github.com/noctalia-dev/noctalia-plugins
// rss-feed/BarWidget.qml. Differences from upstream: parallel per-feed fetches,
// pluggable format registry, no pluginApi-polling Timer.
Singleton {
    id: root

    readonly property string _cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string _cacheDirPath: _cacheDir.toString().replace("file://", "")
    readonly property string _stateFile: _cacheDir + "/rss_feed_notifier.json"
    readonly property int _seenCap: 500
    readonly property int _maxItemsPerFeed: 50

    property var _seen: ({})
    property bool _stateLoaded: false
    property var _parsers: ({})

    function init() {
        _state.reload();
        const feeds = Config.options.rssFeedNotifier?.feeds ?? [];
        if (feeds.length === 0) {
            Logger.info(`no feeds configured — add entries to ${Config.configFile} under "rssFeedNotifier.feeds"`);
        } else {
            Logger.info(`monitoring ${feeds.length} feed(s)`);
        }
    }

    function registerParser(name, fn) {
        _parsers[name] = fn;
    }

    Component.onCompleted: {
        registerParser("rss", _parseRSS);
    }

    Instantiator {
        model: Config.options.rssFeedNotifier?.feeds ?? []
        delegate: QtObject {
            id: feedDelegate
            required property var modelData

            property var _timer: Timer {
                interval: Math.max(10, (feedDelegate.modelData?.interval ?? 900)) * 1000
                running: root._stateLoaded && (Config.options.rssFeedNotifier?.enabled ?? true)
                repeat: true
                triggeredOnStart: true
                onTriggered: root._fetch(feedDelegate.modelData)
            }
        }
    }

    Component {
        id: _fetcherComponent
        Process {
            id: proc
            property var feed
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text)
                        root._process(proc.feed, text);
                }
            }
            stderr: StdioCollector {}
            onExited: exitCode => {
                if (exitCode !== 0)
                    Logger.warn(`fetch failed for ${proc.feed?.name} (${proc.feed?.url}): exit ${exitCode}`);
                proc.destroy();
            }
        }
    }

    function _fetch(feed) {
        if (!feed?.url)
            return;
        const p = _fetcherComponent.createObject(root, {
            "feed": feed
        });
        p.command = ["curl", "-s", "-L", "-H", "User-Agent: Mozilla/5.0", "--max-time", "10", feed.url];
        p.running = true;
    }

    function _parse(feed, text) {
        const fmt = feed.format || "rss";
        const parser = _parsers[fmt];
        if (!parser) {
            Logger.warn(`no parser for format '${fmt}' (feed ${feed.name})`);
            return [];
        }
        try {
            return parser(text, feed);
        } catch (e) {
            Logger.warn(`parse error in ${feed.name}: ${e}`);
            return [];
        }
    }

    function _process(feed, text) {
        const items = _parse(feed, text);
        // First time we've ever fetched this feed URL: seed `seen` silently so adding a new
        // feed (or clearing state) doesn't dump a backlog of notifications at once.
        const firstFetch = root._seen[feed.url] === undefined;
        const seenForUrl = (root._seen[feed.url] || []).slice();
        const seenSet = new Set(seenForUrl);
        let added = 0, notified = 0;
        for (const it of items) {
            const guid = it.guid || it.link;
            if (!guid || seenSet.has(guid))
                continue;
            seenForUrl.push(guid);
            seenSet.add(guid);
            added++;
            if (!firstFetch && _whitelistMatches(feed.whitelist, it.title)) {
                _fireNotification(feed, it);
                notified++;
            }
        }
        if (seenForUrl.length > root._seenCap) {
            seenForUrl.splice(0, seenForUrl.length - root._seenCap);
        }
        root._seen[feed.url] = seenForUrl;
        if (added > 0)
            _saveSeen();
        if (firstFetch) {
            Logger.info(`${feed.name}: first fetch, seeded ${added} item(s) silently`);
        } else {
            Logger.info(`${feed.name}: ${items.length} parsed, ${added} new, ${notified} notified`);
        }
    }

    function _whitelistMatches(whitelist, title) {
        if (!whitelist || whitelist.length === 0)
            return true;
        const t = (title || "").toLowerCase();
        return whitelist.some(w => t.includes(String(w).toLowerCase()));
    }

    function _fireNotification(feed, item) {
        const summary = `RSS: ${feed.name || "feed"}`;
        const body = item.title || "(untitled)";
        const link = item.link || "";
        const args = ["notify-send", "-a", summary, "-u", "low"];
        if (link)
            args.push("-A", `open:${encodeURIComponent(link)}=Open`);
        args.push(summary, body);
        Quickshell.execDetached(args);
    }

    function _parseRSS(xml, feed) {
        const items = [];
        const itemRegex = /<(?:item|entry)[^>]*>([\s\S]*?)<\/(?:item|entry)>/gi;
        let match;
        let count = 0;
        while ((match = itemRegex.exec(xml)) !== null && count < root._maxItemsPerFeed) {
            const itemXml = match[1];
            const title = _extractTag(itemXml, "title") || "Untitled";
            const link = _extractTag(itemXml, "link") || _extractAttr(itemXml, "link", "href") || "";
            const description = _extractTag(itemXml, "description") || _extractTag(itemXml, "summary") || _extractTag(itemXml, "content") || "";
            const pubDate = _extractTag(itemXml, "pubDate") || _extractTag(itemXml, "published") || _extractTag(itemXml, "updated") || new Date().toISOString();
            const guid = _extractTag(itemXml, "guid") || _extractTag(itemXml, "id") || link;
            items.push({
                "feedName": feed.name,
                "feedUrl": feed.url,
                "title": _cleanText(title),
                "link": link,
                "description": _cleanText(description).substring(0, 200),
                "pubDate": pubDate,
                "guid": guid
            });
            count++;
        }
        return items;
    }

    function _extractTag(xml, tag) {
        const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\/${tag}>`, "i");
        const m = xml.match(re);
        return m ? m[1] : "";
    }

    function _extractAttr(xml, tag, attr) {
        const re = new RegExp(`<${tag}[^>]*${attr}="([^"]*)"`, "i");
        const m = xml.match(re);
        return m ? m[1] : "";
    }

    function _cleanText(text) {
        if (!text)
            return "";
        text = text.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1");
        text = text.replace(/<[^>]+>/g, " ");
        text = text.replace(/&#(\d+);/g, (m, dec) => String.fromCharCode(parseInt(dec, 10)));
        text = text.replace(/&#x([0-9A-Fa-f]+);/g, (m, hex) => String.fromCharCode(parseInt(hex, 16)));
        text = text.replace(/&lt;/g, "<");
        text = text.replace(/&gt;/g, ">");
        text = text.replace(/&amp;/g, "&");
        text = text.replace(/&quot;/g, '"');
        text = text.replace(/&#39;/g, "'");
        text = text.replace(/&apos;/g, "'");
        text = text.replace(/&nbsp;/g, " ");
        text = text.replace(/&mdash;/g, "\u2014");
        text = text.replace(/&ndash;/g, "\u2013");
        text = text.replace(/&ldquo;/g, "\u201C");
        text = text.replace(/&rdquo;/g, "\u201D");
        text = text.replace(/&lsquo;/g, "\u2018");
        text = text.replace(/&rsquo;/g, "\u2019");
        text = text.replace(/&hellip;/g, "\u2026");
        text = text.replace(/\s+/g, " ").trim();
        return text;
    }

    FileView {
        id: _state
        path: root._stateFile
        onLoaded: {
            try {
                root._seen = JSON.parse(_state.text())?.seen ?? {};
            } catch (e) {
                Logger.warn(`state parse failed: ${e}`);
                root._seen = {};
            }
            root._stateLoaded = true;
            Logger.info(`state loaded (${Object.keys(root._seen).length} feed(s) tracked)`);
        }
        onLoadFailed: err => {
            if (err == FileViewError.FileNotFound) {
                Logger.info("no state file, creating cache dir and empty state");
                _ensureCacheDirProc.running = true;
            } else {
                Logger.error(`state load: ${err}`);
                root._stateLoaded = true;
            }
        }
    }

    Process {
        id: _ensureCacheDirProc
        command: ["mkdir", "-p", root._cacheDirPath]
        onExited: (code, status) => {
            if (code === 0) {
                root._seen = {};
                _state.setText(JSON.stringify({
                    "seen": root._seen
                }, null, 2));
            } else {
                Logger.error("failed to create cache dir");
            }
            root._stateLoaded = true;
        }
    }

    Timer {
        id: _saveDebounce
        interval: 500
        onTriggered: _state.setText(JSON.stringify({
            "seen": root._seen
        }, null, 2))
    }

    function _saveSeen() {
        _saveDebounce.restart();
    }
}
