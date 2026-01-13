import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property string compositor: ""

  // Logger helper functions
  function logDebug(msg) {
    if (typeof Logger !== 'undefined') Logger.d("KeybindCheatsheet", msg);
    else console.log("[KeybindCheatsheet] " + msg);
  }

  function logInfo(msg) {
    if (typeof Logger !== 'undefined') Logger.i("KeybindCheatsheet", msg);
    else console.log("[KeybindCheatsheet] " + msg);
  }

  function logWarn(msg) {
    if (typeof Logger !== 'undefined') Logger.w("KeybindCheatsheet", msg);
    else console.warn("[KeybindCheatsheet] " + msg);
  }

  function logError(msg) {
    if (typeof Logger !== 'undefined') Logger.e("KeybindCheatsheet", msg);
    else console.error("[KeybindCheatsheet] " + msg);
  }

  onPluginApiChanged: {
    if (pluginApi) {
      logInfo("pluginApi loaded, detecting compositor");
      detectCompositor();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      logDebug("Component.onCompleted, detecting compositor");
      detectCompositor();
    }
  }

  function detectCompositor() {
    // Check environment variables to detect compositor
    var hyprlandSig = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
    var niriSocket = Quickshell.env("NIRI_SOCKET");

    if (hyprlandSig && hyprlandSig.length > 0) {
      compositor = "hyprland";
      logInfo("Detected Hyprland compositor");
    } else if (niriSocket && niriSocket.length > 0) {
      compositor = "niri";
      logInfo("Detected Niri compositor");
    } else {
      // Fallback: try to detect by checking running processes
      logWarn("No compositor detected via env vars, trying process detection");
      detectByProcess();
      return;
    }

    if (pluginApi) {
      pluginApi.pluginSettings.detectedCompositor = compositor;
      pluginApi.saveSettings();
    }
    runParser();
  }

  Process {
    id: detectProcess
    command: ["sh", "-c", "pgrep -x hyprland >/dev/null && echo hyprland || (pgrep -x niri >/dev/null && echo niri || echo unknown)"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        var detected = data.trim();
        if (detected === "hyprland" || detected === "niri") {
          root.compositor = detected;
          logInfo("Detected compositor via process: " + detected);
        } else {
          root.compositor = "unknown";
          logError("Could not detect compositor");
        }

        if (pluginApi) {
          pluginApi.pluginSettings.detectedCompositor = root.compositor;
          pluginApi.saveSettings();
        }

        if (root.compositor !== "unknown") {
          runParser();
        } else {
          saveToDb([{
            "title": "Error",
            "binds": [{ "keys": "ERROR", "desc": "No supported compositor detected (Hyprland/Niri)" }]
          }]);
        }
      }
    }
  }

  function detectByProcess() {
    detectProcess.running = true;
  }

  property string configContent: ""

  function runParser() {
    logDebug("=== START PARSER for " + compositor + " ===");

    var homeDir = Quickshell.env("HOME");
    if (!homeDir) {
      logError("Cannot get $HOME");
      saveToDb([{
        "title": "ERROR",
        "binds": [{ "keys": "ERROR", "desc": "Cannot get $HOME" }]
      }]);
      return;
    }

    var filePath;
    if (compositor === "hyprland") {
      filePath = homeDir + "/.config/hypr/keybind.conf";
    } else if (compositor === "niri") {
      filePath = homeDir + "/.config/niri/config.kdl";
    } else {
      logError("Unknown compositor: " + compositor);
      return;
    }

    logDebug("Config path = " + filePath);
    configContent = "";
    readConfigProcess.command = ["cat", filePath];
    readConfigProcess.running = true;
  }

  Process {
    id: readConfigProcess
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.configContent += data;
      }
    }

    onExited: (exitCode, exitStatus) => {
      logDebug("Process finished. ExitCode: " + exitCode);

      if (exitCode !== 0) {
        logError("Read error! Code: " + exitCode);
        saveToDb([{
          "title": "READ ERROR",
          "binds": [
            { "keys": "EXIT CODE", "desc": exitCode.toString() }
          ]
        }]);
        return;
      }

      logDebug("Content length: " + root.configContent.length);

      if (root.configContent.length > 0) {
        if (root.compositor === "hyprland") {
          parseHyprlandConfig(root.configContent);
        } else if (root.compositor === "niri") {
          parseNiriConfig(root.configContent);
        }
      } else {
        logWarn("File is empty!");
        saveToDb([{
          "title": "FILE EMPTY",
          "binds": [{ "keys": "INFO", "desc": "File contains no data" }]
        }]);
      }
    }
  }

  // ========== HYPRLAND PARSER ==========
  function parseHyprlandConfig(text) {
    logDebug("Parsing Hyprland config");
    var lines = text.split('\n');
    var categories = [];
    var currentCategory = null;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      // Category header: # 1. Category Name
      if (line.startsWith("#") && line.match(/#\s*\d+\./)) {
        if (currentCategory) {
          categories.push(currentCategory);
        }
        var title = line.replace(/#\s*\d+\.\s*/, "").trim();
        logDebug("New category: " + title);
        currentCategory = { "title": title, "binds": [] };
      }
      // Keybind: bind = $mod, T, exec, cmd #"description"
      else if (line.includes("bind") && line.includes('#"')) {
        if (currentCategory) {
          var descMatch = line.match(/#"(.*?)"$/);
          var description = descMatch ? descMatch[1] : "No description";

          var parts = line.split(',');
          if (parts.length >= 2) {
            var mod = parts[0].split('=')[1].trim().replace("$mod", "Super");
            var key = parts[1].trim().toUpperCase();
            if (parts[0].includes("SHIFT")) mod += " + Shift";
            if (parts[0].includes("CTRL")) mod += " + Ctrl";
            if (parts[0].includes("ALT")) mod += " + Alt";

            currentCategory.binds.push({
              "keys": mod + " + " + key,
              "desc": description
            });
            logDebug("Added bind: " + mod + " + " + key);
          }
        }
      }
    }

    if (currentCategory) {
      categories.push(currentCategory);
    }

    logDebug("Found " + categories.length + " categories");
    saveToDb(categories);
  }

  // ========== NIRI PARSER ==========
  function parseNiriConfig(text) {
    logDebug("Parsing Niri KDL config");
    var lines = text.split('\n');
    var inBindsBlock = false;
    var braceDepth = 0;
    var currentCategory = null;

    var actionCategories = {
      "spawn": "Applications",
      "focus-column": "Column Navigation",
      "focus-window": "Window Focus",
      "focus-workspace": "Workspace Navigation",
      "move-column": "Move Columns",
      "move-window": "Move Windows",
      "consume-window": "Window Management",
      "expel-window": "Window Management",
      "close-window": "Window Management",
      "fullscreen-window": "Window Management",
      "maximize-column": "Column Management",
      "set-column-width": "Column Width",
      "switch-preset-column-width": "Column Width",
      "reset-window-height": "Window Size",
      "screenshot": "Screenshots",
      "power-off-monitors": "Power",
      "quit": "System",
      "toggle-animation": "Animations"
    };

    var categorizedBinds = {};

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      // Find binds block
      if (line.startsWith("binds") && line.includes("{")) {
        inBindsBlock = true;
        braceDepth = 1;
        continue;
      }

      if (!inBindsBlock) continue;

      // Track brace depth
      for (var j = 0; j < line.length; j++) {
        if (line[j] === '{') braceDepth++;
        else if (line[j] === '}') braceDepth--;
      }

      if (braceDepth <= 0) {
        inBindsBlock = false;
        break;
      }

      // Comments as category hints
      if (line.startsWith("//")) {
        var commentText = line.substring(2).trim();
        if (commentText.length > 0 && commentText.length < 50) {
          currentCategory = commentText;
        }
        continue;
      }

      if (line.length === 0) continue;

      // Parse: Mod+Key { action; }
      var bindMatch = line.match(/^([A-Za-z0-9_+]+)\s*(?:[a-z\-]+=\S+\s*)*\{\s*([^}]+)\s*\}/);

      if (bindMatch) {
        var keyCombo = bindMatch[1];
        var action = bindMatch[2].trim().replace(/;$/, '');

        var formattedKeys = formatNiriKeyCombo(keyCombo);
        var category = currentCategory || getNiriCategory(action, actionCategories);

        if (!categorizedBinds[category]) {
          categorizedBinds[category] = [];
        }

        categorizedBinds[category].push({
          "keys": formattedKeys,
          "desc": formatNiriAction(action)
        });

        logDebug("Added bind: " + formattedKeys + " -> " + action);
      }
    }

    // Convert to array
    var categoryOrder = [
      "Applications", "Window Management", "Column Navigation",
      "Window Focus", "Workspace Navigation", "Move Columns",
      "Move Windows", "Column Management", "Column Width",
      "Window Size", "Screenshots", "Power", "System", "Animations"
    ];

    var categories = [];
    for (var k = 0; k < categoryOrder.length; k++) {
      var catName = categoryOrder[k];
      if (categorizedBinds[catName] && categorizedBinds[catName].length > 0) {
        categories.push({
          "title": catName,
          "binds": categorizedBinds[catName]
        });
      }
    }

    // Add remaining categories
    for (var cat in categorizedBinds) {
      if (categoryOrder.indexOf(cat) === -1 && categorizedBinds[cat].length > 0) {
        categories.push({
          "title": cat,
          "binds": categorizedBinds[cat]
        });
      }
    }

    logDebug("Found " + categories.length + " categories");
    saveToDb(categories);
  }

  function formatNiriKeyCombo(combo) {
    return combo
      .replace(/Mod\+/g, "Super + ")
      .replace(/Super\+/g, "Super + ")
      .replace(/Ctrl\+/g, "Ctrl + ")
      .replace(/Control\+/g, "Ctrl + ")
      .replace(/Alt\+/g, "Alt + ")
      .replace(/Shift\+/g, "Shift + ")
      .replace(/Win\+/g, "Super + ")
      .replace(/\+\s*$/, "")
      .replace(/\s+/g, " ");
  }

  function formatNiriAction(action) {
    if (action.startsWith("spawn")) {
      var spawnMatch = action.match(/spawn\s+"([^"]+)"/);
      if (spawnMatch) {
        return "Run: " + spawnMatch[1];
      }
      return action;
    }
    return action.replace(/-/g, ' ').replace(/\b\w/g, function(l) { return l.toUpperCase(); });
  }

  function getNiriCategory(action, actionCategories) {
    for (var prefix in actionCategories) {
      if (action.startsWith(prefix)) {
        return actionCategories[prefix];
      }
    }
    return "Other";
  }

  function saveToDb(data) {
    if (pluginApi) {
      pluginApi.pluginSettings.cheatsheetData = data;
      pluginApi.saveSettings();
      logInfo("Saved " + data.length + " categories to settings");
    } else {
      logError("pluginApi is null!");
    }
  }

  IpcHandler {
    target: "plugin:keybind-cheatsheet"
    function toggle() {
      logDebug("IPC toggle called");
      if (pluginApi) {
        if (!compositor) {
          detectCompositor();
        } else {
          runParser();
        }
        pluginApi.withCurrentScreen(screen => pluginApi.openPanel(screen));
      }
    }
  }
}
