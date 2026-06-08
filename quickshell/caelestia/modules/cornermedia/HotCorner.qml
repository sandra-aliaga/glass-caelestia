import Quickshell
import Quickshell.Wayland
import QtQuick

// Invisible 20x20 trigger anchored to bottom-right corner
PanelWindow {
    id: root

    signal triggered()
    signal released()

    WlrLayershell.namespace: "glass-hotcorner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors { bottom: true; right: true }
    width: 20
    height: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.triggered()
        onExited: root.released()
    }
}
