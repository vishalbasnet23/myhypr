import QtQuick
import Quickshell
import "root:/modules/common"
import ".."

/**
 * Both clocks from waybar's group/time:
 *
 *   clock#4  "{:%B | %a %d, %Y | %I:%M %p}"          (local, always visible)
 *   clock#6  "{:%I:%M %p} NST"  timezone Asia/Kathmandu  (in the drawer)
 *
 * `short: true` + `suffix` gives the clock#6 form.
 *
 * Qt's Date has no named-timezone support without QTimeZone, which QML does
 * not expose, so the offset is applied numerically. Asia/Kathmandu is
 * UTC+05:45 year-round - Nepal observes no DST - so a fixed offset is correct
 * here rather than merely convenient.
 */
BarItem {
    id: root

    /// IANA name, for documentation; only Asia/Kathmandu is special-cased.
    property string timezone: ""
    property string suffix: ""
    /// Time only, no date.
    property bool short: false

    readonly property var offsets: ({
            "Asia/Kathmandu": 5.75
        })

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    function two(n) {
        return n < 10 ? `0${n}` : `${n}`;
    }

    function shifted(date) {
        if (!root.timezone || root.offsets[root.timezone] === undefined)
            return date;
        const utcMs = date.getTime() + date.getTimezoneOffset() * 60000;
        return new Date(utcMs + root.offsets[root.timezone] * 3600000);
    }

    function fmt(raw) {
        const date = root.shifted(raw);
        const months = ["January", "February", "March", "April", "May", "June",
                        "July", "August", "September", "October", "November", "December"];
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

        let h = date.getHours();
        const ampm = h < 12 ? "AM" : "PM";
        h = h % 12;
        if (h === 0)
            h = 12;
        const time = `${root.two(h)}:${root.two(date.getMinutes())} ${ampm}`;

        if (root.short)
            return `${time}${root.suffix}`;
        return `${months[date.getMonth()]} | ${days[date.getDay()]} ${date.getDate()}, ${date.getFullYear()} | ${time}`;
    }

    BarText {
        text: root.fmt(clock.date)
        color: root.short ? Glass.textDim : Glass.textGlass
    }
}
