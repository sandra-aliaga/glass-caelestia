pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Raw "id\tpreview" lines from cliphist list
    property list<string> entries: []

    function refresh(): void {
        listProc.running = true;
    }

    function preview(entry: string): string {
        const tab = entry.indexOf("\t");
        return tab >= 0 ? entry.slice(tab + 1) : entry;
    }

    function copy(entry: string): void {
        Quickshell.execDetached(["sh", "-c", `printf '%s' "$0" | cliphist decode | wl-copy`, entry]);
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l.length > 0)
        }
    }
}
