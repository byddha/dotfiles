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

    function init() {
        Logger.info("Service initialized");
    }

    // Cache directory and file
    readonly property string cacheDir: (StandardPaths.writableLocation ? StandardPaths.writableLocation(StandardPaths.CacheLocation) : "~/.cache") + "/bidshell"
    readonly property string cacheFile: cacheDir + "/weather.json"

    // Update interval (30 minutes in seconds)
    readonly property int weatherUpdateFrequency: 30 * 60

    // State
    property bool isFetchingWeather: false
    property bool coordinatesReady: false

    // Stable UI properties - only updated when location is fully resolved
    property string stableLatitude: ""
    property string stableLongitude: ""
    property string stableName: ""

    // Data alias for external access: WeatherService.data.weather, etc.
    readonly property alias data: adapter

    // Helper property for UI
    readonly property bool weatherReady: Config.options.calendar?.weather?.enabled && adapter.weather !== null

    // File view for caching
    FileView {
        id: cacheFileView
        path: root.cacheFile
        printErrors: false

        onLoaded: {
            Logger.info("Loaded cached data");
            // Initialize stable properties from cache
            if (adapter.latitude !== "" && adapter.longitude !== "" && adapter.weatherLastFetch > 0) {
                root.stableLatitude = adapter.latitude;
                root.stableLongitude = adapter.longitude;
                root.stableName = adapter.name;
                root.coordinatesReady = true;
                Logger.info("Coordinates ready from cache");
            }
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
        running: Config.options.calendar?.weather?.enabled ?? false
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
        if (!(Config.options.calendar?.weather?.enabled ?? false)) {
            return;
        }

        if (isFetchingWeather) {
            Logger.warn("Weather is still fetching");
            return;
        }

        const currentLocation = Config.options.calendar?.weather?.location ?? "London";
        const now = Math.floor(Date.now() / 1000);

        // Refresh if: no data, location changed, or cache expired
        if (adapter.weatherLastFetch === 0 || adapter.weather === null || adapter.latitude === "" || adapter.longitude === "" || adapter.name !== currentLocation || now >= adapter.weatherLastFetch + weatherUpdateFrequency) {
            getFreshWeather();
        }
    }

    /**
     * Reset weather data and fetch fresh
     */
    function resetWeather() {
        Logger.info("Resetting weather data");

        root.coordinatesReady = false;
        root.stableLatitude = "";
        root.stableLongitude = "";
        root.stableName = "";

        adapter.latitude = "";
        adapter.longitude = "";
        adapter.name = "";
        adapter.weatherLastFetch = 0;
        adapter.weather = null;

        updateWeather();
    }

    /**
     * Get weather icon from WMO weather code
     * Returns Nerd Font icon - use with Theme.fontFamilyIcons
     */
    function weatherSymbolFromCode(code) {
        if (code === 0)
            return Icons.weatherSunny;           // Clear sky
        if (code === 1 || code === 2)
            return Icons.weatherPartlyCloudy;    // Partly cloudy
        if (code === 3)
            return Icons.weatherCloudy;          // Overcast
        if (code >= 45 && code <= 48)
            return Icons.weatherFog;             // Fog
        if (code >= 51 && code <= 67)
            return Icons.weatherRainy;           // Drizzle/Rain
        if (code >= 71 && code <= 77)
            return Icons.weatherSnowy;           // Snow
        if (code >= 80 && code <= 82)
            return Icons.weatherRainy;           // Rain showers
        if (code >= 85 && code <= 86)
            return Icons.weatherSnowy;           // Snow showers
        if (code >= 95 && code <= 99)
            return Icons.weatherThunderstorm;    // Thunderstorm
        return Icons.weatherCloudy;              // Default
    }

    /**
     * Get weather description from WMO weather code
     */
    function weatherDescriptionFromCode(code) {
        if (code === 0)
            return "Clear sky";
        if (code === 1)
            return "Mainly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 55)
            return "Drizzle";
        if (code >= 56 && code <= 57)
            return "Freezing drizzle";
        if (code >= 61 && code <= 65)
            return "Rain";
        if (code >= 66 && code <= 67)
            return "Freezing rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code >= 85 && code <= 86)
            return "Snow showers";
        if (code >= 95 && code <= 99)
            return "Thunderstorm";
        return "Unknown";
    }

    // ========================================================================
    // PRIVATE METHODS
    // ========================================================================

    function getFreshWeather() {
        isFetchingWeather = true;

        const currentLocation = Config.options.calendar?.weather?.location ?? "London";
        const locationChanged = adapter.name !== currentLocation;

        if (locationChanged) {
            root.coordinatesReady = false;
            Logger.info("Location changed to: " + currentLocation);
        }

        // Need geocoding?
        if (adapter.latitude === "" || adapter.longitude === "" || locationChanged) {
            geocodeLocation(currentLocation, function (lat, lon, name, country) {
                Logger.info("Geocoded " + currentLocation + " to: " + lat + ", " + lon);

                adapter.name = currentLocation;
                adapter.latitude = lat.toString();
                adapter.longitude = lon.toString();
                root.stableName = name + (country ? ", " + country : "");

                fetchWeather(lat, lon);
            }, errorCallback);
        } else {
            fetchWeather(adapter.latitude, adapter.longitude);
        }
    }

    function geocodeLocation(locationName, callback, errorCallback) {
        Logger.info("Geocoding: " + locationName);

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
        Logger.info("Fetching weather for: " + latitude + ", " + longitude);

        const url = "https://api.open-meteo.com/v1/forecast?" + "latitude=" + latitude + "&longitude=" + longitude + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m" + "&hourly=temperature_2m,weather_code,precipitation_probability" + "&daily=temperature_2m_max,temperature_2m_min,weather_code" + "&timezone=auto";

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const weatherData = JSON.parse(xhr.responseText);

                        // Save data
                        adapter.weather = weatherData;
                        adapter.weatherLastFetch = Math.floor(Date.now() / 1000);

                        // Update stable properties
                        root.stableLatitude = adapter.latitude = weatherData.latitude.toString();
                        root.stableLongitude = adapter.longitude = weatherData.longitude.toString();
                        root.coordinatesReady = true;

                        isFetchingWeather = false;
                        Logger.info("Weather data updated successfully");
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
