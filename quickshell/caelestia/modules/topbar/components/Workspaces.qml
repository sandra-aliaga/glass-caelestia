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

    spacing: 4

    Repeater {
        model: ScriptModel { values: root.monitorWorkspaces }

        delegate: Item {
            required property var modelData

            readonly property bool isActive: modelData.id === root.activeWsId
            readonly property bool isUrgent: modelData.urgent

            width: 18
            height: 18

            Rectangle {
                anchors.fill: parent
                color: parent.isActive
                    ? Colours.palette.m3primary
                    : Qt.rgba(1, 1, 1, parent.isUrgent ? 0.25 : 0.08)
                radius: 0

                Behavior on color { CAnim {} }
            }

            // Urgent dot — cleared automatically by Hyprland when workspace is visited
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 2
                width: 4
                height: 4
                radius: 2
                color: Colours.palette.m3error
                visible: parent.isUrgent && !parent.isActive
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
