import QtQuick
import Quickshell
import Quickshell.Io
import "../../Utils"

/**
 * SteamProvider - Detects and provides Steam game library data
 *
 * Parses Steam's VDF files to discover installed games:
 * - libraryfolders.vdf for library locations
 * - appmanifest_*.acf for game metadata
 * - librarycache for cover art
 */
Item {
    id: root

    property var games: []
    property bool isLoading: false
    property string lastError: ""

    property string activeSteamPath: ""
    property var libraryPaths: []
    property var pendingManifests: []
    property var loadedGames: []
    property int currentPathIndex: 0

    // ========================================================================
    // PUBLIC API
    // ========================================================================

    function getSteamPaths() {
        const home = Quickshell.env("HOME");
        return [`${home}/.local/share/Steam`, `${home}/.steam/steam`];
    }

    function refresh() {
        if (root.isLoading) {
            Logger.debug("SteamProvider: Already loading, skipping refresh");
            return;
        }
        Logger.info("SteamProvider: Refreshing game library");
        root.isLoading = true;
        root.loadedGames = [];
        root.libraryPaths = [];
        root.currentPathIndex = 0;
        tryNextSteamPath();
    }

    // ========================================================================
    // STEAM INSTALLATION DETECTION
    // ========================================================================

    function tryNextSteamPath() {
        const paths = getSteamPaths();
        if (root.currentPathIndex >= paths.length) {
            root.lastError = "Steam installation not found";
            root.isLoading = false;
            Logger.error("SteamProvider: Steam not found");
            return;
        }

        const path = paths[root.currentPathIndex];
        const libFile = `${path}/steamapps/libraryfolders.vdf`;
        steamPathChecker.steamPath = path;
        steamPathChecker.command = ["test", "-f", libFile];
        steamPathChecker.running = true;
    }

    Process {
        id: steamPathChecker
        running: false
        property string steamPath: ""

        onExited: (code, status) => {
            if (code === 0) {
                root.activeSteamPath = steamPath;
                Logger.info(`SteamProvider: Found Steam at ${root.activeSteamPath}`);
                loadLibraryFolders();
            } else {
                root.currentPathIndex++;
                tryNextSteamPath();
            }
        }
    }

    // ========================================================================
    // LIBRARY FOLDERS PARSING
    // ========================================================================

    function loadLibraryFolders() {
        libraryFoldersFile.path = `${root.activeSteamPath}/steamapps/libraryfolders.vdf`;
        libraryFoldersFile.reload();
    }

    FileView {
        id: libraryFoldersFile
        path: ""

        onLoaded: {
            parseLibraryFolders(libraryFoldersFile.text());
        }

        onLoadFailed: error => {
            Logger.error(`SteamProvider: Failed to load libraryfolders.vdf: ${error}`);
            root.lastError = "Failed to load Steam library";
            root.isLoading = false;
        }
    }

    function parseLibraryFolders(vdfText) {
        // Simple VDF parser for libraryfolders.vdf
        // Extract "path" values to find all library locations
        const paths = [];
        const lines = vdfText.split('\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            // Match: "path"		"/path/to/library"
            const pathMatch = line.match(/"path"\s+"([^"]+)"/);
            if (pathMatch) {
                paths.push(pathMatch[1]);
            }
        }

        Logger.info(`SteamProvider: Found ${paths.length} library paths`);
        root.libraryPaths = paths;

        // Now find all appmanifest files
        findAppManifests();
    }

    // ========================================================================
    // APP MANIFEST DISCOVERY AND PARSING
    // ========================================================================

    // Filter out non-game entries (runtimes, tools, redistributables)
    function isNonGame(name) {
        const filters = [/^Proton\s/, /^Steam\s+Linux\s+Runtime/, /^Steamworks\s+Common/, /Redistributable/i, /^Proton\s+EasyAntiCheat/, /^Proton\s+BattlEye/, /^Steam\s+Controller/,];

        for (let filter of filters) {
            if (filter.test(name))
                return true;
        }
        return false;
    }

    // Generate search abbreviations from game name
    // e.g., "The Last of Us: Part II" -> ["tloupii", "tloup2", "loup2", "tlou", ...]
    function generateAbbreviations(name) {
        const romanToArabic = {
            'i': '1', 'ii': '2', 'iii': '3', 'iv': '4', 'v': '5',
            'vi': '6', 'vii': '7', 'viii': '8', 'ix': '9', 'x': '10'
        };

        // Clean and split into words
        const cleaned = name.toLowerCase()
            .replace(/[:\-–—]/g, ' ')  // Replace punctuation with space
            .replace(/['']/g, '')       // Remove apostrophes
            .replace(/[^a-z0-9\s]/g, '') // Remove other special chars
            .trim();
        const words = cleaned.split(/\s+/).filter(w => w.length > 0);

        if (words.length === 0) return [];

        const abbreviations = new Set();

        // Build acronym from first letters
        const buildAcronym = (wordList) => {
            return wordList.map(w => {
                // Check if word is a roman numeral
                if (romanToArabic[w]) return romanToArabic[w];
                // Check if word is a number
                if (/^\d+$/.test(w)) return w;
                // Otherwise take first letter
                return w[0];
            }).join('');
        };

        // Full acronym (all words)
        const fullAcronym = buildAcronym(words);
        abbreviations.add(fullAcronym);

        // Version with roman numerals kept as letters
        const acronymRomanAsLetters = words.map(w => {
            if (/^\d+$/.test(w)) return w;
            return w[0];
        }).join('');
        abbreviations.add(acronymRomanAsLetters);

        // Without common articles/prepositions at start
        const skipWords = ['the', 'a', 'an'];
        if (skipWords.includes(words[0]) && words.length > 1) {
            abbreviations.add(buildAcronym(words.slice(1)));
        }

        // Without trailing subtitle indicators (after common separators)
        // e.g., "The Last of Us Part II" -> also generate "tlou"
        const subtitleMarkers = ['part', 'episode', 'chapter', 'volume', 'act', 'remastered', 'edition', 'definitive', 'goty', 'complete'];
        for (let i = 1; i < words.length; i++) {
            if (subtitleMarkers.includes(words[i]) || romanToArabic[words[i]] || /^\d+$/.test(words[i])) {
                const mainPart = words.slice(0, i);
                if (mainPart.length > 0) {
                    abbreviations.add(buildAcronym(mainPart));
                    // Also without leading article
                    if (skipWords.includes(mainPart[0]) && mainPart.length > 1) {
                        abbreviations.add(buildAcronym(mainPart.slice(1)));
                    }
                }
                break;
            }
        }

        // Filter out single-char abbreviations and duplicates
        return Array.from(abbreviations).filter(a => a.length > 1);
    }

    function findAppManifests() {
        if (root.libraryPaths.length === 0) {
            finishLoading();
            return;
        }

        // Use a single command to find and parse all manifests at once
        const searchPaths = root.libraryPaths.map(p => `"${p}/steamapps"`).join(' ');
        manifestParser.command = ["sh", "-c", `
            for f in $(find ${searchPaths} -maxdepth 1 -name 'appmanifest_*.acf' 2>/dev/null); do
                appid=$(grep -m1 '"appid"' "$f" | sed 's/.*"appid"[[:space:]]*"\\([^"]*\\)".*/\\1/')
                name=$(grep -m1 '"name"' "$f" | sed 's/.*"name"[[:space:]]*"\\([^"]*\\)".*/\\1/')
                if [ -n "$appid" ] && [ -n "$name" ]; then
                    echo "$appid|$name"
                fi
            done
        `];
        manifestParser.running = true;
    }

    Process {
        id: manifestParser
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.length > 0);
                Logger.info(`SteamProvider: Parsed ${lines.length} app manifests`);

                for (let line of lines) {
                    const parts = line.split('|');
                    if (parts.length >= 2) {
                        const appid = parts[0];
                        const name = parts[1];

                        // Filter out non-game entries
                        if (isNonGame(name))
                            continue;

                        root.loadedGames.push({
                            id: `steam_${appid}`,
                            appid: appid,
                            name: name,
                            abbreviations: generateAbbreviations(name),
                            platform: "steam",
                            coverArt: "",
                            heroArt: "",
                            launchCommand: ["steam", `steam://rungameid/${appid}`]
                        });
                    }
                }

                findAllCoverArt();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    Logger.warn(`SteamProvider manifest parser stderr: ${text}`);
                }
            }
        }
    }

    // ========================================================================
    // COVER ART DISCOVERY (BATCH)
    // ========================================================================

    function findAllCoverArt() {
        if (root.loadedGames.length === 0) {
            finishLoading();
            return;
        }

        // Find cover art and hero art:
        // Cover: library_600x900.jpg, library_capsule.jpg
        // Hero: library_hero.jpg (for backgrounds)
        const cacheDir = `${root.activeSteamPath}/appcache/librarycache`;
        coverArtFinder.command = ["sh", "-c", `find "${cacheDir}" \\( -name 'library_600x900.jpg' -o -name 'library_600x900_2x.jpg' -o -name 'library_capsule.jpg' -o -name 'library_hero.jpg' \\) 2>/dev/null`];
        coverArtFinder.running = true;
    }

    Process {
        id: coverArtFinder
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const paths = text.trim().split('\n').filter(p => p.length > 0);
                Logger.info(`SteamProvider: Found ${paths.length} art images`);

                // Build maps: appid -> art path
                const coverMap = {};
                const heroMap = {};

                for (let path of paths) {
                    const match = path.match(/librarycache\/(\d+)\//);
                    if (match) {
                        const appid = match[1];
                        const filePath = `file://${path}`;

                        if (path.includes('library_hero')) {
                            heroMap[appid] = filePath;
                        } else {
                            // Cover art: prefer 600x900 over capsule
                            const is600x900 = path.includes('library_600x900');
                            if (!coverMap[appid] || is600x900) {
                                coverMap[appid] = filePath;
                            }
                        }
                    }
                }

                // Update games with local art
                for (let game of root.loadedGames) {
                    game.coverArt = coverMap[game.appid] ?? "";
                    game.heroArt = heroMap[game.appid] ?? "";
                }
                Logger.info(`SteamProvider: ${Object.keys(coverMap).length} covers, ${Object.keys(heroMap).length} heroes`);

                finishLoading();
            }
        }
    }

    // ========================================================================
    // FINISH LOADING
    // ========================================================================

    function finishLoading() {
        // Sort alphabetically (sorting by lastPlayed is done in GameService)
        root.loadedGames.sort((a, b) => a.name.localeCompare(b.name));
        root.games = root.loadedGames;
        root.isLoading = false;
        root.lastError = "";
        Logger.info(`SteamProvider: Loaded ${root.games.length} games`);
    }

    Component.onCompleted: {
        Logger.info("SteamProvider initialized");
    }
}
