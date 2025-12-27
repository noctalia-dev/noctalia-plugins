import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  readonly property url updaterJson: Qt.resolvedUrl("file://" + Settings.configDir + "/plugins/update-count/updaterConfigs.json")
  readonly property int minutesToMillis: 60_000

  readonly property int updateIntervalMinutes: pluginApi?.pluginSettings.updateIntervalMinutes || pluginApi?.manifest?.metadata.defaultSettings?.updateIntervalMinutes || 30
  readonly property string updateTerminalCommand: pluginApi?.pluginSettings.updateTerminalCommand || pluginApi?.manifest?.metadata.defaultSettings?.updateTerminalCommand || ""

  property int updateCount: 0
  property var updater: null
  property var customUpdater: ({
    name: "custom",
    cmdGetNumUpdates:  pluginApi?.pluginSettings.customCmdGetNumUpdates || "",
    cmdDoSystemUpdate: pluginApi?.pluginSettings.customCmdDoSystemUpdate || ""
  })

  //
  // ------ Initialization ------
  //
  property var updaters: []
  property int checkIndex: 0
  property var current: null

  FileView {
    id: updaterFile
    path: root.updaterJson

    onLoaded: {
      try {
        root.updaters = JSON.parse(updaterFile.text());
        root.runAllCmdChecks();
      } catch (e) {
        Logger.e("UpdateCount", "JSON Error in", root.updaterJson, ":", e);
      }
    }
  }

  function runAllCmdChecks() {
    if (!root.updaters || root.updaters.length === 0) {
      return;
    }

    root.checkIndex = 0;
    root.checkNext();
  }

  function checkNext() {
    if (root.checkIndex >= root.updaters.length) {
      startGetNumUpdates();
      return;
    }

    root.current = root.updaters[root.checkIndex++];
    cmdCheckProc.command = ["sh", "-c", root.current.cmdCheck];
    cmdCheckProc.running = true;
  }

  Process {
    id: cmdCheckProc

    onExited: function (exitCode, exitStatus) {
      if (exitCode === 0) {
        root.updater = root.current
        Logger.i("UpdateCount", `Initialization finished. Detected updater: ${root.updater.name}.`);
        root.startGetNumUpdates()
      } else {
        root.checkNext();
      }
    }
  }

  //
  // ------ Get number of updates ------
  //
  Timer {
    id: timerGetNumUpdates

    interval: root.updateIntervalMinutes * root.minutesToMillis
    running: true
    repeat: true
    onTriggered: root.startGetNumUpdates()
  }

  function startGetNumUpdates() {
    const cmd = root.customUpdater.cmdGetNumUpdates || root.updater.cmdGetNumUpdates || "exit 1"
    getNumUpdates.command = ["sh", "-c", cmd]
    getNumUpdates.running = true;
  }

  Process {
    id: getNumUpdates

    stdout: StdioCollector {
      onStreamFinished: {
        var count = parseInt(text.trim());
        root.updateCount = isNaN(count) ? -1 : count;
        if (root.updateCount >= 0) {
          Logger.i("UpdateCount", `Updates available: ${root.updateCount}`);
        } else {
          Logger.e("UpdateCount", `getNumUpdates return '${text.trim()}' cannot be parsed into int`);
        }
      }
    }
  }

  //
  // ------ Start update ------
  //
  function startDoSystemUpdate() {
    const updateCmd = root.customUpdater.cmdDoSystemUpdate || root.updater.cmdDoSystemUpdate || "echo 'No update cmd found.'"
    const ipcCmd = "qs -c noctalia-shell ipc call plugin:update-count check"
    const combinedCmd = updateCmd + " && " + ipcCmd

    const term = root.updateTerminalCommand.trim();
    const fullCmd = (term.indexOf("{}") !== -1) ? term.replace("{}", combinedCmd) : term + " " + combinedCmd;

    doSystemUpdate.command = ["sh", "-c", fullCmd]
    doSystemUpdate.running = true;

    Logger.i("UpdateCount", `Executed update command: ${fullCmd}`);
  }

  Process {
    id: doSystemUpdate
  }

  //
  // ------ IPC ------
  //
  IpcHandler {
    target: "plugin:update-count"

    function check(): void {
      root.startGetNumUpdates()
    }

    function run(): void {
      root.startDoSystemUpdate()
    }
  }
}
