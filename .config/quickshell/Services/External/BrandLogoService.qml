pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Config"
import "../../Utils"

Singleton {
    id: root

    readonly property string _publishableKey: Config.options.brandLogos?.apiKey ?? ""
    readonly property string _secretKey: Config.options.brandLogos?.secretKey ?? ""
    readonly property string _cacheDirUrl: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string _cacheDir: _cacheDirUrl.toString().replace("file://", "")
    readonly property string _cacheFile: _cacheDirUrl + "/brand_cache.json"
    readonly property string _logoDir: _cacheDir + "/logos"

    // Caches (persisted to disk)
    property var _ouiCache: ({})       // OUI → vendor name
    property var _domainCache: ({})    // vendor name → domain
    property var _deviceBrands: ({})   // device id → vendor name
    property var _logoDownloaded: ({}) // domain → true (persisted)
    property var _pendingOui: ({})

    signal brandResolved

    // ==================
    // Public API
    // ==================

    function getLogoPath(brand) {
        if (!brand)
            return "";
        const domain = _domainCache[brand];
        if (!domain) {
            if (_domainCache[brand] === undefined && _secretKey) {
                _domainCache[brand] = null;
                _searchDomain(brand);
            }
            return "";
        }

        const localPath = _logoDir + "/" + domain + ".png";

        if (_logoDownloaded[domain])
            return localPath;

        // Trigger download — path returned after download completes via brandResolved → rebuild
        if (_logoDownloaded[domain] === undefined) {
            _logoDownloaded[domain] = false;
            _downloadLogo(domain);
        }

        return "";
    }

    function getCachedDeviceBrand(deviceId) {
        return _deviceBrands[deviceId] || "";
    }

    function setCachedDeviceBrand(deviceId, brand) {
        if (brand && _deviceBrands[deviceId] !== brand) {
            _deviceBrands[deviceId] = brand;
            _saveCache();
        }
    }

    function lookupBrandFromMac(macSource, callback) {
        const mac = _extractMac(macSource);
        if (!mac) {
            callback("");
            return;
        }

        const oui = _macToOui(mac);

        if (_ouiCache[oui] !== undefined) {
            callback(_ouiCache[oui]);
            return;
        }

        if (_pendingOui[oui]) {
            _pendingOui[oui].push(callback);
            return;
        }

        _pendingOui[oui] = [callback];
        const proc = ouiLookupComponent.createObject(root, {
            oui: oui
        });
        proc.running = true;
    }

    function _extractMac(str) {
        if (!str)
            return "";
        const match = str.match(/([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}/);
        return match ? match[0] : "";
    }

    // ==================
    // Internal
    // ==================

    function _macToOui(mac) {
        return mac.split(/[:\-]/).slice(0, 3).join("-").toUpperCase();
    }

    function _saveCache() {
        saveTimer.restart();
    }

    function _downloadLogo(domain) {
        if (!_publishableKey)
            return;
        const url = `https://img.logo.dev/${domain}?token=${_publishableKey}&size=64&format=png`;
        const localPath = _logoDir + "/" + domain + ".png";
        const proc = logoDownloadComponent.createObject(root, {
            domain: domain
        });
        proc.command = ["bash", "-c", `mkdir -p '${_logoDir}' && curl -sf -o '${localPath}' '${url}'`];
        proc.running = true;
    }

    function _searchDomain(brand) {
        if (!_secretKey)
            return;
        const cleaned = brand.split(/\s/)[0].replace(/,$/, "");
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const results = JSON.parse(xhr.responseText);
                    if (results.length > 0) {
                        _domainCache[brand] = results[0].domain;
                        _saveCache();
                        _downloadLogo(results[0].domain);
                        Logger.debug(`Brand search: "${brand}" → ${results[0].domain}`);
                    } else {
                        _domainCache[brand] = "";
                    }
                } catch (e) {
                    _domainCache[brand] = "";
                }
            } else {
                _domainCache[brand] = "";
            }
        };
        xhr.open("GET", `https://api.logo.dev/search?q=${encodeURIComponent(cleaned)}`);
        xhr.setRequestHeader("Authorization", `Bearer ${_secretKey}`);
        xhr.send();
    }

    // ==================
    // Cache persistence
    // ==================

    FileView {
        id: cacheFileView
        path: root._cacheFile
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(cacheFileView.text());
                root._ouiCache = data.oui || {};
                root._domainCache = data.domains || {};
                root._deviceBrands = data.devices || {};
                root._logoDownloaded = data.logos || {};
                Logger.info(`Brand cache loaded: ${Object.keys(root._ouiCache).length} OUI, ${Object.keys(root._domainCache).length} domains, ${Object.keys(root._deviceBrands).length} devices`);
            } catch (e) {
                Logger.warn("Failed to parse brand cache:", e);
            }
        }

        onLoadFailed: function (error) {
            Logger.info("No brand cache found, starting fresh");
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: {
            cacheFileView.setText(JSON.stringify({
                oui: root._ouiCache,
                domains: root._domainCache,
                devices: root._deviceBrands,
                logos: root._logoDownloaded
            }, null, 2));
        }
    }

    // ==================
    // OUI lookup
    // ==================

    Component {
        id: ouiLookupComponent

        Process {
            id: ouiProc
            property string oui: ""
            command: ["grep", "-m1", oui, "/usr/share/hwdata/oui.txt"]

            stdout: StdioCollector {
                onStreamFinished: {
                    const parts = text.split(/\t+/);
                    const vendor = parts.length >= 2 ? parts[parts.length - 1].trim() : "";

                    root._ouiCache[ouiProc.oui] = vendor;
                    root._saveCache();

                    const callbacks = root._pendingOui[ouiProc.oui] || [];
                    delete root._pendingOui[ouiProc.oui];
                    for (const cb of callbacks)
                        cb(vendor);

                    Logger.debug(`OUI ${ouiProc.oui} → "${vendor}"`);
                    ouiProc.destroy();
                }
            }

            onExited: (code, status) => {
                if (code !== 0) {
                    root._ouiCache[oui] = "";
                    root._saveCache();
                    const callbacks = root._pendingOui[oui] || [];
                    delete root._pendingOui[oui];
                    for (const cb of callbacks)
                        cb("");
                    destroy();
                }
            }
        }
    }

    // ==================
    // Logo download
    // ==================

    Component {
        id: logoDownloadComponent

        Process {
            id: dlProc
            property string domain: ""

            onExited: (code, status) => {
                if (code === 0) {
                    root._logoDownloaded[domain] = true;
                    root._saveCache();
                    root.brandResolved();
                    Logger.info(`Logo downloaded: ${domain}`);
                } else {
                    Logger.warn(`Logo download failed: ${domain}`);
                }
                destroy();
            }
        }
    }

    Component.onCompleted: {
        Logger.info("BrandLogoService initialized");
        cacheFileView.reload();
    }
}
