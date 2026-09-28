pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Utils"
import "../../Config"
import ".."

/**
 * WeatherService - Weather data fetching and caching
 *
 * Uses Open-Meteo API (free, no API key required) to fetch weather data.
 * Caches data to disk and refreshes every 30 minutes.
 */
Singleton {
    id: root

    // Called by shell.qml to instantiate the singleton eagerly.
    function init() {
    }

    // Cache directory and file
    readonly property string cacheDir: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/bidshell"
    readonly property string cacheFile: cacheDir + "/weather.json"

    // Update interval (30 minutes in seconds)
    readonly property int weatherUpdateFrequency: 30 * 60

    // State
    property bool isFetchingWeather: false

    // Data alias for external access: WeatherService.data.weather, etc.
    readonly property alias data: adapter

    // Helper property for UI
    readonly property string location: "Bucharest"
    readonly property bool weatherReady: adapter.weather !== null

    // File view for caching
    FileView {
        id: cacheFileView
        path: root.cacheFile
        printErrors: false

        onLoaded: {
            updateWeather();
        }

        onLoadFailed: function (error) {
            Logger.warn("Failed to load cache: " + error);
            updateWeather();
        }

        onAdapterUpdated: saveTimer.start()

        JsonAdapter {
            id: adapter

            // Core data properties
            property string latitude: ""
            property string longitude: ""
            property string name: ""
            property int weatherLastFetch: 0
            property var weather: null
        }
    }

    // Debounce timer for saving
    Timer {
        id: saveTimer
        running: false
        interval: 1000
        onTriggered: cacheFileView.writeAdapter()
    }

    // Periodic update timer (every 20s check if refresh needed)
    Timer {
        id: updateTimer
        interval: 20 * 1000
        running: true
        repeat: true
        onTriggered: updateWeather()
    }

    // ========================================================================
    // PUBLIC API
    // ========================================================================

    /**
     * Force weather refresh
     */
    function updateWeather() {
        if (isFetchingWeather) {
            Logger.warn("Weather is still fetching");
            return;
        }

        const currentLocation = root.location;
        const now = Math.floor(Date.now() / 1000);

        // Refresh if: no data, location changed, or cache expired
        if (adapter.weatherLastFetch === 0 || adapter.weather === null || adapter.latitude === "" || adapter.longitude === "" || adapter.name !== currentLocation || now >= adapter.weatherLastFetch + weatherUpdateFrequency) {
            getFreshWeather();
        }
    }

    // WMO weather code -> [icon, description]
    readonly property var wmoCodes: {
        const table = {};
        const add = (from, to, icon, description) => {
            for (let code = from; code <= to; code++)
                table[code] = [icon, description];
        };
        add(0, 0, Icons.weatherSunny, "Clear sky");
        add(1, 1, Icons.weatherPartlyCloudy, "Mainly clear");
        add(2, 2, Icons.weatherPartlyCloudy, "Partly cloudy");
        add(3, 3, Icons.weatherCloudy, "Overcast");
        add(45, 45, Icons.weatherFog, "Fog");
        add(48, 48, Icons.weatherFog, "Fog");
        add(51, 55, Icons.weatherRainy, "Drizzle");
        add(56, 57, Icons.weatherRainy, "Freezing drizzle");
        add(61, 65, Icons.weatherRainy, "Rain");
        add(66, 67, Icons.weatherRainy, "Freezing rain");
        add(71, 77, Icons.weatherSnowy, "Snow");
        add(80, 82, Icons.weatherRainy, "Rain showers");
        add(85, 86, Icons.weatherSnowy, "Snow showers");
        add(95, 99, Icons.weatherThunderstorm, "Thunderstorm");
        return table;
    }

    // Returns a Nerd Font icon - use with Theme.fontFamilyIcons
    function weatherSymbolFromCode(code) {
        return wmoCodes[code]?.[0] ?? Icons.weatherCloudy;
    }

    // Lucide glyph (Theme.fontIcons) for a WMO code
    function glyphFromCode(code, isDay) {
        if (code === 0)
            return isDay ? Lucide.sun : Lucide.moon;
        if (code <= 2)
            return isDay ? Lucide.cloudSun : Lucide.cloudMoon;
        if (code === 3)
            return Lucide.cloud;
        if (code <= 48)
            return Lucide.cloudFog;
        if (code <= 57)
            return Lucide.cloudDrizzle;
        if (code <= 67 || (code >= 80 && code <= 82))
            return Lucide.cloudRain;
        if (code <= 86)
            return Lucide.cloudSnow;
        return Lucide.cloudLightning;
    }

    function weatherDescriptionFromCode(code) {
        return wmoCodes[code]?.[1] ?? "Unknown";
    }

    // ========================================================================
    // PRIVATE METHODS
    // ========================================================================

    function getFreshWeather() {
        isFetchingWeather = true;

        const currentLocation = root.location;
        const locationChanged = adapter.name !== currentLocation;

        // Need geocoding?
        if (adapter.latitude === "" || adapter.longitude === "" || locationChanged) {
            geocodeLocation(currentLocation, function (lat, lon, name, country) {
                adapter.name = currentLocation;
                adapter.latitude = lat.toString();
                adapter.longitude = lon.toString();

                fetchWeather(lat, lon);
            }, errorCallback);
        } else {
            fetchWeather(adapter.latitude, adapter.longitude);
        }
    }

    function geocodeLocation(locationName, callback, errorCallback) {
        const url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(locationName) + "&count=1&language=en&format=json";

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText);
                        if (data.results && data.results.length > 0) {
                            const result = data.results[0];
                            callback(result.latitude, result.longitude, result.name, result.country);
                        } else {
                            errorCallback("WeatherService", "Location not found: " + locationName);
                        }
                    } catch (e) {
                        errorCallback("WeatherService", "Failed to parse geocoding response: " + e);
                    }
                } else {
                    errorCallback("WeatherService", "Geocoding error: " + xhr.status);
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fetchWeather(latitude, longitude) {
        const url = "https://api.open-meteo.com/v1/forecast?" + "latitude=" + latitude + "&longitude=" + longitude + "&current=temperature_2m,apparent_temperature,is_day,relative_humidity_2m,precipitation,weather_code,wind_speed_10m" + "&hourly=temperature_2m,weather_code,precipitation_probability" + "&daily=temperature_2m_max,temperature_2m_min,weather_code" + "&timezone=auto";

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const weatherData = JSON.parse(xhr.responseText);

                        // Save data
                        adapter.weather = weatherData;
                        adapter.weatherLastFetch = Math.floor(Date.now() / 1000);

                        adapter.latitude = weatherData.latitude.toString();
                        adapter.longitude = weatherData.longitude.toString();

                        isFetchingWeather = false;
                    } catch (e) {
                        errorCallback("WeatherService", "Failed to parse weather response: " + e);
                    }
                } else {
                    errorCallback("WeatherService", "Weather fetch error: " + xhr.status);
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function errorCallback(module, message) {
        Logger.error(module, message);
        isFetchingWeather = false;
    }
}
