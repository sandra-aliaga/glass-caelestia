pragma ComponentBehavior: Bound

import qs.services
import qs.utils
import qs.config
import qs.components
import qs.components.effects
import "components"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property var hyprMonitor: Hypr.monitorFor(screen)
    // Slide bar out when there's a fullscreen window on this monitor
    readonly property bool hasFullscreen: hyprMonitor?.activeWorkspace?.toplevels.values
        .some(t => t.lastIpcObject.fullscreen === 2) ?? false

    readonly property int islandPadding: Appearance.padding.large

    screen: root.screen
    WlrLayershell.namespace: "glass-topbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    exclusiveZone: hasFullscreen ? 0 : height + 8
    implicitHeight: 40
    visible: !hasFullscreen

    color: "transparent"

    // Left island — workspaces and focused window
    GlassRect {
        id: leftIsland

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: leftRow.implicitWidth + root.islandPadding * 2

        RowLayout {
            id: leftRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            // OS icon — opens launcher on click
            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                ColouredIcon {
                    anchors.centerIn: parent
                    source: SysInfo.osLogo
                    implicitSize: 18
                    colour: Colours.palette.m3primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const vis = Visibilities.getForActive()
                        if (vis) vis.launcher = !vis.launcher
                    }
                }
            }

            IslandDivider {}

            Workspaces {
                screen: root.screen
            }

            IslandDivider {}

            ActiveWindow {}
        }
    }

    // Center island — clock
    GlassRect {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: clock.implicitWidth + root.islandPadding * 2

        Clock {
            id: clock
            anchors.centerIn: parent
        }
    }

    // Right island — system status and power
    GlassRect {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: rightRow.implicitWidth + root.islandPadding * 2

        RowLayout {
            id: rightRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            Tray {}

            IslandDivider {
                visible: SystemTray.items.values.length > 0
            }

            StatusIcons {}

            IslandDivider {}

            PowerButton {
                onClicked: {
                    const vis = Visibilities.getForActive()
                    if (vis) vis.session = !vis.session
                }
            }
        }
    }

    // Thin vertical separator used between island sections
    component IslandDivider: Rectangle {
        implicitWidth: 1
        implicitHeight: 16
        color: Qt.rgba(1, 1, 1, 0.12)
    }
}
