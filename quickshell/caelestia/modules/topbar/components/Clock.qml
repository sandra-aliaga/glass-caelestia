import qs.services
import qs.components
import qs.config
import QtQuick

// Time in primary accent + short date in muted tone
Row {
    spacing: Appearance.spacing.normal

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "HH:mm")
        font.pointSize: Appearance.font.size.normal
        font.family: Appearance.font.family.mono
        font.weight: 600
        color: Colours.palette.m3primary
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.format("ddd d MMM")
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurfaceVariant
    }
}
