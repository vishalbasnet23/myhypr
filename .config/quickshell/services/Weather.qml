pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Weather from Open-Meteo: current conditions plus the next few hours.
 *
 * Location is NOT hard-coded. It is resolved in this order:
 *   1. `weather.location` in ~/.config/quickshell/config.json - either
 *      "lat,lon" or a place name
 *   2. ip-api.com geolocation
 *
 * The existing UserScripts/Weather.sh stays untouched and still feeds the bar
 * module; this is a separate reader because the bar needs one line of text
 * while the dashboard needs structured hourly data.
 */
Singleton {
    id: root

    property string location: ""      // resolved "lat,lon"
    property string place: ""         // human-readable
    property bool ready: false

    property real temperature: 0
    property real feelsLike: 0
    property int humidity: 0
    property real windSpeed: 0
    property int code: -1
    property bool isDay: true

    /// [{ hour: "14:00", temp: 12.3, code: 3 }, …]
    property var hourly: []

    // WMO weather codes -> glyph + label. Same families the waybar script uses.
    // Nerd Font weather glyphs (nf-weather-*), verified present in
    // Maple Mono NF CN with `fc-list :charset=...`. Emoji rendered tiny and
    // monochrome and are not part of the icon set (DESIGN.md §4).
    function iconFor(c, day) {
        const cp = (() => {
            if (c === 0)
                return day ? 0xE30D : 0xE32B;          // clear / clear night
            if (c <= 2)
                return day ? 0xE302 : 0xE37E;          // partly cloudy
            if (c === 3)
                return 0xE312;                          // overcast
            if (c <= 48)
                return 0xE313;                          // fog
            if (c <= 57)
                return 0xE309;                          // drizzle
            if (c <= 67)
                return 0xE318;                          // rain
            if (c <= 77)
                return 0xE31A;                          // snow
            if (c <= 82)
                return 0xE309;                          // showers
            if (c <= 86)
                return 0xE31A;                          // snow showers
            return 0xE31D;                              // thunderstorm
        })();
        return String.fromCodePoint(cp);
    }

    function labelFor(c) {
        if (c === 0)
            return "Clear";
        if (c <= 2)
            return "Partly cloudy";
        if (c === 3)
            return "Overcast";
        if (c <= 48)
            return "Fog";
        if (c <= 57)
            return "Drizzle";
        if (c <= 67)
            return "Rain";
        if (c <= 77)
            return "Snow";
        if (c <= 82)
            return "Showers";
        if (c <= 86)
            return "Snow showers";
        return "Thunderstorm";
    }

    FileView {
        id: config

        path: `${Quickshell.env("HOME")}/.config/quickshell/config.json`
        blockLoading: true
        printErrors: false

        Component.onCompleted: {
            let loc = "";
            try {
                loc = (JSON.parse(text())?.weather?.location ?? "").trim();
            } catch (e) {
            // no config, or no weather section - fall through to geolocation
            }
            if (loc !== "" && /^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$/.test(loc)) {
                root.location = loc.replace(/\s/g, "");
                root.place = root.location;
                fetch.restart();
            } else if (loc !== "") {
                geocode.command = ["curl", "-s", "-m", "8", `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(loc)}&count=1&format=json`];
                geocode.running = true;
            } else {
                geoip.running = true;
            }
        }
    }

    Process {
        id: geoip

        command: ["curl", "-s", "-m", "8", "http://ip-api.com/json?fields=status,city,lat,lon"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if (d.status === "success") {
                        root.location = `${d.lat},${d.lon}`;
                        root.place = d.city ?? root.location;
                        fetch.restart();
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: geocode

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(this.text)?.results?.[0];
                    if (r) {
                        root.location = `${r.latitude},${r.longitude}`;
                        root.place = r.name;
                        fetch.restart();
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetch

        function restart() {
            if (root.location === "")
                return;
            const [lat, lon] = root.location.split(",");
            command = ["curl", "-s", "-m", "10", `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day" + "&hourly=temperature_2m,weather_code&forecast_hours=8&timezone=auto"];
            running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    const c = d.current;
                    root.temperature = c.temperature_2m;
                    root.feelsLike = c.apparent_temperature;
                    root.humidity = c.relative_humidity_2m;
                    root.windSpeed = c.wind_speed_10m;
                    root.code = c.weather_code;
                    root.isDay = c.is_day === 1;

                    const out = [];
                    const times = d.hourly?.time ?? [];
                    for (let i = 0; i < Math.min(6, times.length); i++)
                        out.push({
                            hour: times[i].slice(11, 16),
                            temp: d.hourly.temperature_2m[i],
                            code: d.hourly.weather_code[i]
                        });
                    root.hourly = out;
                    root.ready = true;
                } catch (e) {}
            }
        }
    }

    // Open-Meteo updates hourly; no point asking more often.
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: fetch.restart()
    }
}
