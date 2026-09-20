import qs.utils
import Quickshell
import QtQuick

Image {
    id: root

    property string path

    source: path ? (path.startsWith("file://") ? path : "file://" + path) : ""
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
}
