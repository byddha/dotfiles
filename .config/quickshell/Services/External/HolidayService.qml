pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Utils"
import "../../Config"
import ".."

/**
 * HolidayService - Public holiday, observance, and name day data
 *
 * - Public holidays: Fetched from Nager.Date API (cached 2 weeks)
 * - Observances: Hardcoded Romanian traditional days
 * - Name days: Hardcoded major Romanian name days
 */
Singleton {
    id: root

    function init() {
        Logger.info("Service initialized");
    }

    // Cache directory and file
    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string cacheFile: cacheDir + "/holidays.json"

    // Cache expiry (2 weeks in seconds)
    readonly property int cacheExpiry: 14 * 24 * 60 * 60

    // State
    property bool isFetching: false

    // Data alias for external access
    readonly property alias data: adapter

    // Helper property for UI
    readonly property bool holidaysReady: adapter.holidays !== null && Object.keys(adapter.holidays).length > 0

    // ========================================================================
    // HARDCODED DATA
    // ========================================================================

    // Romanian observances (month-day format)
    readonly property var observances: ({
            "2-14": "Ziua Îndrăgostiților",
            "2-24": "Dragobete",
            "3-1": "Mărțișor",
            "3-8": "Ziua Femeii",
            "3-9": "Sfinții 40 de Mucenici / Ziua Bărbatului",
            "6-24": "Sânziene / Drăgaica",
            "10-31": "Halloween"
        })

    // Major Romanian name days (month-day format)
    readonly property var nameDays: ({
            "1-1": "Sf. Vasile (Vasile, Vasilica)",
            "1-7": "Sf. Ioan Botezătorul (Ion, Ioana, Ioan, Ionuț, Ionela)",
            "1-17": "Sf. Antonie (Anton, Antonia)",
            "4-23": "Sf. Gheorghe (George, Georgeta, Georgiana)",
            "5-21": "Sf. Constantin și Elena (Constantin, Elena, Costin)",
            "6-29": "Sf. Petru și Pavel (Petru, Pavel, Petra, Paula)",
            "7-20": "Sf. Ilie (Ilie, Ilinca)",
            "8-15": "Sf. Maria (Maria, Marian, Mariana, Mioara)",
            "10-26": "Sf. Dimitrie (Dumitru, Mitică)",
            "11-8": "Sf. Mihail și Gavriil (Mihai, Mihail, Gabriel, Gabriela)",
            "11-25": "Sf. Ecaterina (Ecaterina, Cătălina)",
            "11-30": "Sf. Andrei (Andrei, Andreea)",
            "12-6": "Sf. Nicolae (Nicolae, Nicoleta, Nicu)",
            "12-27": "Sf. Ștefan (Ștefan, Ștefania)"
        })

    // ========================================================================
    // PUBLIC API
    // ========================================================================

    /**
     * Get event for a specific date
     * @param year - Full year (e.g., 2025)
     * @param month - Month index (0-11)
     * @param day - Day of month (1-31)
     * @returns {type, name} or null
     *          type: "user" | "public" | "observance" | "nameday"
     */
    function getHoliday(year, month, day) {
        // Check user events first (highest priority)
        const userEvent = UserEventsService.getEvent(year, month, day);
        if (userEvent) {
            return {
                type: "user",
                name: userEvent
            };
        }

        // Check public holidays
        const dateStr = year + "-" + String(month + 1).padStart(2, '0') + "-" + String(day).padStart(2, '0');
        const yearData = adapter.holidays[year.toString()];
        if (yearData && yearData[dateStr]) {
            return {
                type: "public",
                name: yearData[dateStr]
            };
        }

        // Check computed observances (Mother's/Father's Day)
        const computed = getComputedObservance(year, month, day);
        if (computed) {
            return {
                type: "observance",
                name: computed
            };
        }

        // Check fixed observances
        const key = (month + 1) + "-" + day;
        if (observances[key]) {
            return {
                type: "observance",
                name: observances[key]
            };
        }

        // Check name days (lowest priority)
        if (nameDays[key]) {
            return {
                type: "nameday",
                name: nameDays[key]
            };
        }

        return null;
    }

    /**
     * Get computed observances (variable dates)
     */
    function getComputedObservance(year, month, day) {
        // Mother's Day: 1st Sunday of May (in Romania)
        if (month === 4) { // May
            const firstSunday = getFirstSundayOfMonth(year, 4);
            if (day === firstSunday) {
                return "Ziua Mamei";
            }
            // Father's Day: 2nd Sunday of May (in Romania)
            const secondSunday = firstSunday + 7;
            if (day === secondSunday) {
                return "Ziua Tatălui";
            }
        }
        return null;
    }

    /**
     * Get the first Sunday of a month
     */
    function getFirstSundayOfMonth(year, month) {
        const firstDay = new Date(year, month, 1);
        const dayOfWeek = firstDay.getDay(); // 0 = Sunday
        return dayOfWeek === 0 ? 1 : (8 - dayOfWeek);
    }

    /**
     * Update holidays - checks cache and fetches if needed
     */
    function updateHolidays() {
        if (!(Config.options.calendar?.holidays?.enabled ?? true))
            return;

        const currentYear = new Date().getFullYear();
        const countryCode = Config.options.calendar?.holidays?.countryCode ?? "RO";
        const now = Math.floor(Date.now() / 1000);

        // Refetch if country changed or cache expired
        if (adapter.countryCode !== countryCode || (adapter.lastFetch > 0 && now >= adapter.lastFetch + cacheExpiry)) {
            Logger.info("Clearing holiday cache (country changed or expired)");
            adapter.holidays = {};
            adapter.countryCode = countryCode;
            adapter.lastFetch = 0;
        }

        fetchYear(currentYear, countryCode);
        fetchYear(currentYear + 1, countryCode);
    }

    // Private: fetch holidays for a single year
    function fetchYear(year, countryCode) {
        if (adapter.holidays[year.toString()])
            return; // Already cached

        isFetching = true;
        Logger.info("Fetching holidays for", year, countryCode);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isFetching = false;
                if (xhr.status === 200) {
                    try {
                        const holidays = JSON.parse(xhr.responseText);
                        // Convert array to {date: localName} map
                        let yearMap = {};
                        holidays.forEach(h => yearMap[h.date] = h.localName);
                        adapter.holidays[year.toString()] = yearMap;
                        adapter.lastFetch = Math.floor(Date.now() / 1000);
                        adapter.holidaysChanged();
                        saveTimer.start();
                        Logger.info("Loaded", Object.keys(yearMap).length, "holidays for", year);
                    } catch (e) {
                        Logger.error("Failed to parse holiday response:", e);
                    }
                } else {
                    Logger.error("Holiday fetch error:", xhr.status);
                }
            }
        };
        xhr.open("GET", "https://date.nager.at/api/v3/PublicHolidays/" + year + "/" + countryCode);
        xhr.send();
    }

    // File view for caching
    FileView {
        id: cacheFileView
        path: root.cacheFile
        printErrors: false

        onLoaded: {
            Logger.info("Loaded holiday cache");
            root.updateHolidays();
        }

        onLoadFailed: function (error) {
            Logger.warn("Failed to load holiday cache:", error);
            root.updateHolidays();
        }

        JsonAdapter {
            id: adapter
            property string countryCode: ""
            property int lastFetch: 0
            property var holidays: ({})
        }
    }

    // Debounced save timer
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: cacheFileView.writeAdapter()
    }
}
