pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded

    // Max notifications kept per app ("stack"); oldest beyond this are closed.
    // Not exposed in shell.json — Config keys come from the compiled plugin.
    property int maxPerApp: 10

    // list is newest-first, so entries past the cap are the oldest
    function trimStack(appName: string): void {
        let kept = 0;
        for (const n of root.list) {
            if (n.closed || n.appName !== appName)
                continue;
            if (++kept > root.maxPerApp)
                n.close();
        }
    }

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    // Toast -> notification bridge: every Toaster.toast() (audio device change,
    // now playing, battery, VPN, DND, game mode, IPC toasts...) is re-posted as a
    // regular notification so it shows in the normal popup + notification centre
    // instead of the separate bottom-right toast stack. Toasts are closed right
    // away (no locks yet, so the plugin drops them synchronously and the toast UI
    // never shows them). Any toast still open here is therefore a new one.
    function toastIcon(icon: string): string {
        if (icon.startsWith("volume") || icon === "no_sound")
            return "audio-volume-high-symbolic";
        if (icon.startsWith("mic"))
            return "audio-input-microphone-symbolic";
        if (icon === "music_note")
            return "media-playback-start-symbolic";
        if (icon.startsWith("battery") || icon.startsWith("power"))
            return "battery-symbolic";
        if (icon.startsWith("vpn"))
            return "network-vpn-symbolic";
        if (icon.startsWith("do_not_disturb"))
            return "notifications-disabled-symbolic";
        if (icon === "gamepad")
            return "input-gaming-symbolic";
        if (icon === "error" || icon === "warning")
            return "dialog-warning-symbolic";
        return "dialog-information-symbolic";
    }

    function toastAppName(icon: string): string {
        if (icon.startsWith("volume") || icon === "no_sound" || icon.startsWith("mic"))
            return "Audio";
        if (icon === "music_note")
            return "Now Playing";
        return "System";
    }

    function postToast(toast: Toast): void {
        const appName = toastAppName(toast.icon);

        // Now playing / audio device changes replace the previous one instead of
        // piling up (Bluetooth reconnects fire output+input changes repeatedly)
        if (appName === "Now Playing" || appName === "Audio")
            for (const n of root.list.slice())
                if (!n.closed && n.appName === appName && n.summary === Tr.trMarked(toast.title))
                    n.close();

        const comp = notifComp.createObject(root, {
            popup: root.shouldShowPopup(),
            // titles may carry a Tr marker; resolve it like ToastItem does
            summary: Tr.trMarked(toast.title),
            body: Tr.trMarked(toast.message),
            hints: ({}),
            appName: appName,
            appIcon: toastIcon(toast.icon),
            expireTimeout: toast.timeout,
            urgency: toast.type === Toast.Error ? NotificationUrgency.Critical : NotificationUrgency.Normal
        });
        root.list = [comp, ...root.list];
        root.trimStack(appName);
    }

    Connections {
        function onToastsChanged(): void {
            for (const toast of [...Toaster.toasts]) {
                if (toast.closed)
                    continue;
                root.postToast(toast);
                toast.close();
            }
        }

        target: Toaster
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                }))))
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
            root.trimStack(comp.appName);
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data) {
                const properties = Object.assign({}, notif);

                // Backwards compatibility for old notifications
                if (properties.notificationId === undefined && properties.id !== undefined)
                    properties.notificationId = properties.id;

                delete properties.id;
                root.list.push(notifComp.createObject(root, properties));
            }
            root.list.sort((a, b) => b.time - a.time);
            for (const appName of new Set(root.list.map(n => n.appName)))
                root.trimStack(appName);
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
