pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
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

    // Whether a special workspace is currently visible on this monitor
    readonly property bool hasSpecialWs: !!(monitor?.lastIpcObject?.specialWorkspace?.name)

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

    // Special workspace indicator — small accent dot when one is active
    Rectangle {
        visible: root.hasSpecialWs
        width: 6
        height: 6
        radius: 0
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3tertiary

        Behavior on opacity { CAnim {} }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hypr.dispatch("togglespecialworkspace")
        }
    }
}
