import qs.services
import qs.components
import qs.config
import QtQuick

// Focus timer: click to start/pause, right click to reset
Item {
    id: root

    readonly property color tone: {
        if (!Pomodoro.active) return Colours.palette.m3onSurfaceVariant
        if (Pomodoro.onBreak) return Colours.palette.m3tertiary
        return Pomodoro.running ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        spacing: Appearance.spacing.small / 2

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            animate: true
            text: Pomodoro.onBreak ? "coffee" : "timer"
            color: root.tone
            font.pointSize: Appearance.font.size.normal
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: Pomodoro.active
            text: Pomodoro.timeText()
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
            color: root.tone
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Pomodoro.reset()
            else
                Pomodoro.toggle()
        }
    }
}
