pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property string storagePath: `${Paths.state}/daily-log.json`
    readonly property string today: Qt.formatDate(Time.date, "yyyy-MM-dd")

    property bool loaded: false
    property string dateKey: today
    property bool done: false

    readonly property bool pending: dateKey !== today || !done
    readonly property bool overdue: pending && Time.hours >= 18
    readonly property color accentColor: pending ? (overdue ? Colours.palette.m3error : Colours.palette.m3tertiary) : Colours.palette.m3primary
    readonly property color idleColor: pending ? Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.75) : Qt.alpha(Colours.palette.m3primary, 0.8)

    Layout.alignment: Qt.AlignHCenter
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth

    function applyState(data: var): void {
        const next = data ?? {};
        dateKey = next.date ?? today;
        done = next.done === true;
    }

    RowLayout {
        id: content

        anchors.fill: parent
        spacing: Appearance.spacing.smaller

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.pending ? 8 : 7
            implicitHeight: implicitWidth
            radius: Appearance.rounding.full
            color: root.accentColor
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: root.pending ? "edit_note" : "task_alt"
            color: root.idleColor
            fill: root.pending ? 0 : 1
            font.pointSize: Math.round(Appearance.font.size.small * 0.95)
        }
    }

    StateLayer {
        color: root.accentColor
        radius: Appearance.rounding.small

        function onClicked(): void {
            DailyLog.compose();
        }
    }

    FileView {
        id: storage

        path: root.storagePath

        onLoaded: {
            try {
                root.applyState(JSON.parse(text()));
            } catch (err) {
                root.applyState({});
            }
            root.loaded = true;
        }

        onLoadFailed: _err => {
            root.applyState({});
            root.loaded = true;
        }
    }

    Timer {
        id: refreshTimer

        interval: 1200
        onTriggered: storage.reload()
    }

    Connections {
        target: Time

        function onDateChanged(): void {
            storage.reload();
        }
    }

    Connections {
        target: DailyLog

        function onLoadedChanged(): void {
            refreshTimer.restart();
        }
    }
}
