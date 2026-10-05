import QtQuick
import "root:/modules/common"
import ".."

/**
 * waybar's custom/separator variants. Glyphs are the exact codepoints from
 * .config/waybar/ModulesCustom, written as \u escapes so no editor or copy
 * step can silently mangle them:
 *
 *   #dot       U+F444 + space
 *   #dot-line  U+E621
 *   #line      "|"
 *   #blank     "" / two spaces / three spaces
 *
 * Glass.css gives separators @wb-faint, and they take no hover lift.
 */
BarItem {
    id: root

    property string kind: "blank"

    readonly property var glyphs: ({
            "dot": " ",
            "dot-line": "",
            "line": "|",
            "blank": "",
            "blank_2": "  ",
            "blank_3": "   "
        })

    interactive: false
    color: "transparent"
    // Blanks are pure spacing. In waybar they compensated for GTK's own box
    // model; here the RowLayout already provides the gap, so they shrink to a
    // hairline of extra breathing room instead of a full module's width.
    implicitWidth: kind.startsWith("blank") ? 2 : label.implicitWidth + Glass.itemPaddingH * 2

    BarText {
        id: label

        text: root.glyphs[root.kind] ?? ""
        color: Glass.textFaint
        visible: !root.kind.startsWith("blank")
    }
}
