import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    // --- REQUIRED PROPERTIES ---
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property var mainInstance: pluginApi?.mainInstance

    // --- SIZING (Fixed to match System Pills) ---
    // Use capsuleHeight instead of barHeight to match Battery/Clock pills
    implicitHeight: Style.capsuleHeight
    implicitWidth: contentRow.implicitWidth + (Style.marginM * 2)

    // --- STYLING ---
    color: Style.capsuleColor
    // Perfectly round pill shape
    radius: height / 2
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // --- CONTENT ---
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.marginS

        // Icon
        NIcon {
            icon: {
                var name = mainInstance?.currentDnsName || "";
                if (name === "Google") return "brand-google";
                if (name === "Cloudflare") return "cloud";
                if (name === "AdGuard") return "shield-check";
                if (name === "Quad9") return "lock";
                return "globe";
            }
            // Use 'S' size for bar icons to keep them small
            pointSize: Style.fontSizeS
            color: Color.mPrimary
        }

        // Text
        NText {
            text: mainInstance?.currentDnsName || "DNS"
            color: Color.mOnSurface
            // Use specific bar font size
            pointSize: Style.barFontSize
            font.weight: Font.Medium
        }
    }

    // --- INTERACTION ---
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
