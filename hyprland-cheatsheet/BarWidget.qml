import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
  id: root
  property var pluginApi: null
  property ShellScreen screen

  implicitWidth: Style.barHeight
  implicitHeight: Style.barHeight
  color: "transparent"
  radius: width * 0.5

  NIcon {
    anchors.centerIn: parent
    icon: "keyboard" 
    applyUiScale: false
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.color = Qt.rgba(1, 1, 1, 0.1)
    onExited: root.color = "transparent"
    onClicked: if (pluginApi) pluginApi.openPanel(root.screen)
  }
}
