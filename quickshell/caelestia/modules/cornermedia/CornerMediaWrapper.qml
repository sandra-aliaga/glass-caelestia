import qs.components.misc
import Caelestia
import Quickshell
import QtQuick

// Orchestrates HotCorner + LazyLoader panel + keybind toggle + toast auto-open
Item {
    id: root

    property bool userOpen: false

    // Auto-open when there are active toasts
    readonly property bool hasToasts: {
        Toaster.toasts  // track list changes
        return Toaster.toasts.some(t => !t.closed)
    }

    readonly property bool open: userOpen || hasToasts

    Timer {
        id: closeTimer
        interval: 500
        onTriggered: root.userOpen = false
    }

    Connections {
        target: Toaster
        // When a new toast arrives, ensure panel stays open long enough to read it
        function onToastsChanged() {
            const active = Toaster.toasts.filter(t => !t.closed)
            if (active.length > 0) {
                const timeout = active[0].expireTimeout
                closeTimer.interval = Math.max(timeout > 0 ? timeout + 500 : 3000, 3000)
                closeTimer.stop()
                root.userOpen = true
                closeTimer.start()
            }
        }
    }

    HotCorner {
        onTriggered: {
            closeTimer.stop()
            root.userOpen = true
        }
        onReleased: closeTimer.restart()
    }

    // Super+M — reuses $kbMusic keybind
    CustomShortcut {
        name: "showCornerMedia"
        description: "Toggle corner media panel"
        onPressed: {
            if (root.userOpen) {
                closeTimer.stop()
                root.userOpen = false
            } else {
                closeTimer.stop()
                root.userOpen = true
            }
        }
    }

    LazyLoader {
        loading: true  // preload in background at shell start

        CornerMediaPanel {
            open: root.open
        }
    }
}
