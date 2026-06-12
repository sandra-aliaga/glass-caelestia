pragma Singleton

import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int focusMinutes: 25
    readonly property int breakMinutes: 5
    readonly property string storagePath: `${Paths.state}/pomodoro.json`
    readonly property string today: Qt.formatDate(Time.date, "yyyy-MM-dd")

    property bool running: false
    property bool onBreak: false
    property int remaining: focusMinutes * 60
    property int completedToday: 0
    property string dateKey: today

    // True once a session was started, even while paused
    readonly property bool active: running || onBreak || remaining !== focusMinutes * 60

    function toggle(): void {
        running = !running;
    }

    function reset(): void {
        running = false;
        onBreak = false;
        remaining = focusMinutes * 60;
    }

    function timeText(): string {
        const m = Math.floor(remaining / 60);
        const s = remaining % 60;
        return `${m}:${s.toString().padStart(2, "0")}`;
    }

    function save(): void {
        storage.setText(JSON.stringify({
            date: dateKey,
            completedToday: completedToday
        }, null, 2));
    }

    function ensureToday(): void {
        if (dateKey !== today) {
            dateKey = today;
            completedToday = 0;
            save();
        }
    }

    Timer {
        running: root.running
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.remaining > 1) {
                root.remaining--;
                return;
            }

            if (root.onBreak) {
                root.onBreak = false;
                root.remaining = root.focusMinutes * 60;
                root.running = false;
                Toaster.toast(qsTr("Break over"), qsTr("Ready for the next focus round"), "timer", Toast.Info);
            } else {
                root.ensureToday();
                root.completedToday++;
                root.save();
                root.onBreak = true;
                root.remaining = root.breakMinutes * 60;
                Toaster.toast(qsTr("Focus complete"), qsTr("%1 today — take a break").arg(root.completedToday), "self_improvement", Toast.Success);
            }
        }
    }

    FileView {
        id: storage

        path: root.storagePath

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.dateKey = data.date ?? root.today;
                root.completedToday = data.completedToday ?? 0;
            } catch (err) {
                console.warn(`[Pomodoro] Failed to parse state: ${err}`);
            }
            root.ensureToday();
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.save();
        }
    }

    Connections {
        target: Time

        function onDateChanged(): void {
            root.ensureToday();
        }
    }

    IpcHandler {
        target: "pomodoro"

        function toggle(): void {
            root.toggle();
        }

        function reset(): void {
            root.reset();
        }

        function status(): string {
            const phase = root.onBreak ? "break" : "focus";
            const state = root.running ? "running" : "paused";
            return `${phase} ${state} ${root.timeText()} (${root.completedToday} today)`;
        }
    }
}
