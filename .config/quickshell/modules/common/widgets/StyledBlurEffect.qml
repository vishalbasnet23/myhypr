// Ported verbatim from MainstreamOS/dots-hyprland (modules/common/widgets/StyledBlurEffect.qml),
// with only the import style and singleton names changed: this config predates
// quickshell's `import qs.*` module URIs and uses `import "root:/..."` paths,
// and its config singleton is ConfigOptions rather than Config.
import QtQuick
import QtQuick.Effects

MultiEffect {
    id: root
    source: wallpaper
    anchors.fill: source
    saturation: 0.2
    blurEnabled: true
    blurMax: 100
    blur: 1
}
