import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  property bool micActive: false
  property bool camActive: false
  property bool scrActive: false
  property var micApps: []
  property var camApps: []
  property var scrApps: []

  readonly property color activeColor: Color.mPrimary
  readonly property color inactiveColor: Qt.alpha(Color.mOnSurfaceVariant, 0.3)
  readonly property color micColor: micActive ? activeColor : inactiveColor
  readonly property color camColor: camActive ? activeColor : inactiveColor
  readonly property color scrColor: scrActive ? activeColor : inactiveColor

  implicitWidth: isVertical ? Style.capsuleHeight : Math.round(layout.implicitWidth + Style.marginM * 2)
  implicitHeight: isVertical ? Math.round(layout.implicitHeight + Style.marginM * 2) : Style.capsuleHeight

  Layout.alignment: Qt.AlignVCenter
  radius: Style.radiusM
  color: Style.capsuleColor

  PwObjectTracker {
    objects: Pipewire.ready ? Pipewire.nodes.values : []
  }

  Process {
    id: cameraCheckProcess
    running: false
    
    command: ["sh", "-c", "for dev in /dev/video*; do [ -e \"$dev\" ] && [ -n \"$(find /proc/[0-9]*/fd/ -lname \"$dev\" 2>/dev/null | head -n1)\" ] && echo \"active\" && exit 0; done; exit 1"]
    
    onExited: (code, status) => {
      var isActive = code === 0;
      root.camActive = isActive;
      
      if (isActive) {
        cameraAppsProcess.running = true;
      } else {
        root.camApps = [];
      }
    }
  }
  
  Process {
    id: cameraAppsProcess
    running: false
    
    command: ["sh", "-c", "for dev in /dev/video*; do [ -e \"$dev\" ] && for fd in /proc/[0-9]*/fd/*; do [ -L \"$fd\" ] && [ \"$(readlink \"$fd\" 2>/dev/null)\" = \"$dev\" ] && ps -p \"$(echo \"$fd\" | cut -d/ -f3)\" -o comm= 2>/dev/null; done; done | sort -u | tr '\\n' ',' | sed 's/,$//'"]
    
    onExited: (code, status) => {
      if (stdout) {
        var appsString = stdout.trim();
        var apps = appsString.length > 0 ? appsString.split(',') : [];
        root.camApps = apps;
      } else {
        root.camApps = [];
      }
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: updatePrivacyState()
  }

  function hasNodeLinks(node, links) {
    for (var i = 0; i < links.length; i++) {
      var link = links[i];
      if (link && (link.source === node || link.target === node)) {
        return true;
      }
    }
    return false;
  }

  function getAppName(node) {
    return node.properties["application.name"] || node.nickname || node.name || "";
  }

  function updateMicrophoneState(nodes, links) {
    var appNames = [];
    var isActive = false;
    
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || !node.isStream || !node.audio || node.isSink) continue;
      if (!hasNodeLinks(node, links) || !node.properties) continue;
      
      var mediaClass = node.properties["media.class"] || "";
      if (mediaClass === "Stream/Input/Audio") {
        if (node.properties["stream.capture.sink"] === "true") {
          continue;
        }
        
        isActive = true;
        var appName = getAppName(node);
        if (appName && appNames.indexOf(appName) === -1) {
          appNames.push(appName);
        }
      }
    }
    
    root.micActive = isActive;
    root.micApps = appNames;
  }

  function updateCameraState() {
    cameraCheckProcess.running = true;
  }

  function isScreenShareNode(node) {
    if (!node.properties) {
      return false;
    }
    
    var mediaClass = node.properties["media.class"] || "";
    
    if (mediaClass.indexOf("Audio") >= 0) {
      return false;
    }
    
    if (mediaClass.indexOf("Video") === -1) {
      return false;
    }
    
    var mediaName = (node.properties["media.name"] || "").toLowerCase();
    
    if (mediaName.match(/^(xdph-streaming|gsr-default|game capture|screen|desktop|display|cast|webrtc|v4l2)/) ||
        mediaName === "gsr-default_output" ||
        mediaName.match(/screen-cast|screen-capture|desktop-capture|monitor-capture|window-capture|game-capture/i)) {
      return true;
    }
    
    return false;
  }

  function updateScreenShareState(nodes, links) {
    var appNames = [];
    var isActive = false;
    
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || !hasNodeLinks(node, links) || !node.properties) continue;
      
      if (isScreenShareNode(node)) {
        isActive = true;
        var appName = getAppName(node);
        if (appName && appNames.indexOf(appName) === -1) {
          appNames.push(appName);
        }
      }
    }
    
    root.scrActive = isActive;
    root.scrApps = appNames;
  }

  function updatePrivacyState() {
    if (!Pipewire.ready) return;
    
    var nodes = Pipewire.nodes.values || [];
    var links = Pipewire.links.values || [];
    
    updateMicrophoneState(nodes, links);
    updateCameraState();
    updateScreenShareState(nodes, links);
  }

  function buildTooltip() {
    var parts = [];
    
    if (micActive && micApps.length > 0) {
      parts.push("Mic: " + micApps.join(", "));
    }
    
    if (camActive && camApps.length > 0) {
      parts.push("Cam: " + camApps.join(", "));
    }
    
    if (scrActive && scrApps.length > 0) {
      parts.push("Screen sharing: " + scrApps.join(", "));
    }
    
    return parts.length > 0 ? parts.join("\n") : "";
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    hoverEnabled: true
    
    onEntered: {
      var tooltipText = buildTooltip();
      if (tooltipText) {
        TooltipService.show(root, tooltipText, BarService.getTooltipDirection());
      }
    }
    onExited: TooltipService.hide()
  }

  Item {
    id: layout
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter

    implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth
    implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight

    RowLayout {
      id: rowLayout
      visible: !root.isVertical
      spacing: Style.marginXS

      NIcon {
        icon: micActive ? "microphone" : "microphone-off"
        color: root.micColor
      }
      NIcon {
        icon: camActive ? "camera" : "camera-off"
        color: root.camColor
      }
      NIcon {
        icon: scrActive ? "screen-share" : "screen-share-off"
        color: root.scrColor
      }
    }

    ColumnLayout {
      id: colLayout
      visible: root.isVertical
      spacing: Style.marginXS

      NIcon {
        icon: micActive ? "microphone" : "microphone-off"
        color: root.micColor
      }
      NIcon {
        icon: camActive ? "camera" : "camera-off"
        color: root.camColor
      }
      NIcon {
        icon: scrActive ? "screen-share" : "screen-share-off"
        color: root.scrColor
      }
    }
  }
}