import qs.services
import qs.config
import QtQuick

Rectangle {
    id: root

    // Same translucent surface as every other shell panel (alpha from transparency config)
    color: Colours.tPalette.m3surface
    radius: 0
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    // Specular highlight — bright top edge simulates glass catching light
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.28)
        z: 1
    }

    Behavior on color { CAnim {} }
}
