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

    // Super+N — reuses $kbShowSidebar keybind (sidebar replaced by this panel)
    CustomShortcut {
        name: "showCornerNotifs"
        description: "Toggle corner notifications panel"
        onPressed: root.open = !root.open
    }

    LazyLoader {
        loading: true  // preload in background at shell start

        CornerNotifsPanel {
            open: root.open
        }
    }
}
