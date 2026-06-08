pragma Singleton
pragma ComponentBehavior: Bound

import qs.utils
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string scriptPath: `${Paths.home}/.local/bin/daily-log`
    readonly property string storagePath: `${Paths.state}/daily-log.json`
    readonly property string today: Qt.formatDate(Time.date, "yyyy-MM-dd")

    property bool loaded: false
    property string dateKey: today
    property bool done: false
    property string didToday: ""
    property string blockers: ""
    property string tomorrow: ""
    property string message: ""
    property string updatedAt: ""

    readonly property bool pending: dateKey !== today || !done
    readonly property bool overdue: pending && Time.hours >= 18
    readonly property string statusText: pending ? (overdue ? qsTr("Daily pendiente") : qsTr("Pendiente hoy")) : qsTr("Marcado hoy")

    function defaultState(): var {
        return {
            date: today,
            done: false,
            didToday: "",
            blockers: "",
            tomorrow: "",
            message: "",
            updatedAt: ""
        };
    }

    function applyState(data: var): void {
        const next = data ?? defaultState();
        dateKey = next.date ?? today;
        done = next.done === true;
        didToday = next.didToday ?? "";
        blockers = next.blockers ?? "";
        tomorrow = next.tomorrow ?? "";
        message = next.message ?? "";
        updatedAt = next.updatedAt ?? "";
    }

    function save(): void {
        storage.setText(JSON.stringify({
            date: dateKey,
            done: done,
            didToday: didToday,
            blockers: blockers,
            tomorrow: tomorrow,
            message: message,
            updatedAt: updatedAt
        }, null, 2));
    }

    function reset(): void {
        applyState(defaultState());
        save();
    }

    function ensureToday(): void {
        if (dateKey !== today) {
            applyState(defaultState());
            save();
        }
    }

    function compose(): void {
        Quickshell.execDetached([scriptPath, "compose"]);
        reloadTimer.restart();
    }

    function reload(): void {
        storage.reload();
    }

    FileView {
        id: storage

        path: root.storagePath

        onLoaded: {
            try {
                root.applyState(JSON.parse(text()));
            } catch (err) {
                console.warn(`[DailyLog] Failed to parse state: ${err}`);
                root.applyState(root.defaultState());
                setText(JSON.stringify(root.defaultState(), null, 2));
            }

            root.loaded = true;
            root.ensureToday();
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.applyState(root.defaultState());
                root.loaded = true;
                setText(JSON.stringify(root.defaultState(), null, 2));
            } else {
                console.warn(`[DailyLog] Failed to load state: ${FileViewError.toString(err)}`);
            }
        }
    }

    Timer {
        id: reloadTimer

        interval: 1200
        onTriggered: storage.reload()
    }

    Connections {
        target: Time

        function onDateChanged(): void {
            root.ensureToday();
        }
    }

    IpcHandler {
        target: "dailyLog"

        function compose(): void {
            root.compose();
        }

        function reload(): void {
            root.reload();
        }

        function reset(): void {
            root.reset();
        }

        function status(): string {
            return root.pending ? "pending" : "done";
        }
    }
}
