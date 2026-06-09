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

    WlrLayershell.namespace: "glass-corner-media"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; right: true }
    margins { bottom: 10; right: 10 }

    implicitWidth: open ? 280 : 0
    implicitHeight: content.implicitHeight + Appearance.padding.large * 2

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
            id: content

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.padding.large
            }
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Media")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            MediaInfo { Layout.fillWidth: true }
            MediaProgress { Layout.fillWidth: true }
            MediaControls { Layout.alignment: Qt.AlignHCenter }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            StyledText {
                text: qsTr("Daily log")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            DailyLogView { Layout.fillWidth: true }
        }
    }
}
