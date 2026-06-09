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

    screen: root.screen
    WlrLayershell.namespace: "glass-topbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    exclusiveZone: hasFullscreen ? 0 : height
    implicitHeight: 40
    visible: !hasFullscreen

    color: "transparent"

    GlassRect {
        anchors.fill: parent

        // Left section — launcher, workspaces, focused window
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Appearance.padding.large
            anchors.verticalCenter: parent.verticalCenter
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

            BarDivider {}

            Workspaces {
                screen: root.screen
            }

            BarDivider {}

            ActiveWindow {}
        }

        // Center section — clock
        Clock {
            anchors.centerIn: parent
        }

        // Right section — tray, status, power
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.large
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.normal

            Tray {}

            BarDivider {
                visible: SystemTray.items.values.length > 0
            }

            StatusIcons {}

            BarDivider {}

            PowerButton {
                onClicked: {
                    const vis = Visibilities.getForActive()
                    if (vis) vis.session = !vis.session
                }
            }
        }
    }

    // Thin vertical separator between bar sections
    component BarDivider: Rectangle {
        implicitWidth: 1
        implicitHeight: 16
        color: Qt.rgba(1, 1, 1, 0.12)
    }
}
