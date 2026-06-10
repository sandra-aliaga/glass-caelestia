pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Caelestia
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    // Follow the focused monitor so the panel opens where the user is working
    screen: Hypr.focusedScreen

    WlrLayershell.namespace: "glass-corner-media"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property real reveal: open ? 1 : 0

    readonly property var activeToasts: {
        Toaster.toasts  // track list changes
        return Toaster.toasts.filter(t => !t.closed)
    }
    readonly property bool hasMedia: Players.current !== null

    anchors { bottom: true; right: true }
    margins { bottom: 10; right: 10 }

    implicitWidth: 300
    implicitHeight: content.implicitHeight + Appearance.padding.large * 2

    visible: glass.reveal > 0.01
    color: "transparent"

    GlassClippingRect {
        id: glass

        property real reveal: root.reveal

        width: parent.width
        height: parent.height
        x: (1 - reveal) * width
        opacity: reveal

        Behavior on reveal {
            Anim {
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.padding.large
            }
            spacing: Appearance.spacing.normal

            // ── Toasts section ────────────────────────────────────────────
            StyledText {
                visible: root.activeToasts.length > 0
                Layout.fillWidth: true
                text: qsTr("Notifications")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            Repeater {
                model: ScriptModel { values: root.activeToasts.slice(0, 4) }

                delegate: GlassRect {
                    required property Toast modelData

                    Layout.fillWidth: true
                    implicitHeight: toastLayout.implicitHeight + Appearance.padding.smaller * 2

                    RowLayout {
                        id: toastLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Appearance.padding.smaller
                            leftMargin: Appearance.padding.normal
                        }
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: modelData.icon || "notifications"
                            color: {
                                if (modelData.type === Toast.Success) return Colours.palette.m3primary
                                if (modelData.type === Toast.Error) return Colours.palette.m3error
                                if (modelData.type === Toast.Warning) return Colours.palette.m3secondary
                                return Colours.palette.m3onSurfaceVariant
                            }
                            font.pointSize: Appearance.font.size.normal
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: modelData.message
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                                opacity: 0.8
                            }
                        }

                        MaterialIcon {
                            text: "close"
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3outlineVariant

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.close()
                            }
                        }
                    }
                }
            }

            // Separator between toasts and media (when both visible)
            Rectangle {
                visible: root.activeToasts.length > 0 && root.hasMedia
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ── Media section ─────────────────────────────────────────────
            StyledText {
                visible: root.hasMedia
                Layout.fillWidth: true
                text: qsTr("Media")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            MediaInfo {
                visible: root.hasMedia
                Layout.fillWidth: true
            }
            MediaProgress {
                visible: root.hasMedia
                Layout.fillWidth: true
            }
            MediaControls {
                visible: root.hasMedia
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ── Daily log section ─────────────────────────────────────────
            StyledText {
                Layout.fillWidth: true
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
