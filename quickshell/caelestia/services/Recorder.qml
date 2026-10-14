pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property int refCount: 0
    property bool needsStart
    property list<string> startArgs
    property bool needsStop
    property bool needsPause

    function start(extraArgs = []): void {
        needsStart = true;
        startArgs = extraArgs;
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        checkProc.running = true;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0 // Might get too large for int

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        running: true
        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => { // qmllint disable signal-handler-parameters
            const running = code === 0;

            if (running && root.needsStop) {
                commandProc.exec(["caelestia", "record"]);
                props.running = false;
                props.paused = false;
            } else if (running && root.needsPause) {
                commandProc.exec(["caelestia", "record", "-p"]);
                props.paused = !props.paused;
            } else if (!running && root.needsStart) {
                commandProc.exec(["caelestia", "record", ...root.startArgs]);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            } else if (running !== props.running && !commandProc.running) {
                // Reconcile recordings started or stopped outside the shell.
                props.running = running;
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;
        }
    }

    Process {
        id: commandProc

        // Wait for region selection or file finalisation before reconciling state.
        onExited: code => {
            if (code !== 0)
                console.warn("Screen recorder command failed:", JSON.stringify({ exitCode: code }));
            checkProc.running = true;
        }
    }

    // Poll only while a recording control is visible.
    Timer {
        interval: 1000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: checkProc.running = true
    }

    Connections {
        function onSecondsChanged(): void {
            props.elapsed++;
        }

        enabled: props.running && !props.paused
        target: Time // qmllint disable incompatible-type
    }
}
