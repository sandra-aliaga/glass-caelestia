pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Caelestia
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    // Keeps the wrapper from closing the panel while in use
    readonly property bool hold: panelHover.hovered || notesArea.activeFocus

    // Follow the focused monitor so the panel opens where the user is working
    screen: Hypr.focusedScreen

    WlrLayershell.namespace: "glass-corner-media"
    WlrLayershell.layer: open ? WlrLayer.Overlay : WlrLayer.Top
    // OnDemand so the notes area can take keyboard focus when clicked
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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

        HoverHandler {
            id: panelHover
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

            // ── Toasts section (flat single-line rows, intentionally subtle) ──
            Repeater {
                model: ScriptModel { values: root.activeToasts.slice(0, 4) }

                delegate: RowLayout {
                    id: toastRow

                    required property Toast modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small
                    opacity: 0.85

                    MaterialIcon {
                        text: toastRow.modelData.icon || "info"
                        color: {
                            if (toastRow.modelData.type === Toast.Success) return Colours.palette.m3primary
                            if (toastRow.modelData.type === Toast.Error) return Colours.palette.m3error
                            if (toastRow.modelData.type === Toast.Warning) return Colours.palette.m3secondary
                            return Colours.palette.m3outlineVariant
                        }
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: toastRow.modelData.message.length > 0
                            ? `${toastRow.modelData.title} — ${toastRow.modelData.message}`
                            : toastRow.modelData.title
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }

                    MaterialIcon {
                        text: "close"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3outlineVariant

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toastRow.modelData.close()
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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ── Quick notes section ───────────────────────────────────────
            StyledText {
                Layout.fillWidth: true
                text: qsTr("Notes")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outlineVariant
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(notesArea.implicitHeight, 120)
                contentWidth: width
                contentHeight: notesArea.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                TextArea.flickable: TextArea {
                    id: notesArea

                    wrapMode: TextEdit.Wrap
                    text: Scratchpad.text
                    onTextChanged: Scratchpad.setText(text)
                    Keys.onEscapePressed: focus = false

                    placeholderText: qsTr("Quick notes…")
                    placeholderTextColor: Colours.palette.m3outline
                    color: Colours.palette.m3onSurface
                    font.family: Appearance.font.family.sans
                    font.pointSize: Appearance.font.size.small
                    padding: 0
                    background: null

                    Connections {
                        target: Scratchpad

                        function onTextChanged(): void {
                            if (notesArea.text !== Scratchpad.text)
                                notesArea.text = Scratchpad.text;
                        }
                    }
                }
            }
        }
    }
}
