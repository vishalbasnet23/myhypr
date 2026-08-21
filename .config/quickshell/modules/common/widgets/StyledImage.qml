// Ported verbatim from MainstreamOS/dots-hyprland (modules/common/widgets/StyledImage.qml),
// with only the import style and singleton names changed: this config predates
// quickshell's `import qs.*` module URIs and uses `import "root:/..."` paths,
// and its config singleton is ConfigOptions rather than Config.
import QtQuick
import Quickshell
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

Image {
    asynchronous: true
    retainWhileLoading: true
    visible: opacity > 0
    opacity: (status === Image.Ready) ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    property list<string> fallbacks: []
    property int currentFallbackIndex: 0

    onStatusChanged: {
        if (status === Image.Error && currentFallbackIndex < fallbacks.length) {
            source = fallbacks[currentFallbackIndex];
            currentFallbackIndex += 1;
        }
    }

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
}
