pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/**
 * Notification server, replacing swaync.
 *
 * Capabilities and timeouts are taken from .config/swaync/config.json so
 * applications see the same contract they did before:
 *
 *   timeout           6s   (normal)
 *   timeout-low       3s
 *   timeout-critical  3s   - swaync's value; note this means critical
 *                            notifications DISMISS themselves, which is
 *                            unusual. Kept for fidelity; set
 *                            `criticalIsPersistent` to change it.
 *
 * Nothing is registered until this singleton is instantiated, so the server
 * only claims org.freedesktop.Notifications once the shell loads it - which is
 * why swaync must be stopped first, or the bus name is already taken and
 * quickshell logs "presumably because one is already registered".
 */
Singleton {
    id: root

    readonly property list<Notification> list: []
    property bool dnd: false
    /// Keep critical notifications on screen instead of expiring them.
    property bool criticalIsPersistent: true

    readonly property int count: list.length
    readonly property bool hasAny: count > 0

    // DESIGN.md §10 overrides the earlier swaync-parity values (6s/3s/3s with
    // critical expiring). Spec: 5s, and critical NEVER expires.
    readonly property int timeoutNormal: 5000
    readonly property int timeoutLow: 5000
    readonly property int timeoutCritical: 0

    signal popup(Notification n)

    function timeoutFor(n) {
        // An app-supplied expireTimeout wins, as it does in swaync.
        if (n.expireTimeout > 0)
            return n.expireTimeout * 1000;
        if (n.urgency === NotificationUrgency.Critical)
            return root.criticalIsPersistent ? 0 : root.timeoutCritical;   // 0 = never
        if (n.urgency === NotificationUrgency.Low)
            return root.timeoutLow;
        return root.timeoutNormal;
    }

    function dismiss(n) {
        const i = root.list.indexOf(n);
        if (i !== -1)
            root.list.splice(i, 1);
        n.dismiss();
    }

    function clearAll() {
        // Copy first: dismiss() mutates the list we are walking.
        const all = root.list.slice();
        root.list.length = 0;
        for (const n of all)
            n.dismiss();
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    NotificationServer {
        id: server

        // Mirrors swaync's advertised capabilities.
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        // swaync: "notification-inline-replies": false
        inlineReplySupported: false

        onNotification: n => {
            // Without this the notification is destroyed the moment this
            // handler returns - tracking is opt-in.
            n.tracked = true;
            root.list.unshift(n);

            Qt.callLater(() => {
                if (!root.dnd)
                    root.popup(n);
            });
        }
    }
}
