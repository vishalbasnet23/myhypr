import QtQuick
import Quickshell
import Quickshell.Io
import "root:/modules/common"
import "root:/services"
import "../popouts"
import ".."

/**
 * waybar custom/weather:
 *   exec      $HOME/.config/hypr/UserScripts/Weather.sh
 *   exec-if   ping api.open-meteo.com -c1
 *   interval  3600
 *   return-type json
 *
 * The script is reused untouched - it already emits waybar's
 * {text, alt, tooltip, class} contract, which WaybarScript.qml parses.
 *
 * Glass.css colours this module by weather class (.sunnyDay, .rainyDay,
 * .severe, …); the mapping below keeps those associations.
 */
BarItem {
    id: root

    readonly property var classColours: ({
            "sunnyDay": Glass.yellow,
            "clearNight": Glass.subtext1,
            "cloudyFoggyDay": Glass.overlay2,
            "cloudyFoggyNight": Glass.overlay1,
            "rainyDay": Glass.sapphire,
            "rainyNight": Glass.sapphire,
            "showyIcyDay": Glass.sky,
            "snowyIcyNight": Glass.sky,
            "severe": Glass.critical,
            "default": Glass.textGlass
        })

    visible: script.valid && script.text.length > 0

    // Hover detail, same as the other bar widgets.
    popoutId: "weather"
    popout: Component {
        WeatherPopout {}
    }

    WaybarScript {
        id: script

        command: ["bash", `${Quickshell.env("HOME")}/.config/hypr/UserScripts/Weather.sh`]
        execIf: ["ping", "api.open-meteo.com", "-c1", "-W", "2"]
        intervalSec: 3600
        json: true
    }

    BarText {
        text: script.text
        color: root.classColours[script.cssClass] ?? Glass.textGlass
    }
}
