pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import Quickshell.Services.SystemTray
import QtQuick

Row {
    id: root

    spacing: Appearance.spacing.small / 2
    visible: items.count > 0

    Repeater {
        id: items
        model: SystemTray.items

        delegate: Item {
            required property SystemTrayItem modelData

            width: 18
            height: 18

            CachingIconImage {
                anchors.fill: parent
                source: parent.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (event.button === Qt.LeftButton)
                        parent.modelData.activate()
                    else
                        parent.modelData.secondaryActivate()
                }
            }
        }
    }
}
