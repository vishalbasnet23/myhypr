pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    function powerProfileToString(p: int): string {
        switch (p) {
        case PowerProfile.Balanced:
            return Tr.trCtx("Balanced", "power profile");
        case PowerProfile.Performance:
            return Tr.trCtx("Performance", "power profile");
        case PowerProfile.PowerSaver:
            return Tr.trCtx("Power saver", "power profile");
        default:
            return Tr.trCtx("Unknown", "power profile");
        }
    }

    function perfDegradationToString(p: int): string {
        switch (p) {
        case PerformanceDegradationReason.HighTemperature:
            return Tr.tr("The device is too hot");
        case PerformanceDegradationReason.LapDetected:
            return Tr.tr("The device is on a lap");
        default:
            return Tr.tr("Unknown reason");
        }
    }

    function formatShort(s: int): string {
        if (s <= 0)
            return "—";
        const hr = Math.floor(s / 3600);
        const min = Math.floor(s / 60) % 60;
        return hr > 0 ? `${hr}h ${min}m` : `${min}m`;
    }

    function stateToString(s: int): string {
        switch (s) {
        case UPowerDeviceState.Charging:
            return Tr.trCtx("Charging", "battery state");
        case UPowerDeviceState.Discharging:
            return Tr.trCtx("On battery", "battery state");
        case UPowerDeviceState.FullyCharged:
            return Tr.trCtx("Fully charged", "battery state");
        case UPowerDeviceState.PendingCharge:
            return Tr.trCtx("Holding at limit", "battery state");
        case UPowerDeviceState.Empty:
            return Tr.trCtx("Empty", "battery state");
        default:
            return Tr.trCtx("Plugged in", "battery state");
        }
    }

    readonly property var dev: UPower.displayDevice
    readonly property bool hasBattery: dev.isLaptopBattery
    // PendingCharge = held at the charge limit, not taking charge: no bolt.
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged].includes(dev.state)
    readonly property bool low: UPower.onBattery && dev.percentage <= 0.2

    readonly property var stats: {
        const s = [];
        if (BatteryInfo.energyFullWh > 0)
            s.push([Tr.tr("Capacity"), `${BatteryInfo.energyFullWh.toFixed(1)} Wh`]);
        if (dev.state === UPowerDeviceState.Discharging)
            s.push([Tr.tr("Time left"), formatShort(dev.timeToEmpty)]);
        else if (dev.state === UPowerDeviceState.Charging && dev.timeToFull > 0)
            s.push([Tr.tr("Time to full"), formatShort(dev.timeToFull)]);
        else if (dev.state === UPowerDeviceState.PendingCharge && BatteryInfo.startThreshold > 0)
            // TLP holds between start and end thresholds; charging resumes below start.
            s.push([Tr.tr("Resumes at"), `${BatteryInfo.startThreshold}%`]);
        if (BatteryInfo.health > 0)
            s.push([Tr.tr("Health"), `${Math.round(BatteryInfo.health * 100)}%`]);
        if (Math.abs(dev.changeRate) > 0.05) {
            const label = dev.state === UPowerDeviceState.Charging ? Tr.tr("Charging") : dev.state === UPowerDeviceState.Discharging ? Tr.tr("Draw") : Tr.tr("Rate");
            s.push([label, `${Math.abs(dev.changeRate).toFixed(1)} W`]);
        }
        if (BatteryInfo.cycleCount > 0)
            s.push([Tr.tr("Cycles"), `${BatteryInfo.cycleCount}`]);
        return s;
    }

    // Content.qml recreates this popout via a Loader on every open.
    Component.onCompleted: BatteryInfo.refresh()

    spacing: Tokens.spacing.medium
    width: Math.max(Tokens.sizes.bar.batteryWidth, 300)

    StyledText {
        visible: !root.hasBattery
        text: Tr.tr("Power profile: %1").arg(root.powerProfileToString(PowerProfiles.profile))
    }

    RowLayout {
        visible: root.hasBattery
        width: parent.width
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: Icons.getBatteryIcon(root.dev.percentage, root.charging)
            fontStyle: Tokens.font.icon.extraLarge
            color: root.low ? Colours.palette.m3error : Colours.palette.m3primary
            fill: 1
            animate: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Tr.tr("Battery")
                font: Tokens.font.title.medium
            }

            StyledText {
                text: root.stateToString(root.dev.state).toUpperCase()
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            text: `${Math.round(root.dev.percentage * 100)}%`
            font: Tokens.font.headline.medium
            color: root.low ? Colours.palette.m3error : Colours.palette.m3onSurface
            animate: true
        }
    }

    StyledProgressBar {
        visible: root.hasBattery
        width: parent.width
        implicitHeight: Tokens.padding.small
        value: root.dev.percentage
        fgColour: root.low ? Colours.palette.m3error : Colours.palette.m3primary
        wavy: root.dev.state === UPowerDeviceState.Charging
    }

    GridLayout {
        visible: root.hasBattery
        width: parent.width
        columns: 2
        columnSpacing: Tokens.spacing.large
        rowSpacing: Tokens.spacing.extraSmall

        Repeater {
            model: root.stats

            RowLayout {
                id: stat

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: stat.modelData[0]
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                StyledText {
                    text: stat.modelData[1]
                    font: Tokens.font.body.small
                }
            }
        }
    }

    StyledText {
        visible: root.hasBattery
        text: Tr.tr("Power profile").toUpperCase()
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }

    Loader {
        asynchronous: true
        anchors.horizontalCenter: parent.horizontalCenter

        active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

        height: active ? ((item as Item)?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: child.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: child.implicitHeight + Tokens.padding.large

            color: Colours.palette.m3error
            radius: Tokens.rounding.large

            Column {
                id: child

                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        // TRANSLATORS: charger or thermal warning: the battery cannot draw full power
                        text: Tr.tr("Performance degraded")
                        color: Colours.palette.m3onError
                        font: Tokens.font.title.small
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: root.perfDegradationToString(PowerProfiles.degradationReason)
                    color: Colours.palette.m3onError
                }
            }
        }
    }

    StyledRect {
        id: profiles

        property string current: {
            const p = PowerProfiles.profile;
            if (p === PowerProfile.PowerSaver)
                return saver.icon;
            if (p === PowerProfile.Performance)
                return perf.icon;
            return balance.icon;
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: saver.implicitHeight + balance.implicitHeight + perf.implicitHeight + Tokens.padding.medium * 2 + Tokens.spacing.largeIncreased * 2
        implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + Tokens.padding.small

        color: Colours.tPalette.m3surfaceContainer
        radius: Config.appearance.rounding.scale > 0 ? Tokens.rounding.full : 0

        StyledRect {
            id: indicator

            color: Colours.palette.m3primary
            radius: Config.appearance.rounding.scale > 0 ? Tokens.rounding.full : 0
            state: profiles.current

            states: [
                State {
                    name: saver.icon

                    Fill {
                        item: saver
                    }
                },
                State {
                    name: balance.icon

                    Fill {
                        item: balance
                    }
                },
                State {
                    name: perf.icon

                    Fill {
                        item: perf
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }
        }

        Profile {
            id: saver

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.extraSmall

            profile: PowerProfile.PowerSaver
            icon: "energy_savings_leaf"
        }

        Profile {
            id: balance

            anchors.centerIn: parent

            profile: PowerProfile.Balanced
            icon: "balance"
        }

        Profile {
            id: perf

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.extraSmall

            profile: PowerProfile.Performance
            icon: "rocket_launch"
        }
    }

    StyledText {
        visible: root.hasBattery && BatteryInfo.thresholdsSupported
        text: `${Tr.tr("Charge limit").toUpperCase()} · ${BatteryInfo.endThreshold}%`
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }

    RowLayout {
        visible: root.hasBattery && BatteryInfo.thresholdsSupported
        width: parent.width
        spacing: Tokens.spacing.small

        Repeater {
            model: BatteryInfo.chargePresets.map(p => p.stop)

            TextButton {
                id: limitBtn

                required property int modelData
                readonly property bool active: BatteryInfo.endThreshold === modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1

                type: TextButton.Tonal
                checked: active
                internalChecked: active
                disabled: BatteryInfo.settingLimit
                text: `${modelData}%`
                onClicked: if (!active)
                    BatteryInfo.setChargeLimit(modelData)
            }
        }
    }

    component Fill: AnchorChanges {
        required property Item item

        target: indicator
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component Profile: Item {
        required property string icon
        required property int profile

        implicitWidth: icon.implicitHeight + Tokens.padding.small
        implicitHeight: icon.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Config.appearance.rounding.scale > 0 ? Tokens.rounding.full : 0
            color: profiles.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: PowerProfiles.profile = parent.profile
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent

            text: parent.icon
            fontStyle: Tokens.font.icon.large
            color: profiles.current === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: profiles.current === text ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
