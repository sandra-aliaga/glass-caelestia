import qs.services
import qs.components
import qs.config
import QtQuick

Item {
    id: root

    implicitWidth: label.width
    implicitHeight: label.implicitHeight

    StyledText {
        id: label

        // Cap width to avoid crowding the bar
        width: Math.min(implicitWidth, 280)
        anchors.verticalCenter: parent.verticalCenter

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        elide: Text.ElideRight
        font.family: Appearance.font.family.mono
        font.italic: true
        font.pointSize: Appearance.font.size.smaller
        color: Colours.palette.m3onSurfaceVariant
    }
}
