import "cards"
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var props
    required property var visibilities
    required property Item popouts
    property bool recordingVisible: visible

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        IdleInhibit {}

        Record {
            observerActive: root.recordingVisible
            props: root.props
            visibilities: root.visibilities
            z: 1
        }

        Toggles {
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }

    RecordingDeleteModal {
        props: root.props
    }
}
