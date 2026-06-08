pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

Row {
    id: root

    property color colour: Colours.palette.m3secondary

    spacing: Appearance.spacing.small / 2

    MaterialIcon {
        visible: Config.bar.status.showAudio
        animate: true
        text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    MaterialIcon {
        visible: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)
        animate: true
        text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    MaterialIcon {
        visible: Config.bar.status.showNetwork && Nmcli.activeEthernet
        animate: true
        text: "cable"
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    MaterialIcon {
        visible: Config.bar.status.showBluetooth
        animate: true
        text: {
            if (!Bluetooth.defaultAdapter?.enabled) return "bluetooth_disabled"
            if (Bluetooth.devices.values.some(d => d.connected)) return "bluetooth_connected"
            return "bluetooth"
        }
        color: root.colour
        font.pointSize: Appearance.font.size.normal
    }

    MaterialIcon {
        visible: Config.bar.status.showBattery && UPower.displayDevice.isLaptopBattery
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
}
