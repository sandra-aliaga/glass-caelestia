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

    // Only workspaces belonging to this monitor, sorted by id
    readonly property var monitorWorkspaces: Hypr.workspaces.values
        .filter(ws => ws.monitor?.name === root.monitor?.name)
        .sort((a, b) => a.id - b.id)

    spacing: 6

    Repeater {
        model: ScriptModel { values: root.monitorWorkspaces }

        // Flat rectangular indicator — the active one stretches wider
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
}
