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
    property string widgetId: ""
    property string section: ""

    readonly property var mainInstance: pluginApi?.mainInstance

    implicitHeight: Style.capsuleHeight
    implicitWidth: contentRow.implicitWidth + (Style.marginM * 2)

    color: Style.capsuleColor
    radius: height / 2
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
            icon: {
                var name = mainInstance?.currentDnsName || "";
                if (name === "Google") return "brand-google";
                if (name === "Cloudflare") return "cloud";
                if (name === "AdGuard") return "shield-check";
                if (name === "Quad9") return "lock";
                return "globe";
            }
            pointSize: Style.fontSizeS
            color: Color.mPrimary
        }

        NText {
            // TRANSLATION: Short Title
            text: mainInstance?.currentDnsName || pluginApi?.tr("plugin.short_title") || "DNS"
            color: Color.mOnSurface
            pointSize: Style.barFontSize
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.color = Qt.lighter(Style.capsuleColor, 1.1)
        onExited: root.color = Style.capsuleColor

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen, root)
            }
        }
    }
}
