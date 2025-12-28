import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null

  property bool steamRunning: false
  property bool overlayActive: false
  property var steamWindows: []

  // Auto-detect screen resolution
  property int screenWidth: 3440  // Default, will be updated
  property int screenHeight: 1440  // Default, will be updated

  // Percentage-based layout (10% / 60% / 25% + gaps)
  property int gapSize: 10
  property int topMargin: screenHeight * 0.025  // 2.5% top
  property int windowHeight: screenHeight * 0.95  // 95% height

  property int friendsWidth: (screenWidth * 0.10) - gapSize
  property int mainWidth: (screenWidth * 0.60) - (gapSize * 2)
  property int chatWidth: (screenWidth * 0.25) - gapSize

  // Calculate center offset for horizontal centering
  property int totalWidth: friendsWidth + gapSize + mainWidth + gapSize + chatWidth
  property int centerOffset: (screenWidth - totalWidth) / 2

  onPluginApiChanged: {
    if (pluginApi) {
      console.log("SteamOverlay:", pluginApi?.tr("main.plugin_loaded"));
      checkSteam.running = true;
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      checkSteam.running = true;
    }
    detectResolution.running = true;
    monitorTimer.start();
  }

  // Check if Steam is running
  Process {
    id: checkSteam
    command: ["pidof", "steam"]
    running: false

    onExited: (exitCode, exitStatus) => {
      steamRunning = (exitCode === 0);
    }
  }

  // Launch Steam
  Process {
    id: launchSteam
    command: ["steam", "steam://open/main"]
    running: false

    onExited: (exitCode, exitStatus) => {
      console.log("SteamOverlay:", pluginApi?.tr("main.steam_launched"));
    }
  }

  // Detect screen resolution
  Process {
    id: detectResolution
    command: ["bash", "-c", "hyprctl monitors -j | jq -r '.[0] | \"\\(.width) \\(.height)\"'"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(" ");
        if (parts.length === 2) {
          screenWidth = parseInt(parts[0]);
          screenHeight = parseInt(parts[1]);
          var msg = pluginApi?.tr("main.resolution_detected")
            .replace("{width}", screenWidth)
            .replace("{height}", screenHeight);
          console.log("SteamOverlay:", msg);
        }
      }
    }
  }

  // Detect Steam windows
  Process {
    id: detectWindows
    command: ["bash", "-c", "hyprctl clients -j | jq -c '.[] | select(.class == \"steam\") | {address: .address, title: .title, x: .at[0], y: .at[1], w: .size[0], h: .size[1]}'"]
    running: false

    property var lines: []

    stdout: SplitParser {
      onRead: data => {
        detectWindows.lines.push(data.trim());
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && lines.length > 0) {
        steamWindows = lines.map(line => JSON.parse(line));
        var msg = pluginApi?.tr("main.windows_found").replace("{count}", steamWindows.length);
        console.log("SteamOverlay:", msg);
        lines = [];
      }
    }
  }

  // Move and position windows
  Process {
    id: moveWindows
    command: ["bash", "-c", ""]
    running: false

    onExited: (exitCode, exitStatus) => {
      var msg = pluginApi?.tr("main.windows_moved").replace("{code}", exitCode);
      console.log("SteamOverlay:", msg);
      if (exitCode === 0) {
        // Show the special workspace
        showWorkspace.running = true;
      }
    }
  }

  // Show special workspace
  Process {
    id: showWorkspace
    command: ["hyprctl", "dispatch", "togglespecialworkspace", "steam"]
    running: false

    onExited: (exitCode, exitStatus) => {
      console.log("SteamOverlay:", pluginApi?.tr("main.workspace_toggled"));
    }
  }

  // Timer to monitor Steam
  Timer {
    id: monitorTimer
    interval: 3000
    repeat: true
    running: false

    onTriggered: {
      checkSteam.running = true;
    }
  }

  function toggleOverlay() {
    console.log("SteamOverlay:", pluginApi?.tr("main.toggle_called"));

    if (!steamRunning) {
      console.log("SteamOverlay:", pluginApi?.tr("main.launching_steam"));
      launchSteam.running = true;
      return;
    }

    if (overlayActive) {
      // Hide overlay
      showWorkspace.running = true;
      overlayActive = false;
    } else {
      // Show overlay - detect and move windows
      detectWindows.running = true;

      // Wait for detection to complete, then move windows
      Qt.callLater(() => {
        if (steamWindows.length > 0) {
          moveWindowsToOverlay();
        } else {
          console.log("SteamOverlay:", pluginApi?.tr("main.no_windows_found"));
        }
      });

      overlayActive = true;
    }
  }

  function moveWindowsToOverlay() {
    var commands = [];

    for (var i = 0; i < steamWindows.length; i++) {
      var win = steamWindows[i];
      var addr = win.address;
      var title = win.title;

      // Move to special workspace
      commands.push("hyprctl dispatch movetoworkspacesilent special:steam,address:" + addr);

      // Position based on title with percentage layout + center offset
      var x = 0, y = topMargin, w = 800, h = windowHeight;

      if (title === "Steam") {
        // Main window: center + friends + gap
        x = centerOffset + friendsWidth + gapSize;
        w = mainWidth;
      } else if (title === "Friends List") {
        // Friends: center offset (left side)
        x = centerOffset;
        w = friendsWidth;
      } else {
        // Chat: center + friends + gap + main + gap
        x = centerOffset + friendsWidth + gapSize + mainWidth + gapSize;
        w = chatWidth;
      }

      // Set floating first, then position and size
      commands.push("hyprctl dispatch setfloating address:" + addr);
      commands.push("hyprctl dispatch resizewindowpixel exact " + w + " " + h + ",address:" + addr);
      commands.push("hyprctl dispatch movewindowpixel exact " + x + " " + y + ",address:" + addr);
    }

    if (commands.length > 0) {
      moveWindows.command = ["bash", "-c", commands.join(" && ")];
      moveWindows.running = true;
    }
  }

  // IPC Handler
  IpcHandler {
    target: "plugin:steam-overlay"

    function toggle() {
      console.log("SteamOverlay:", pluginApi?.tr("main.ipc_received"));
      root.toggleOverlay();
    }
  }
}
