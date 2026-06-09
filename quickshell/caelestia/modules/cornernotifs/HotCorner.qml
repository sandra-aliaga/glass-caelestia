import Quickshell
import Quickshell.Wayland
import QtQuick

// Invisible 20x20 trigger anchored to bottom-left corner
PanelWindow {
    id: root

    signal triggered()
    signal released()

    WlrLayershell.namespace: "glass-hotcorner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors { bottom: true; left: true }
    implicitWidth: 20
    implicitHeight: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.triggered()
        onExited: root.released()
    }
}
