import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick

// Invisible 20x20 trigger anchored to bottom-right corner
PanelWindow {
    id: root

    signal triggered()
    signal released()

    // Focus follows the mouse across monitors, so this keeps the corner under the cursor
    screen: Hypr.focusedScreen

    WlrLayershell.namespace: "glass-hotcorner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors { bottom: true; right: true }
    implicitWidth: 20
    implicitHeight: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.triggered()
        onExited: root.released()
    }
}
