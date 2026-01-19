import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    implicitWidth: contentRow.implicitWidth + Style.marginM * 2
    implicitHeight: Style.capsuleHeight

    color: Style.capsuleColor
    radius: Style.radiusL

    NIcon {
        id: contentRow
        anchors.centerIn: parent
        icon: "charging-pile"
        applyUiScale: false
        color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            root.color = Color.mHover
        }

        onExited: {
            root.color = Style.capsuleColor
        }

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen)
            }
        }
    }
}
