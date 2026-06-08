import qs.services
import qs.components
import qs.components.images
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    CachingImage {
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        Layout.alignment: Qt.AlignVCenter
        source: Players.active?.trackCoverUrl ?? ""
        fillMode: Image.PreserveAspectCrop

        MaterialIcon {
            anchors.centerIn: parent
            visible: parent.source.toString().length === 0
            text: "music_note"
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.extraLarge
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackTitle ?? qsTr("Nothing playing")
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackArtists?.join(", ") ?? ""
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
