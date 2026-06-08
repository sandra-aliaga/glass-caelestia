pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

GlassRect {
    id: root

    required property Notifs.Notif modelData

    readonly property color urgencyColor: {
        switch (modelData.urgency) {
            case "critical": return Colours.palette.m3error
            case "normal":   return Colours.palette.m3primary
            default:         return Colours.palette.m3outline
        }
    }

    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2
    implicitWidth: parent?.width ?? 320

    // Left stripe indicating urgency level
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.urgencyColor
    }

    RowLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.padding.normal
            leftMargin: Appearance.padding.normal + 4
        }
        spacing: Appearance.spacing.small

        CachingIconImage {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignTop
            source: root.modelData.appIcon
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.summary
                elide: Text.ElideRight
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.modelData.body
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "close"
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outlineVariant

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modelData.dismiss()
            }
        }
    }
}
