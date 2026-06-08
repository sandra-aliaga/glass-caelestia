import qs.components
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    signal clicked()

    width: icon.implicitWidth + Appearance.padding.small * 2
    height: icon.implicitHeight + Appearance.padding.small * 2

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "power_settings_new"
        color: Colours.palette.m3error
        font.pointSize: Appearance.font.size.normal
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
