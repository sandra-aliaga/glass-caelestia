pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

Row {
    id: root

    required property ShellScreen screen

    property color colour: Colours.palette.m3secondary

    spacing: Appearance.spacing.small / 2

    // Clipboard history
    Item {
        implicitWidth: clipboardIcon.implicitWidth
        implicitHeight: clipboardIcon.implicitHeight

        MaterialIcon {
            id: clipboardIcon
            anchors.centerIn: parent
            text: "content_paste"
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "clipboard")
        }
    }

    // Quick notes
    Item {
        implicitWidth: notesIcon.implicitWidth
        implicitHeight: notesIcon.implicitHeight

        MaterialIcon {
            id: notesIcon
            anchors.centerIn: parent
            text: "edit_note"
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "notes")
        }
    }

    // Do not disturb toggle
    Item {
        implicitWidth: dndIcon.implicitWidth
        implicitHeight: dndIcon.implicitHeight

        MaterialIcon {
            id: dndIcon
            anchors.centerIn: parent
            animate: true
            text: Notifs.dnd ? "notifications_off" : "notifications"
            color: Notifs.dnd ? Colours.palette.m3primary : root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.dnd = !Notifs.dnd
        }
    }

    // Audio
    Item {
        visible: Config.bar.status.showAudio
        implicitWidth: audioIcon.implicitWidth
        implicitHeight: audioIcon.implicitHeight

        MaterialIcon {
            id: audioIcon
            anchors.centerIn: parent
            animate: true
            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "audio")
        }
    }

    // WiFi
    Item {
        visible: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)
        implicitWidth: wifiIcon.implicitWidth
        implicitHeight: wifiIcon.implicitHeight

        MaterialIcon {
            id: wifiIcon
            anchors.centerIn: parent
            animate: true
            text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "network")
        }
    }

    // Ethernet
    Item {
        visible: Config.bar.status.showNetwork && Nmcli.activeEthernet
        implicitWidth: ethernetIcon.implicitWidth
        implicitHeight: ethernetIcon.implicitHeight

        MaterialIcon {
            id: ethernetIcon
            anchors.centerIn: parent
            animate: true
            text: "cable"
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "ethernet")
        }
    }

    // Bluetooth
    Item {
        visible: Config.bar.status.showBluetooth
        implicitWidth: btIcon.implicitWidth
        implicitHeight: btIcon.implicitHeight

        MaterialIcon {
            id: btIcon
            anchors.centerIn: parent
            animate: true
            text: {
                if (!Bluetooth.defaultAdapter?.enabled) return "bluetooth_disabled"
                if (Bluetooth.devices.values.some(d => d.connected)) return "bluetooth_connected"
                return "bluetooth"
            }
            color: root.colour
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "bluetooth")
        }
    }

    // Battery
    Item {
        visible: Config.bar.status.showBattery && UPower.displayDevice.isLaptopBattery
        implicitWidth: battIcon.implicitWidth
        implicitHeight: battIcon.implicitHeight

        MaterialIcon {
            id: battIcon
            anchors.centerIn: parent
            animate: true
            text: {
                const perc = UPower.displayDevice.percentage
                const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
                if (perc === 1) return charging ? "battery_charging_full" : "battery_full"
                let level = Math.floor(perc * 7)
                if (charging && (level === 4 || level === 1)) level--
                return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`
            }
            color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2
                ? root.colour
                : Colours.palette.m3error
            fill: 1
            font.pointSize: Appearance.font.size.normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Visibilities.showPopout(Hypr.monitorFor(root.screen), "battery")
        }
    }
}
