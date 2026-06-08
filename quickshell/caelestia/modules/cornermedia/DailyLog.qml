import qs.components
import qs.services
import qs.config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.small / 2

    StyledText {
        Layout.fillWidth: true
        text: Time.format("dddd d MMM").toLowerCase()
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3outlineVariant
    }

    // Read tasks from ~/.local/share/caelestia/daily-log (one per line)
    FileView {
        id: logFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/caelestia/daily-log"
    }

    Repeater {
        model: logFile.text
            ? logFile.text.split("\n").filter(l => l.trim().length > 0).slice(0, 5)
            : []

        StyledText {
            required property string modelData
            Layout.fillWidth: true
            text: `→ ${modelData}`
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !logFile.text || logFile.text.trim().length === 0
        text: qsTr("No tasks today")
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3outline
        font.italic: true
    }
}
