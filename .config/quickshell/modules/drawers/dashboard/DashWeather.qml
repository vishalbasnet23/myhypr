import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/bar/popouts"
import "root:/modules/drawers"
import "root:/services"

/**
 * Current conditions, then the next six hours.
 *
 * Location comes from services/Weather.qml, which reads `weather.location`
 * from quickshell/config.json and falls back to IP geolocation - nothing
 * about this machine's whereabouts is in the QML.
 *
 * Previously the hourly strip crammed six columns into the left of the panel
 * with 11px glyphs. Each column now fills an equal share of the width and the
 * glyphs are at the heading step, which is the smallest size they stay legible
 * at.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: Glass.cardGap

        // ---- current ----
        Card {
            Layout.fillWidth: true
            implicitHeight: 128

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Glass.spaceXs

                BarText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Weather.place
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Glass.spaceM

                    BarText {
                        text: Weather.iconFor(Weather.code, Weather.isDay)
                        color: Glass.accent
                        pixelSize: Glass.fontClock
                    }

                    BarText {
                        text: Weather.ready ? `${Math.round(Weather.temperature)}°C` : "--"
                        color: Glass.textGlass
                        pixelSize: Glass.fontBig
                    }
                }

                BarText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Weather.labelFor(Weather.code)
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                }
            }
        }

        // ---- detail ----
        Card {
            Layout.fillWidth: true
            implicitHeight: detail.implicitHeight + Glass.cardPadding * 2

            ColumnLayout {
                id: detail

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Glass.spaceXs

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
            }
        }

        // ---- next hours ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 0

                Repeater {
                    model: Weather.hourly

                    delegate: ColumnLayout {
                        required property var modelData

                        // Equal share of the card, so six columns spread
                        // across the panel instead of bunching at the left.
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: Glass.spaceXs

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
                            pixelSize: Glass.fontHeading
                        }

                        BarText {
                            Layout.alignment: Qt.AlignHCenter
                            text: `${Math.round(modelData.temp)}°`
                            color: Glass.textGlass
                            pixelSize: Glass.fontSize
                        }
                    }
                }
            }

            BarText {
                anchors.centerIn: parent
                visible: Weather.hourly.length === 0
                text: Weather.ready ? "No forecast available" : "Loading forecast…"
                color: Glass.textFaint
            }
        }
    }
}
