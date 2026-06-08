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

    WlrLayershell.namespace: "glass-corner-notifs"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; left: true }
    margins { bottom: 10; left: 10 }

    implicitWidth: open ? 320 : 0
    implicitHeight: Math.min(
        column.implicitHeight + Appearance.padding.normal * 2,
        (screen?.height ?? 1080) * 0.4
    )

    visible: implicitWidth > 0
    color: "transparent"

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    GlassClippingRect {
        anchors.fill: parent

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
                letterSpacing: 1
            }

            Repeater {
                model: ScriptModel { values: Notifs.list.values.slice(0, 8) }

                NotifCard {
                    Layout.fillWidth: true
                    modelData: modelData
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: Notifs.list.values.length === 0
                text: qsTr("No notifications")
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
