pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string storagePath: `${Paths.state}/scratchpad.md`

    property string text: ""
    property bool loaded: false

    function setText(value: string): void {
        if (text === value)
            return;
        text = value;
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(root.text)
    }

    FileView {
        id: storage

        path: root.storagePath

        onLoaded: {
            root.text = text();
            root.loaded = true;
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                setText("");
            }
        }
    }
}
