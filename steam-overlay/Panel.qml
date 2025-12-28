import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property real contentPreferredWidth: 3440
  property real contentPreferredHeight: 1080
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: false
  readonly property bool panelAnchorHorizontalCenter: true
  readonly property bool panelAnchorTop: true
  anchors.fill: parent

  // Semi-transparent background
  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    // Top bar with status and close button
    Rectangle {
      id: topBar
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 40
      color: Color.mSurfaceVariant
      opacity: 0.95

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        spacing: Style.marginM

        NIcon {
          icon: "steam"
          pointSize: Style.fontSizeL
          color: Color.mPrimary
        }

        NText {
          text: "Steam Overlay"
          font.pointSize: Style.fontSizeM
          font.weight: Font.Bold
          color: Color.mOnSurface
        }

        Item {
          Layout.fillWidth: true
        }

        // Steam status indicator
        RowLayout {
          spacing: Style.marginS

          Rectangle {
            width: 10
            height: 10
            radius: 5
            color: steamRunning ? "#4CAF50" : "#F44336"
          }

          NText {
            text: steamRunning ? "Steam Running" : "Steam Stopped"
            font.pointSize: Style.fontSizeS
            color: Color.mOnSurface
          }
        }

        // Close button
        NButton {
          text: "Zamknij (ESC)"
          onClicked: {
            if (pluginApi) {
              pluginApi.closePanel();
            }
          }
        }
      }
    }

    // Window layout guide (semi-transparent overlays showing where windows should be)
    Row {
      anchors.top: topBar.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      spacing: 0

      // Friends List area
      Rectangle {
        width: friendsWidth
        height: parent.height
        color: "#1976D2"
        opacity: 0.1
        border.color: Color.mPrimary
        border.width: 2

        NText {
          anchors.centerIn: parent
          text: "Friends List\n" + friendsWidth + "px"
          font.pointSize: Style.fontSizeL
          color: Color.mPrimary
          horizontalAlignment: Text.AlignHCenter
          opacity: 0.5
        }
      }

      // Main Steam area
      Rectangle {
        width: mainWidth
        height: parent.height
        color: "#388E3C"
        opacity: 0.1
        border.color: Color.mSecondary
        border.width: 2

        NText {
          anchors.centerIn: parent
          text: "Main Steam\n" + mainWidth + "px"
          font.pointSize: Style.fontSizeL
          color: Color.mSecondary
          horizontalAlignment: Text.AlignHCenter
          opacity: 0.5
        }
      }

      // Chat area
      Rectangle {
        width: chatWidth
        height: parent.height
        color: "#D32F2F"
        opacity: 0.1
        border.color: Color.mTertiary
        border.width: 2

        NText {
          anchors.centerIn: parent
          text: "Steam Chat\n" + chatWidth + "px"
          font.pointSize: Style.fontSizeL
          color: Color.mTertiary
          horizontalAlignment: Text.AlignHCenter
          opacity: 0.5
        }
      }
    }
  }

  // Settings
  property bool steamRunning: false
  property int friendsWidth: pluginApi?.pluginSettings?.friendsWidth || 375
  property int mainWidth: pluginApi?.pluginSettings?.mainWidth || 2600
  property int chatWidth: pluginApi?.pluginSettings?.chatWidth || 465

  // Keyboard shortcut to close
  Keys.onEscapePressed: {
    if (pluginApi) {
      pluginApi.closePanel();
    }
  }

  Component.onCompleted: {
    forceActiveFocus();
  }
}
