import qs.components.misc
import Quickshell
import QtQuick

// Orchestrates HotCorner + LazyLoader panel + keybind toggle
Item {
    id: root

    property bool open: false

    Timer {
        id: closeTimer
        interval: 500
        onTriggered: root.open = false
    }

    HotCorner {
        onTriggered: {
            closeTimer.stop()
            root.open = true
        }
        onReleased: closeTimer.restart()
    }

    // Super+M — reuses $kbMusic keybind (music special workspace replaced by this panel)
    CustomShortcut {
        name: "showCornerMedia"
        description: "Toggle corner media panel"
        onPressed: root.open = !root.open
    }

    LazyLoader {
        loading: true  // preload in background at shell start

        CornerMediaPanel {
            open: root.open
        }
    }
}
