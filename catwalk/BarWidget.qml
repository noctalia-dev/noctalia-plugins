import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets
import qs.Services.System

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property real baseSize: Style.capsuleHeight
    property url currentIconSource

    property string tooltipText: {
        if (!pluginApi) return "";
        return root.isRunning ? (pluginApi.tr("tooltip.running") || "Running") : (pluginApi.tr("tooltip.sleeping") || "Sleeping");
    }

    property string tooltipDirection: BarService.getTooltipDirection()
    property bool enabled: true
    property bool allowClickWhenDisabled: false
    property bool hovering: false

    property color colorBg: Color.mSurfaceVariant
    property color colorFg: Color.mPrimary
    property color colorBgHover: Color.mHover
    property color colorFgHover: Color.mOnHover
    property color colorBorder: Color.mOutline
    property color colorBorderHover: Color.mOutline
    property real customRadius: Style.radiusL

    signal entered
    signal exited
    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(int angleDelta)

    implicitWidth: Math.round(baseSize + Style.marginS * 2)
    implicitHeight: Math.round(baseSize)

    opacity: root.enabled ? Style.opacityFull : Style.opacityMedium
    color: Style.capsuleColor
    radius: Math.min((customRadius >= 0 ? customRadius : Style.iRadiusL), width / 2)
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color {
        ColorAnimation {
            duration: Style.animationNormal
            easing.type: Easing.InOutQuad
        }
    }

    // --- Catwalk Specific Logic ---
    property int frameIndex: 0
    property int idleFrameIndex: 0
    readonly property bool isRunning: root.pluginApi?.mainInstance?.isRunning ?? false  
    readonly property var icons: root.pluginApi?.mainInstance?.icons || []
    readonly property var idleIcons: root.pluginApi?.mainInstance?.idleIcons || []
    readonly property real cpuUsage: root.pluginApi?.mainInstance?.cpuUsage ?? 0
    
    function openPanel() {
        if (pluginApi) {
            var result = pluginApi.openPanel(root.screen);
            Logger.i("Catwalk", "OpenPanel result:", result);
        } else {
            Logger.e("Catwalk", "PluginAPI is null");
        }
    }
    
    function openExternalMonitor() {
      Quickshell.execDetached(["sh", "-c", Settings.data.systemMonitor.externalMonitor]);
    }

    Timer {
        interval: Math.max(30, 200 - root.cpuUsage * 1.7)
        running: root.isRunning
        repeat: true
        onTriggered: {
            root.frameIndex = (root.frameIndex + 1) % root.icons.length
        }
    }
    
    Timer {
        interval: 400
        running: !root.isRunning
        repeat: true
        onTriggered: {
            root.idleFrameIndex = (root.idleFrameIndex + 1) % root.idleIcons.length
        }
    }

    currentIconSource: (root.icons && root.icons.length > 0 && root.idleIcons && root.idleIcons.length > 0)
                       ? (root.isRunning
                           ? Qt.resolvedUrl(root.icons[root.frameIndex % root.icons.length])
                           : Qt.resolvedUrl(root.idleIcons[root.idleFrameIndex % root.idleIcons.length]))
                       : ""


    Image {
        id: iconImage
        source: root.currentIconSource
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -3
        anchors.verticalCenterOffset: -1
        
        width: root.width - Style.marginS * 2
        height: width
        
        // Ensures the SVG renders sharply at any size
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true 

        // This enables the "mask" behavior to recolor the icon
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: Settings.data.colorSchemes.darkMode ? "white" : "black"
        }
    }
    

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onEntered: {
            root.hovering = true;
            if (root.tooltipText) {
                TooltipService.show(root, root.tooltipText, root.tooltipDirection);
            }
            root.entered();
        }
        onExited: {
            root.hovering = false;
            if (root.tooltipText) {
                TooltipService.hide();
            }
            root.exited();
        }
        onClicked: function (mouse) {
            if (root.tooltipText) {
                TooltipService.hide();
            }
            
            Logger.i("Catwalk", "Clicked! API:", !!pluginApi, "Screen:", root.screen ? root.screen.name : "null");

            
            if (!root.enabled && !root.allowClickWhenDisabled) {
                return;
            }
            // Open Panel on left/right click
            // Open external monitor on middle click
            if (mouse.button === Qt.LeftButton) {
                root.openPanel();
                root.clicked();
            } else if (mouse.button === Qt.RightButton) {
                root.openPanel();
                root.rightClicked();
            } else if (mouse.button === Qt.MiddleButton) {
                root.openExternalMonitor();
                root.middleClicked();
            }
        }
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}
