import Quickshell
import QtQuick

// One TopBar instance per connected monitor — auto-created/destroyed as monitors change
Variants {
    model: Quickshell.screens

    delegate: Component {
        TopBar {
            required property var modelData
            screen: modelData
        }
    }
}
