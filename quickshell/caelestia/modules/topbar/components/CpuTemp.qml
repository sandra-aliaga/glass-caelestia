import qs.services
import qs.components
import qs.components.misc
import qs.config
import QtQuick

// CPU temperature readout; turns to the error colour above warnTemp
Row {
    id: root

    readonly property int warnTemp: 75
    readonly property bool hot: SystemUsage.cpuTemp >= warnTemp
    readonly property color tone: hot ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant

    spacing: Appearance.spacing.small / 2

    // Keeps SystemUsage polling alive while the bar is loaded
    Ref {
        service: SystemUsage
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: "device_thermostat"
        color: root.tone
        font.pointSize: Appearance.font.size.small
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(SystemUsage.cpuTemp)}°`
        font.pointSize: Appearance.font.size.small
        font.family: Appearance.font.family.mono
        color: root.tone
    }
}
