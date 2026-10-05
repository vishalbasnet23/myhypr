import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import "root:/modules/drawers"
import "root:/services"
import ".."

/**
 * Weather detail, hung under the bar's weather module.
 *
 * Deliberately its own layout rather than reusing DashWeather: that one is
 * built for a 400px panel with fillHeight cards, and stretching a panel layout
 * into a popout is what broke the media card earlier. Same data, same tokens,
 * sized for this context.
 */
ColumnLayout {
    id: root

    property int preferredWidth: 300

    spacing: Glass.spaceS

    PopoutHeader {
        text: "Weather"
    }

    // ---- current ----
    RowLayout {
        Layout.fillWidth: true
        spacing: Glass.spaceM

        BarText {
            text: Weather.iconFor(Weather.code, Weather.isDay)
            color: Glass.accent
            pixelSize: Glass.fontClock
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            BarText {
                text: Weather.ready ? `${Math.round(Weather.temperature)}°C` : "--"
                color: Glass.textGlass
                pixelSize: Glass.fontBig
            }

            BarText {
                text: Weather.labelFor(Weather.code)
                color: Glass.textDim
                pixelSize: Glass.fontMeta
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BarText {
                text: Weather.place
                color: Glass.textFaint
                pixelSize: Glass.fontMeta
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Glass.glassBorder
    }

    PopoutRow {
        label: "Feels like"
        value: Weather.ready ? `${Math.round(Weather.feelsLike)}°C` : "--"
    }

    PopoutRow {
        label: "Humidity"
        value: `${Weather.humidity}%`
    }

    PopoutRow {
        label: "Wind"
        value: `${Weather.windSpeed.toFixed(1)} km/h`
    }

    // ---- next hours ----
    Card {
        Layout.fillWidth: true
        Layout.topMargin: Glass.spaceXs
        implicitHeight: hours.implicitHeight + Glass.cardPadding * 2
        visible: Weather.hourly.length > 0

        RowLayout {
            id: hours

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: Weather.hourly

                delegate: ColumnLayout {
                    required property var modelData

                    // Equal share, so the columns spread rather than bunch.
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.hour.slice(0, 2)
                        color: Glass.textDim
                        pixelSize: Glass.fontMeta
                    }

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Weather.iconFor(modelData.code, true)
                        color: Glass.textGlass
                        pixelSize: Glass.fontTitle
                    }

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${Math.round(modelData.temp)}°`
                        color: Glass.textGlass
                        pixelSize: Glass.fontMeta
                    }
                }
            }
        }
    }

    BarText {
        visible: !Weather.ready
        text: "Loading forecast…"
        color: Glass.textFaint
        pixelSize: Glass.fontMeta
    }
}
