pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick

Column {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.normal
    width: Config.bar.sizes.clipboardWidth

    Component.onCompleted: Cliphist.refresh()

    StyledText {
        text: qsTr("Clipboard history")
        font.weight: 500
    }

    StyledListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, Config.bar.sizes.clipboardHeight)
        clip: true

        model: ScriptModel {
            values: Cliphist.entries
        }

        delegate: Item {
            id: entry

            required property string modelData
            readonly property string preview: Cliphist.preview(modelData)
            readonly property bool isImage: preview.startsWith("[[ binary data")

            width: list.width
            implicitHeight: row.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                radius: Appearance.rounding.small

                function onClicked(): void {
                    Cliphist.copy(entry.modelData);
                    root.wrapper.hasCurrent = false;
                }
            }

            Row {
                id: row

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.isImage ? "image" : "content_paste"
                    color: Colours.palette.m3outlineVariant
                    font.pointSize: Appearance.font.size.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x
                    text: entry.isImage ? qsTr("Image") : entry.preview.trim()
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }
        }
    }

    StyledText {
        visible: Cliphist.entries.length === 0
        text: qsTr("History is empty")
        color: Colours.palette.m3outline
        font.pointSize: Appearance.font.size.small
    }
}
