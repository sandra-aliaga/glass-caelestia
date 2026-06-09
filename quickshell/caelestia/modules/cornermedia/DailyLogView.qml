import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Shows today's daily log status from the DailyLog service
ColumnLayout {
    id: root

    spacing: Appearance.spacing.small / 2

    StyledText {
        Layout.fillWidth: true
        text: Time.format("dddd d MMM").toLowerCase()
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3outlineVariant
    }

    StyledText {
        Layout.fillWidth: true
        text: DailyLog.statusText
        font.pointSize: Appearance.font.size.small
        color: DailyLog.overdue
            ? Colours.palette.m3error
            : DailyLog.pending
                ? Colours.palette.m3onSurfaceVariant
                : Colours.palette.m3primary
    }

    StyledText {
        Layout.fillWidth: true
        visible: DailyLog.didToday.length > 0
        text: `→ ${DailyLog.didToday}`
        elide: Text.ElideRight
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurfaceVariant
    }

    StyledText {
        Layout.fillWidth: true
        visible: DailyLog.blockers.length > 0
        text: `⚠ ${DailyLog.blockers}`
        elide: Text.ElideRight
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3error
    }

    StyledText {
        Layout.fillWidth: true
        visible: DailyLog.tomorrow.length > 0
        text: `↳ ${DailyLog.tomorrow}`
        elide: Text.ElideRight
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurfaceVariant
    }
}
