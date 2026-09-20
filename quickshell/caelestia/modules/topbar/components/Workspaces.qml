pragma ComponentBehavior: Bound

import qs.services
import qs.utils
import qs.config
import qs.components
import qs.components.images
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    required property ShellScreen screen

    readonly property var monitor: Hypr.monitorFor(screen)
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1

    // Regular workspaces only (id >= 0) — special workspaces have negative IDs
    readonly property var monitorWorkspaces: Hypr.workspaces.values
        .filter(ws => ws.monitor?.name === root.monitor?.name && ws.id >= 0)
        .sort((a, b) => a.id - b.id)

    // Special workspaces that currently hold a window, one entry per workspace
    // with a representative app class so we can show its icon in the bar.
    readonly property var specialClients: {
        const groups = {};
        for (const t of Hypr.toplevels.values) {
            const ws = t.workspace;
            if (!ws || ws.id >= 0)
                continue;
            const name = ws.name ?? "";
            if (!groups[name])
                groups[name] = {
                    name,
                    short: name.replace(/^special:/, ""),
                    appClass: t.lastIpcObject?.class ?? ""
                };
        }
        return Object.values(groups);
    }

    // Name of the special workspace currently visible on this monitor (if any)
    readonly property string activeSpecial: monitor?.lastIpcObject?.specialWorkspace?.name ?? ""

    spacing: 6

    Repeater {
        model: ScriptModel { values: root.monitorWorkspaces }

        delegate: Item {
            required property var modelData

            readonly property bool isActive: modelData.id === root.activeWsId
            readonly property bool isUrgent: modelData.urgent

            width: isActive ? 36 : 22
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                Anim {
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            Rectangle {
                anchors.fill: parent
                color: parent.isActive
                    ? Colours.palette.m3primary
                    : parent.isUrgent
                        ? Qt.alpha(Colours.palette.m3error, 0.35)
                        : Qt.rgba(1, 1, 1, 0.10)
                radius: 0

                Behavior on color { CAnim {} }
            }

            StyledText {
                anchors.centerIn: parent
                text: modelData.id.toString()
                font.pointSize: Appearance.font.size.small
                color: parent.isActive
                    ? Colours.palette.m3onPrimary
                    : Colours.palette.m3onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.dispatch(`workspace ${modelData.id}`)
            }
        }
    }

    // Divider before the special-workspace app icons (only if any exist)
    Rectangle {
        visible: root.specialClients.length > 0
        width: 1
        height: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    // One icon per special workspace holding a window (Discord, Spotify, …).
    // Highlighted when that scratchpad is currently visible; click toggles it.
    Repeater {
        model: ScriptModel { values: root.specialClients }

        delegate: Item {
            required property var modelData

            readonly property bool isActive: root.activeSpecial === modelData.name

            width: 22
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                color: parent.isActive ? Colours.palette.m3tertiary : Qt.rgba(1, 1, 1, 0.10)
                radius: 0

                Behavior on color { CAnim {} }
            }

            CachingIconImage {
                anchors.centerIn: parent
                implicitSize: 13
                source: Icons.getAppIcon(parent.modelData.appClass, "application-x-executable")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.dispatch(`togglespecialworkspace ${parent.modelData.short}`)
            }
        }
    }
}
