pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property bool open: false

    function filterMatch(text: string): bool {
        return search.text.length === 0 || text.toLowerCase().includes(search.text.toLowerCase());
    }

    readonly property var filtered: {
        if (search.text.length === 0)
            return Keybinds.categories;
        const q = search.text.toLowerCase();
        return Keybinds.categories
            .map(c => ({ name: c.name, binds: c.binds.filter(b => `${b.combo} ${b.description}`.toLowerCase().includes(q)) }))
            .filter(c => c.binds.length > 0);
    }

    screen: Hypr.focusedScreen

    WlrLayershell.namespace: "glass-cheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    visible: open
    color: "transparent"

    onOpenChanged: {
        if (open) {
            search.text = "";
            search.forceActiveFocus();
        }
    }

    // Dim backdrop — click anywhere outside the card to dismiss
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    GlassRect {
        anchors.centerIn: parent
        width: Math.min(760, root.width - Appearance.padding.large * 4)
        height: Math.min(card.implicitHeight + Appearance.padding.large * 2, root.height - Appearance.padding.large * 4)

        // Swallow clicks so they don't reach the dismiss backdrop
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: card

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "keyboard"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Atajos de teclado")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: searchRow.implicitHeight + Appearance.padding.normal * 2
                color: Colours.tPalette.m3surfaceContainer
                radius: Appearance.rounding.normal

                RowLayout {
                    id: searchRow

                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.normal
                    anchors.rightMargin: Appearance.padding.normal
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "search"
                        color: Colours.palette.m3outline
                    }

                    StyledTextField {
                        id: search

                        Layout.fillWidth: true
                        placeholderText: qsTr("Buscar atajo…")
                        Keys.onEscapePressed: root.open = false
                    }
                }
            }

            StyledFlickable {
                id: flick

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(grid.implicitHeight, root.height * 0.7)
                contentWidth: width
                contentHeight: grid.implicitHeight
                clip: true

                ColumnLayout {
                    id: grid

                    width: flick.width
                    spacing: Appearance.spacing.large

                    Repeater {
                        model: root.filtered

                        delegate: ColumnLayout {
                            id: category

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: category.modelData.name
                                color: Colours.palette.m3primary
                                font.pointSize: Appearance.font.size.small
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1
                            }

                            Repeater {
                                model: category.modelData.binds

                                delegate: RowLayout {
                                    id: bind

                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.normal

                                    StyledRect {
                                        Layout.preferredWidth: 180
                                        implicitHeight: comboText.implicitHeight + Appearance.padding.small
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        radius: Appearance.rounding.small

                                        StyledText {
                                            id: comboText

                                            anchors.centerIn: parent
                                            text: bind.modelData.combo
                                            font.family: Appearance.font.family.mono
                                            font.pointSize: Appearance.font.size.small
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: bind.modelData.description
                                        color: Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Appearance.font.size.small
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
