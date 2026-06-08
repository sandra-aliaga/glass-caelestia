import qs.services
import qs.components
import qs.config
import QtQuick

StyledText {
    text: Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "HH:mm")
    font.pointSize: Appearance.font.size.smaller
    font.family: Appearance.font.family.mono
    color: Colours.palette.m3onSurface
}
