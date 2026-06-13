pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Group the flat event list into [{ day, label, isToday, events }]
    readonly property var grouped: {
        const byDay = {};
        const order = [];
        for (const ev of Calendar.events) {
            const d = new Date(ev.start);
            const key = Qt.formatDate(d, "yyyy-MM-dd");
            if (!byDay[key]) {
                byDay[key] = { key, date: d, events: [] };
                order.push(key);
            }
            byDay[key].events.push(ev);
        }
        const todayKey = Qt.formatDate(new Date(), "yyyy-MM-dd");
        return order.map(k => ({
            label: Qt.formatDate(byDay[k].date, "dddd d MMM"),
            isToday: k === todayKey,
            events: byDay[k].events
        }));
    }

    function timeText(ev: var): string {
        if (ev.allDay)
            return qsTr("Todo el día");
        const s = Qt.formatDateTime(new Date(ev.start), "HH:mm");
        const e = Qt.formatDateTime(new Date(ev.end), "HH:mm");
        return `${s} – ${e}`;
    }

    implicitWidth: 840
    implicitHeight: Math.max(420, layout.implicitHeight)

    Component.onCompleted: Calendar.refresh()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Agenda")
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
                font.weight: 650
            }

            StyledText {
                visible: Calendar.loading
                text: qsTr("· actualizando…")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Reload")
                type: TextButton.Text
                onClicked: Calendar.refresh()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.15)
            clip: true

            Flickable {
                id: list

                property real wheelStep: Appearance.padding.large * 5.5

                function clampContentY(value: real): real {
                    return Math.max(0, Math.min(value, Math.max(0, contentHeight - height)));
                }

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: days.implicitHeight
                clip: true

                WheelHandler {
                    target: null
                    acceptedDevices: PointerDevice.Mouse
                    onWheel: event => {
                        const delta = event.angleDelta.y !== 0 ? (-event.angleDelta.y / 120) * list.wheelStep : -event.pixelDelta.y;
                        if (delta === 0)
                            return;
                        list.contentY = list.clampContentY(list.contentY + delta);
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: days

                    width: list.width
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: root.grouped

                        delegate: ColumnLayout {
                            id: dayGroup

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Appearance.spacing.smaller

                            StyledText {
                                text: dayGroup.modelData.label
                                color: dayGroup.modelData.isToday ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.small
                                font.weight: 600
                                font.capitalization: Font.Capitalize
                            }

                            Repeater {
                                model: dayGroup.modelData.events

                                delegate: StyledRect {
                                    id: evRow

                                    required property var modelData

                                    Layout.fillWidth: true
                                    implicitHeight: evCol.implicitHeight + Appearance.padding.normal * 2

                                    radius: Appearance.rounding.normal
                                    color: Colours.tPalette.m3surfaceContainerLow
                                    border.width: 1
                                    border.color: Qt.alpha(Colours.palette.m3outline, 0.12)

                                    RowLayout {
                                        id: evCol

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Appearance.padding.normal
                                        anchors.rightMargin: Appearance.padding.normal
                                        spacing: Appearance.spacing.normal

                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: 3
                                            implicitHeight: 28
                                            radius: 2
                                            color: Colours.palette.m3primary
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: evRow.modelData.summary
                                                color: Colours.palette.m3onSurface
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                visible: evRow.modelData.location.length > 0
                                                text: evRow.modelData.location
                                                color: Colours.palette.m3outline
                                                font.pointSize: Appearance.font.size.smaller
                                                elide: Text.ElideRight
                                            }
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: root.timeText(evRow.modelData)
                                            color: Colours.palette.m3onSurfaceVariant
                                            font.family: Appearance.font.family.mono
                                            font.pointSize: Appearance.font.size.small
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty / error / unconfigured states
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.padding.large
                        visible: root.grouped.length === 0
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: Calendar.configured ? "event_available" : "link_off"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.extraLarge
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            color: Colours.palette.m3onSurfaceVariant
                            text: {
                                if (!Calendar.configured)
                                    return qsTr("Definí CAELESTIA_CALENDAR_URL en el archivo .env\n(raíz del repo) con tu URL secreta iCal de Google Calendar.");
                                if (Calendar.error.length > 0)
                                    return qsTr("Error: %1").arg(Calendar.error);
                                return qsTr("No hay eventos en los próximos días.");
                            }
                        }
                    }
                }
            }
        }
    }
}
