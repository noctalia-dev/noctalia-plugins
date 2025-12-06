import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    // SmartPanel properties
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 300 * Style.uiScaleRatio
    property real contentPreferredHeight: 300 * Style.uiScaleRatio

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.transparent

        Rectangle {
            anchors.fill: parent
            anchors.margins: Style.marginL
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.marginL

                // Big Cat
                Item {
                    id: bigCatItem
                    Layout.preferredWidth: 128 * Style.uiScaleRatio
                    Layout.preferredHeight: 128 * Style.uiScaleRatio
                    Layout.alignment: Qt.AlignHCenter

                    property int frameIndex: 0
                    property bool isRunning: true 
                    
                    readonly property bool isLightMode: (Color.mOnSurface.r * 0.299 + Color.mOnSurface.g * 0.587 + Color.mOnSurface.b * 0.114) < 0.5
                    readonly property string iconPrefix: isLightMode ? "icons/black/" : "icons/"

                    readonly property var icons: [
                        bigCatItem.iconPrefix + "my-active-0-symbolic.svg",
                        bigCatItem.iconPrefix + "my-active-1-symbolic.svg",
                        bigCatItem.iconPrefix + "my-active-2-symbolic.svg",
                        bigCatItem.iconPrefix + "my-active-3-symbolic.svg",
                        bigCatItem.iconPrefix + "my-active-4-symbolic.svg"
                    ]
                    
                    property int idleFrameIndex: 0
                    readonly property var idleIcons: [
                        bigCatItem.iconPrefix + "my-idle-0-symbolic.svg",
                        bigCatItem.iconPrefix + "my-idle-1-symbolic.svg",
                        bigCatItem.iconPrefix + "my-idle-2-symbolic.svg",
                        bigCatItem.iconPrefix + "my-idle-3-symbolic.svg"
                    ]

                    Timer {
                        interval: SystemStatService.cpuUsage > 90 ? 30 : (SystemStatService.cpuUsage > 50 ? 80 : 150)
                        running: bigCatItem.isRunning && SystemStatService.cpuUsage >= 10
                        repeat: true
                        onTriggered: bigCatItem.frameIndex = (bigCatItem.frameIndex + 1) % bigCatItem.icons.length
                    }
                    
                    Timer {
                        interval: 400
                        running: bigCatItem.isRunning && SystemStatService.cpuUsage < 10
                        repeat: true
                        onTriggered: bigCatItem.idleFrameIndex = (bigCatItem.idleFrameIndex + 1) % bigCatItem.idleIcons.length
                    }

                    Image {
                        id: bigCatImage
                        anchors.fill: parent
                        source: (bigCatItem.isRunning && SystemStatService.cpuUsage >= 10) 
                                ? Qt.resolvedUrl(bigCatItem.icons[bigCatItem.frameIndex]) 
                                : Qt.resolvedUrl(bigCatItem.idleIcons[bigCatItem.idleFrameIndex])
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: true
                    }
                }

                // CPU Stats
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "CPU: " + Math.round(SystemStatService.cpuUsage) + "%"
                    font.pointSize: Style.fontSizeXL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                }
            }
        }
    }
}
