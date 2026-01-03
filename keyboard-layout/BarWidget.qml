import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.Keyboard

Rectangle {
    id: root

    property string currentLayout: KeyboardLayoutService ? KeyboardLayoutService.currentLayout : "??"
    property bool capsLockOn: LockKeysService ? LockKeysService.capsLockOn : false
    
    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight - 6

    property string displayText: {
      if (!currentLayout || currentLayout === "system.unknown-layout") {
        return "??";
      }
      return currentLayout.substring(0, 2).toUpperCase();
    }

    color: capsLockOn ? Color.mHover : Color.mSurfaceVariant
    radius: 4


    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.marginL


        NText {
            id: text
            text: displayText
            color: capsLockOn ? Color.mOnHover : Color.mOnSurface
            pointSize: Style.fontSizeS
        }
    }

    Connections {
      target: KeyboardLayoutService
      function onCurrentLayoutChanged() {
        Logger.d("KeyboardLayoutWidget",displayText)
      }
    }
    
    Connections {
      target: LockKeysService
      function onCapsLockChanged(active) {
        Logger.d("KeyboardLayoutWidget",capsLockOn)
      }
    }
}