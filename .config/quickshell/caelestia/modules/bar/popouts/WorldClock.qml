pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Hover popout for the bar clock: current time in a few other timezones.
// Edit `zones` to change the list (IANA names, see `timedatectl list-timezones`).
Column {
    id: root

    readonly property var zones: [
        { tz: "UTC", label: "UTC" },
        { tz: "Asia/Kathmandu", label: "Kathmandu", home: true },
        { tz: "Australia/Sydney", label: "Sydney" },
        { tz: "Europe/London", label: "London" },
        { tz: "America/New_York", label: "New York" },
        { tz: "America/Los_Angeles", label: "Los Angeles" }
    ]

    // tz -> UTC offset in minutes. Resolved by `date` so DST is always right;
    // the QML JS engine has no Intl/timeZone support.
    property var offsets: ({})

    readonly property int localOffset: -Time.date.getTimezoneOffset()

    function zoneDate(offset: int): date {
        // A Date whose UTC fields read as wall-clock time in the target zone.
        return new Date(Time.date.getTime() + offset * 60000);
    }

    function formatTime(d: date): string {
        const h = d.getUTCHours();
        const m = String(d.getUTCMinutes()).padStart(2, "0");
        if (Units.twelveHourClock)
            return `${h % 12 || 12}:${m} ${h < 12 ? "am" : "pm"}`;
        return `${String(h).padStart(2, "0")}:${m}`;
    }

    function dayLabel(d: date): string {
        const local = zoneDate(localOffset);
        const diff = Math.round((Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()) - Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate())) / 86400000);
        if (diff === 1)
            return Tr.tr("Tomorrow");
        if (diff === -1)
            return Tr.tr("Yesterday");
        return Tr.tr("Today");
    }

    function diffLabel(offset: int): string {
        const d = offset - localOffset;
        if (d === 0)
            return Tr.tr("Same time");
        const a = Math.abs(d);
        const h = Math.floor(a / 60);
        const m = a % 60;
        return `${d > 0 ? "+" : "−"}${h}${m ? `:${String(m).padStart(2, "0")}` : ""}h`;
    }

    // Content.qml recreates this popout via a Loader on every open, so offsets
    // are re-resolved each time (cheap, and picks up DST changes).
    Component.onCompleted: offsetProc.running = true

    spacing: Tokens.spacing.medium
    width: 280

    RowLayout {
        width: parent.width
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "public"
            fontStyle: Tokens.font.icon.extraLarge
            color: Colours.palette.m3tertiary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Time.format("dddd, d MMMM")
                font: Tokens.font.title.medium
            }

            StyledText {
                text: Tr.tr("World clock").toUpperCase()
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Tokens.spacing.small

        Repeater {
            model: root.zones.filter(z => root.offsets[z.tz] !== undefined)

            RowLayout {
                id: row

                required property var modelData
                readonly property int offset: root.offsets[modelData.tz]
                readonly property date when: root.zoneDate(offset)

                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.fillWidth: !row.modelData.home
                            text: row.modelData.label
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: row.modelData.home ?? false
                            text: "home"
                            color: Colours.palette.m3tertiary
                            fill: 1
                        }

                        Item {
                            visible: row.modelData.home ?? false
                            Layout.fillWidth: true
                        }
                    }

                    StyledText {
                        text: `${root.dayLabel(row.when)} · ${root.diffLabel(row.offset)}`
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                StyledText {
                    text: root.formatTime(row.when)
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3tertiary
                }
            }
        }
    }

    Process {
        id: offsetProc

        // Prints "tz|+HHMM" per zone.
        command: ["sh", "-c", "for z; do printf '%s|%s\\n' \"$z\" \"$(TZ=$z date +%z)\"; done", "sh", ...root.zones.map(z => z.tz)]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const o = {};
                for (const line of text.trim().split("\n")) {
                    const [tz, off] = line.split("|");
                    const m = /^([+-])(\d\d)(\d\d)$/.exec(off ?? "");
                    if (m)
                        o[tz] = (m[1] === "-" ? -1 : 1) * (parseInt(m[2]) * 60 + parseInt(m[3]));
                }
                root.offsets = o;
            }
        }
    }
}
