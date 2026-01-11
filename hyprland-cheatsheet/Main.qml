import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "KeybindParser.js" as Parser

Item {
    id: root
    property var pluginApi: null

    // Logger helper functions (fallback to console if Logger not available)
    function logDebug(msg) {
        if (typeof Logger !== 'undefined')
            Logger.d(msg);
        else
            console.log(msg);
    }

    function logInfo(msg) {
        if (typeof Logger !== 'undefined')
            Logger.i(msg);
        else
            console.log(msg);
    }

    function logWarn(msg) {
        if (typeof Logger !== 'undefined')
            Logger.w(msg);
        else
            console.warn(msg);
    }

    function logError(msg) {
        if (typeof Logger !== 'undefined')
            Logger.e(msg);
        else
            console.error(msg);
    }

    onPluginApiChanged: {
        if (pluginApi) {
            logInfo("HyprlandCheatsheet: pluginApi loaded, starting generator");
            runGenerator();
        }
    }

    Component.onCompleted: {
        if (pluginApi) {
            logDebug("HyprlandCheatsheet: Component.onCompleted, starting generator");
            runGenerator();
        }
    }

    function runGenerator() {
        logDebug("HyprlandCheatsheet: === START GENERATOR ===");

        // Get HOME from environment
        var homeDir = process.environment["HOME"];
        if (!homeDir) {
            logError("HyprlandCheatsheet: ERROR - cannot get $HOME");
            saveToDb([
                {
                    "title": pluginApi?.tr("main.error") || "ERROR",
                    "binds": [
                        {
                            "keys": "ERROR",
                            "desc": pluginApi?.tr("main.cannot_get_home") || "Cannot get $HOME"
                        }
                    ]
                }
            ]);
            return;
        }

        var cmd = "cat " + homeDir + "/.config/hypr/*.conf " + homeDir + "/.config/hypr/**/*.conf 2>/dev/null";

        logDebug("HyprlandCheatsheet: HOME = " + homeDir);
        logDebug("HyprlandCheatsheet: Full path = " + filePath);
        logDebug("HyprlandCheatsheet: Command = " + cmd);

        var proc = process.create("bash", ["-c", cmd]);

        proc.finished.connect(function () {
            logDebug("HyprlandCheatsheet: Process finished. ExitCode: " + proc.exitCode);
            logDebug("HyprlandCheatsheet: Stdout length: " + proc.stdout.length);
            logDebug("HyprlandCheatsheet: Stderr: " + proc.stderr);

            if (proc.exitCode !== 0) {
                logError("HyprlandCheatsheet: ERROR! Code: " + proc.exitCode);
                logError("HyprlandCheatsheet: Full stderr: " + proc.stderr);

                saveToDb([
                    {
                        "title": pluginApi?.tr("main.read_error") || "READ ERROR",
                        "binds": [
                            {
                                "keys": pluginApi?.tr("main.exit_code") || "EXIT CODE",
                                "desc": proc.exitCode.toString()
                            },
                            {
                                "keys": pluginApi?.tr("main.stderr") || "STDERR",
                                "desc": proc.stderr
                            }
                        ]
                    }
                ]);
                return;
            }

            var content = proc.stdout;
            logDebug("HyprlandCheatsheet: Content retrieved. Length: " + content.length);

            // Show first 200 chars
            if (content.length > 0) {
                logDebug("HyprlandCheatsheet: First 200 chars: " + content.substring(0, 200));
                parseAndSave(content);
            } else {
                logWarn("HyprlandCheatsheet: File is empty!");
                saveToDb([
                    {
                        "title": pluginApi?.tr("main.file_empty") || "FILE EMPTY",
                        "binds": [
                            {
                                "keys": "INFO",
                                "desc": pluginApi?.tr("main.file_no_data") || "File contains no data"
                            }
                        ]
                    }
                ]);
            }
        });
    }

    Process {
        id: process
        function create(cmd, args) {
            logDebug("HyprlandCheatsheet: Creating process: " + cmd + " " + args.join(" "));
            command = [cmd].concat(args);
            running = true;
            return this;
        }
    }

    function parseAndSave(text) {
        logDebug("HyprlandCheatsheet: Parsing started");
        var categories = Parser.parseKeybindConfig(text);
        logDebug("HyprlandCheatsheet: Found " + categories.length + " categories.");
        saveToDb(categories);
    }

    function saveToDb(data) {
        if (pluginApi) {
            pluginApi.pluginSettings.cheatsheetData = data;
            pluginApi.saveSettings();
            logInfo("HyprlandCheatsheet: SAVED TO DB " + data.length + " categories");
        } else {
            logError("HyprlandCheatsheet: ERROR - pluginApi is null!");
        }
    }

    IpcHandler {
        target: "plugin:hyprland-cheatsheet"
        function toggle() {
            logDebug("HyprlandCheatsheet: IPC toggle called");
            if (pluginApi) {
                runGenerator();
                pluginApi.withCurrentScreen(screen => pluginApi.openPanel(screen));
            }
        }
    }
}
