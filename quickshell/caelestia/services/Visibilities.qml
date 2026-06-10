pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property var panels: new Map()  // keyed by HyprlandMonitor

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hypr.focusedMonitor);
    }

    function showPopout(monitor, name: string): void {
        const p = panels.get(monitor)
        if (!p) return
        p.popouts.currentName = name
        p.popouts.hasCurrent = true
    }
}
