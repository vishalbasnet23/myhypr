import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {

    property QtObject appearance: QtObject {
        property int fakeScreenRounding: 1 // 0: None | 1: Always | 2: When not fullscreen
    }

    property QtObject overview: QtObject {
        property real scale: 0.15 // Relative to screen size
        property real numOfRows: 2
        property real numOfCols: 5
        property bool showXwaylandIndicator: true
        property real windowPadding: 6 
        property real position: 1 // 0: top | 1: middle | 2: bottom
        property real workspaceNumberSize: 120 // Set 0, dynamic calculation based on monitor size
    }

    property QtObject resources: QtObject {
        property int updateInterval: 3000
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 20 // milliseconds
    }

    property QtObject search: QtObject {
    property bool searchEnabled: false
    property int nonAppResultDelay: 30 // This prevents lagging when typing
    property QtObject prefix: QtObject {
            property string action: "/"
            property string clipboard: ";"
            property string emojis: ":"
        }
    }
    
    property QtObject bar: QtObject {
        property bool bottom: false // Instead of top

        // Geometry of the *waybar* surface, so the quickshell media pill can be
        // parked in the gap left by the removed waybar mpris module. These must
        // match waybar: `width` and `margin-top` from waybar/configs/VB23, the
        // rendered height from `hyprctl layers` (ns=waybar), and the
        // .modules-left margin+padding from waybar/style/New.css (10px + 4px).
        property real waybarWidth: 1444
        property real waybarHeight: 36
        property real waybarMarginTop: 5
        property real waybarSidePadding: 14
    }

    property QtObject media: QtObject {
        property real pillWidth: 220     // keep in sync with #custom-mediapill min-width
        property real popupWidth: 420
        property int hoverCloseDelay: 350 // ms of grace when moving pill -> popup
    }
}
