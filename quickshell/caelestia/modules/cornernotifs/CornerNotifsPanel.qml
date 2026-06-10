pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    // Follow the focused monitor so the panel opens where the user is working
    screen: Hypr.focusedScreen

    WlrLayershell.namespace: "glass-corner-notifs"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Slide progress 0..1 — animating content instead of window size keeps it smooth
    readonly property real reveal: open ? 1 : 0

    anchors { bottom: true; left: true }
    margins { bottom: 10; left: 10 }

    implicitWidth: 320
    implicitHeight: Math.min(
        column.implicitHeight + Appearance.padding.normal * 2,
        (screen?.height ?? 1080) * 0.4
    )

    visible: glass.reveal > 0.01
    color: "transparent"

    GlassClippingRect {
        id: glass

        property real reveal: root.reveal

        width: parent.width
        height: parent.height
        x: (reveal - 1) * width  // slide in from the left edge
        opacity: reveal

        Behavior on reveal {
            Anim {
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        ColumnLayout {
            id: column

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.padding.normal
            }
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Notifications")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            Repeater {
                model: ScriptModel { values: Notifs.list.filter(n => !n.closed).slice(0, 8) }

                NotifCard {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: Notifs.list.filter(n => !n.closed).length === 0
                text: qsTr("No notifications")
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
