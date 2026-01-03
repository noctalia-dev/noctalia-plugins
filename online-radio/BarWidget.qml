import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI


Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    // Свойство для иконки из настроек
    property string currentIconName: pluginApi?.pluginSettings?.currentIconName || pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName

    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight - 4

    readonly property string barPosition: Settings.data.bar.position || "top"
    readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

    color: Style.capsuleColor
    radius: Style.radiusM


    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.marginL

        NIcon {
            id: icon
            icon: root.currentIconName
            color: Color.mPrimary
        }

        NText {
            id: text
            text: "Radio"
            visible: !barIsVertical
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        cursorShape: Qt.PointingHandCursor

        onEntered: {
            root.color = Color.mHover
            text.color = Color.mOnHover
            icon.color = Color.mOnHover
        }

        onExited: {
            root.color = Style.capsuleColor
            text.color = Color.mOnSurface
            icon.color = Color.mPrimary
        }

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                pluginApi.openPanel(root.screen)
            } else if (mouse.button === Qt.RightButton) {
               
            }
        }
        
    }
}