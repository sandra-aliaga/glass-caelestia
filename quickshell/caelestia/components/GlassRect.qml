import qs.services
import qs.config
import QtQuick

Rectangle {
    id: root

    // Dynamic tint from Material You surface color; alpha from transparency config
    color: Qt.rgba(
        Colours.palette.m3surface.r,
        Colours.palette.m3surface.g,
        Colours.palette.m3surface.b,
        Appearance.transparency.enabled ? 0.55 : 0.92
    )
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
