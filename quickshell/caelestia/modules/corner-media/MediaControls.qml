import qs.services
import qs.components
import qs.config
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    spacing: Appearance.spacing.normal

    MediaButton {
        text: "skip_previous"
        onClicked: Players.active?.previous()
    }

    MediaButton {
        text: Players.active?.isPlaying ? "pause" : "play_arrow"
        highlighted: true
        onClicked: Players.active?.togglePlaying()
    }

    MediaButton {
        text: "skip_next"
        onClicked: Players.active?.next()
    }

    component MediaButton: Item {
        id: btn

        property string text
        property bool highlighted: false
        signal clicked()

        width: highlighted ? 28 : 20
        height: highlighted ? 28 : 20

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: parent.highlighted
                ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.2)
                : Qt.rgba(1, 1, 1, 0.06)
            border.color: parent.highlighted
                ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.3)
                : "transparent"
            border.width: 1
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: btn.text
            font.pointSize: Appearance.font.size.normal
            color: btn.highlighted ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            animate: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
