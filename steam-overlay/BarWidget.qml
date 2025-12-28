import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  implicitWidth: barIsVertical ? Style.capsuleHeight : contentRow.implicitWidth + Style.marginM * 2
  implicitHeight: Style.capsuleHeight

  property bool hasNewMessages: pluginApi?.pluginSettings?.hasNewMessages || false
  property bool steamRunning: false

  readonly property string barPosition: Settings.data.bar.position || "top"
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

  color: Style.capsuleColor
  radius: Style.radiusL

  // Process to check Steam status
  Process {
    id: checkSteamProcess
    command: ["pidof", "steam"]
    running: false

    onExited: (exitCode, exitStatus) => {
      steamRunning = (exitCode === 0);
    }
  }

  // Update steam status periodically
  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: {
      checkSteamProcess.running = true;
    }
  }

  Component.onCompleted: {
    checkSteamProcess.running = true;
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS

    Item {
      implicitWidth: 24
      implicitHeight: 24

      // Steam icon - using stacked rectangles to create Steam-like logo
      Item {
        id: steamIcon
        anchors.centerIn: parent
        width: 20
        height: 20

        // Simple Steam-inspired icon using rectangles
        Rectangle {
          anchors.centerIn: parent
          width: 20
          height: 20
          color: "transparent"
          border.color: steamRunning ? Color.mPrimary : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
          border.width: 2
          radius: 10

          // Inner circles for Steam logo effect
          Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -4
            anchors.verticalCenterOffset: 2
            width: 6
            height: 6
            radius: 3
            color: steamRunning ? Color.mPrimary : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
          }

          Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 4
            anchors.verticalCenterOffset: 2
            width: 4
            height: 4
            radius: 2
            color: steamRunning ? Color.mPrimary : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
          }

          Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4
            width: 8
            height: 8
            radius: 4
            color: steamRunning ? Color.mPrimary : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
          }
        }

        // Notification dot
        Rectangle {
          visible: hasNewMessages
          anchors.top: parent.top
          anchors.right: parent.right
          width: 8
          height: 8
          radius: 4
          color: "#F44336"
          border.color: Color.mSurface
          border.width: 1

          SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: hasNewMessages

            NumberAnimation {
              from: 1.0
              to: 0.3
              duration: 800
              easing.type: Easing.InOutQuad
            }
            NumberAnimation {
              from: 0.3
              to: 1.0
              duration: 800
              easing.type: Easing.InOutQuad
            }
          }
        }
      }
    }

  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      root.color = Color.mHover;
    }

    onExited: {
      root.color = Style.capsuleColor;
    }

    onClicked: {
      if (pluginApi) {
        console.log("BarWidget: Calling Steam overlay toggle");
        // Use direct IPC call
        var ipc = Qt.createQmlObject('
          import Quickshell.Io
          Process {
            command: ["qs", "ipc", "-c", "noctalia-shell", "call", "plugin:steam-overlay", "toggle"]
            running: true
          }
        ', root, "ipcProcess");
      }
    }
  }
}
