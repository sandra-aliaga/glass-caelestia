pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property string scriptPath: `${Paths.home}/.local/bin/daily-log`

    property bool open: false
    property string didToday: ""
    property string blockers: ""
    property string tomorrow: ""
    property Item firstField: null

    signal submitted

    anchors.fill: parent
    visible: open
    enabled: open
    focus: open
    z: 1000

    function openEditor(nextDidToday: string, nextBlockers: string, nextTomorrow: string): void {
        didToday = nextDidToday;
        blockers = nextBlockers;
        tomorrow = nextTomorrow;
        open = true;
        Qt.callLater(() => firstField?.forceActiveFocus());
    }

    function closeEditor(): void {
        open = false;
    }

    function save(): void {
        Quickshell.execDetached([scriptPath, "submit", didToday, blockers, tomorrow]);
        open = false;
        submitted();
    }

    Keys.onEscapePressed: event => {
        root.closeEditor();
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.42)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeEditor()
        }
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent
        width: Math.min(620, parent.width - Appearance.padding.large * 4)
        height: Math.min(560, parent.height - Appearance.padding.large * 4)
        color: Colours.palette.m3surfaceContainerHigh
        radius: Appearance.rounding.large
        scale: root.open ? 1 : 0.96
        opacity: root.open ? 1 : 0
        clip: true
        z: 1

        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 1.2
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Daily Log")
                font.pointSize: Appearance.font.size.large
                font.weight: 600
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Escribe tranquilo acá. Al guardar se copia el mensaje y se abre Discord.")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }

            ScrollView {
                id: scroll

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: Appearance.spacing.normal

                    Field {
                        id: didTodayField

                        Layout.fillWidth: true
                        label: qsTr("Qué hice hoy")
                        value: root.didToday
                        placeholderValue: qsTr("Mañana: continué con las preguntas de física con figura...")
                        onValueEdited: value => root.didToday = value
                    }

                    Field {
                        Layout.fillWidth: true
                        label: qsTr("Bloqueos / problemas")
                        value: root.blockers
                        placeholderValue: qsTr("Ninguno")
                        onValueEdited: value => root.blockers = value
                    }

                    Field {
                        Layout.fillWidth: true
                        label: qsTr("Qué haré mañana")
                        value: root.tomorrow
                        placeholderValue: qsTr("Seguir con...")
                        onValueEdited: value => root.tomorrow = value
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                TextButton {
                    text: qsTr("Cancelar")
                    type: TextButton.Text
                    onClicked: root.closeEditor()
                }

                Item {
                    Layout.fillWidth: true
                }

                IconTextButton {
                    icon: "content_copy"
                    text: qsTr("Copiar y abrir")
                    onClicked: root.save()
                }
            }
        }
    }

    component Field: ColumnLayout {
        id: fieldRoot

        required property string label
        required property string value
        property string placeholderValue: ""
        signal valueEdited(string value)

        spacing: Appearance.spacing.smaller / 2

        StyledText {
            text: fieldRoot.label
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 116
            color: editor.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Appearance.rounding.small
            border.width: 1
            border.color: editor.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.25)
            clip: true

            Behavior on color {
                CAnim {}
            }

            Behavior on border.color {
                CAnim {}
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor

                onPressed: mouse => {
                    editor.forceActiveFocus();
                    editor.cursorPosition = editor.positionAt(mouse.x - editor.x, mouse.y - editor.y);
                    mouse.accepted = false;
                }
            }

            TextEdit {
                id: editor

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                activeFocusOnPress: true
                selectByKeyboard: true
                color: Colours.palette.m3onSurface
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                persistentSelection: true
                font.family: Appearance.font.family.sans
                font.pointSize: Appearance.font.size.smaller
                clip: true
                textFormat: TextEdit.PlainText

                Binding {
                    target: editor
                    property: "text"
                    value: fieldRoot.value
                    when: !editor.activeFocus
                }

                onTextChanged: fieldRoot.valueEdited(text)
            }

            Loader {
                active: fieldRoot.value.length === 0 && !editor.activeFocus
                anchors.fill: editor
                anchors.margins: Appearance.padding.normal

                sourceComponent: StyledText {
                    text: fieldRoot.placeholderValue
                    color: Colours.palette.m3outline
                    wrapMode: Text.WordWrap
                }
            }

            Component.onCompleted: {
                if (fieldRoot === didTodayField)
                    root.firstField = editor;
            }
        }
    }
}
