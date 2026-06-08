import qs.services
import qs.config
import QtQuick

Item {
    id: root

    implicitHeight: 3
    implicitWidth: parent?.width ?? 200

    // Track background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.08)
        radius: 0
    }

    // Progress fill — animated smoothly while track plays
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 0
        color: Colours.palette.m3primary

        readonly property real progress: {
            const active = Players.active
            return active?.length ? active.position / active.length : 0
        }
        width: parent.width * progress

        Behavior on width { Anim { duration: Appearance.anim.durations.large } }
        Behavior on color { CAnim {} }
    }
}
