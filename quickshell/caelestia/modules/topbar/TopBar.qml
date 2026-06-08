pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import qs.components.effects
import "components"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
    margins { top: 10; left: 10; right: 10 }
    exclusiveZone: hasFullscreen ? 0 : height
    implicitHeight: 38

    color: "transparent"

    // Slide out on fullscreen
    y: hasFullscreen ? -height - 10 : 0
    Behavior on y {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    GlassRect {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // OS icon — opens launcher on click
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                ColouredIcon {
                    anchors.centerIn: parent
                    source: SysInfo.osLogo
                    implicitSize: Appearance.font.size.large
                    colour: Colours.palette.m3tertiary
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

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screen: root.screen
            }

            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
            }

            // Flexible spacer — pushes clock to center
            Item { Layout.fillWidth: true }

            Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            // Flexible spacer — clock stays centered
            Item { Layout.fillWidth: true }

            StatusIcons {
                Layout.alignment: Qt.AlignVCenter
            }

            Tray {
                Layout.alignment: Qt.AlignVCenter
            }

            PowerButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    const vis = Visibilities.getForActive()
                    if (vis) vis.session = !vis.session
                }
            }
        }
    }
}
