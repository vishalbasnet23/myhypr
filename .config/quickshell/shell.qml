//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import "./modules/bar/"
import "./modules/drawers/"
import "./modules/notifications/"
import "./modules/common/"
import "./modules/overview/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "./services/"

ShellRoot {
    // Enable/disable modules here. False = not loaded at all, so rest assured
    // no unnecessary stuff will take up memory if you decide to only use, say, the overview.
    property bool enableOverview: true
    // The Vibrant Glass bar - a port of waybar's VB23 profile. While this is
    // true AND waybar is running, the bar sits below waybar for comparison
    // (see Glass.barCompareOffset).
    property bool enableBar: true
    // Notification server + popups + centre, replacing swaync. Turning this
    // off releases org.freedesktop.Notifications so swaync can take it back.
    property bool enableNotifications: true
    // Drawer panels (dashboard, and later launcher/sidebar/session/osd).
    property bool enablePanels: true

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
    }

    Loader { active: enableOverview; sourceComponent: Overview {} }
    Loader { active: enableBar; sourceComponent: Bar {} }
    Loader { active: enableNotifications; sourceComponent: Popups {} }
    Loader { active: enableNotifications; sourceComponent: Center {} }
    Loader { active: enablePanels; sourceComponent: Drawers {} }

}