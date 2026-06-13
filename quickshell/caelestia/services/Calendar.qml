pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

// Upcoming events from a (secret) ICS calendar URL. The heavy lifting —
// fetching, parsing and expanding recurrences — is done by a Python helper
// (utils/scripts/calendar-agenda.py) so this just runs it and parses JSON.
Singleton {
    id: root

    readonly property string python: `${Paths.state}/calendar-venv/bin/python`
    readonly property string script: `${Paths.data}/quickshell/caelestia/utils/scripts/calendar-agenda.py`

    // [{ summary, location, start (ISO), end (ISO), allDay }]
    property var events: []
    property string error: ""
    property bool loading: false
    property bool configured: true

    function refresh(): void {
        if (loading)
            return;
        loading = true;
        proc.running = true;
    }

    Timer {
        running: true
        triggeredOnStart: true
        interval: 900000 // 15 min
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc

        command: [root.python, root.script]

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const out = text.trim();
                if (out.length === 0) {
                    root.events = [];
                    return;
                }
                try {
                    const data = JSON.parse(out);
                    if (data && data.error) {
                        root.error = data.error;
                        root.configured = !`${data.error}`.includes("calendar url");
                        root.events = [];
                    } else {
                        root.error = "";
                        root.configured = true;
                        root.events = data;
                    }
                } catch (e) {
                    root.error = `bad output: ${e}`;
                    root.events = [];
                }
            }
        }
    }
}
