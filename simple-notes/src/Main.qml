/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import Quickshell.Io

import qs.Commons

Item {
    id: root

    property var pluginApi: null
    readonly property string pluginId: pluginApi?.pluginId ?? "noctalia-supergfxctl"
    property bool debug: pluginApi?.pluginSettings?.debug || pluginApi?.manifest?.metadata?.defaultSettings?.debug || false

    enum SGFXMode {
        Integrated,
        Hybrid,
        AsusMuxDgpu,
        NvidiaNoModeset,
        Vfio,
        AsusEgpu,
        None
    }

    enum SGFXPower {
        Active,
        Suspended,
        Off,
        DgpuDisabled,
        AsusMuxDiscreet,
        Unknown
    }

    enum SGFXAction {
        Logout,
        Reboot,
        SwitchToIntegrated,
        AsusEgpuDisable,
        Nothing
    }

    readonly property bool available: d.available
    readonly property string version: d.version

    readonly property int mode: d.mode
    readonly property list<int> supportedModes: d.supportedModes

    readonly property int power: d.power

    readonly property int pendingAction: d.pendingAction
    readonly property bool hasPendingAction: d.pendingAction !== Main.SGFXAction.Nothing
    readonly property int pendingMode: d.pendingMode

    Component.onCompleted: refresh()

    function setMode(mode) {
        if (d.mode === mode)
            return;

        const entry = d.modeByEnum[mode];
        if (!entry) {
            error("Invalid mode passed:", mode);
            return;
        }

        setModeProc.command = ["supergfxctl", "--mode", entry.key];
        setModeProc.running = true;

        log("setting mode:", mode);

        // TODO: get rid of once I understand why supergfxctl is so unreliable after mode switch
        d.pendingMode = mode;
    }

    function refresh() {
        log("querying supergfxctl...");
        refreshProc.command = ["supergfxctl", "--version", "--get", "--supported", "--status", "--pend-action", "--pend-mode"];
        refreshProc.running = true;
    }

    function modeInfo(modeEnum) {
        return d.modeByEnum[modeEnum] ?? d.modeByEnum[Main.SGFXMode.None];
    }

    function powerInfo(powerEnum) {
        return d.powerByEnum[powerEnum] ?? d.powerByEnum[Main.SGFXPower.Unknown];
    }

    function actionInfo(actionEnum) {
        return d.actionByEnum[actionEnum] ?? d.actionByEnum[Main.SGFXAction.Nothing];
    }

    function log(...msg) {
        if (debug)
            Logger.i(root.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    function warn(...msg) {
        if (debug)
            Logger.w(root.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    function error(...msg) {
        if (debug)
            Logger.e(root.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    QtObject {
        id: d

        property bool available: false
        property string version: "???"
        property int mode: Main.SGFXMode.None
        property int power: Main.SGFXPower.Unknown
        property int pendingAction: Main.SGFXAction.Nothing
        property int pendingMode: Main.SGFXMode.None
        property list<int> supportedModes: []

        readonly property var modeByEnum: ({
                [Main.SGFXMode.Hybrid]: {
                    enumValue: Main.SGFXMode.Hybrid,
                    cmd: "Hybrid",
                    label: pluginApi.tr("mode.Hybrid"),
                    icon: "chart-circles",
                    description: "Both GPUs active"
                },
                [Main.SGFXMode.Integrated]: {
                    enumValue: Main.SGFXMode.Integrated,
                    cmd: "Integrated",
                    label: pluginApi.tr("mode.Integrated"),
                    icon: "cpu",
                    description: "iGPU only"
                },
                [Main.SGFXMode.NvidiaNoModeset]: {
                    enumValue: Main.SGFXMode.NvidiaNoModeset,
                    cmd: "NvidiaNoModeset",
                    label: pluginApi.tr("mode.NvidiaNoModeset"),
                    icon: "cpu-off",
                    description: "Nvidia without modesetting"
                },
                [Main.SGFXMode.Vfio]: {
                    enumValue: Main.SGFXMode.Vfio,
                    cmd: "Vfio",
                    label: pluginApi.tr("mode.Vfio"),
                    icon: "device-desktop-up",
                    description: "GPU passthrough"
                },
                [Main.SGFXMode.AsusEgpu]: {
                    enumValue: Main.SGFXMode.AsusEgpu,
                    cmd: "AsusEgpu",
                    label: pluginApi.tr("mode.AsusEgpu"),
                    icon: "external-link",
                    description: "External GPU"
                },
                [Main.SGFXMode.AsusMuxDgpu]: {
                    enumValue: Main.SGFXMode.AsusMuxDgpu,
                    cmd: "AsusMuxDgpu",
                    label: pluginApi.tr("mode.AsusMuxDgpu"),
                    icon: "gauge",
                    description: "Direct dGPU via MUX"
                },
                [Main.SGFXMode.None]: {
                    enumValue: Main.SGFXMode.None,
                    cmd: "None",
                    label: pluginApi.tr("unknown"),
                    icon: "question-mark",
                    description: "Unknown mode"
                }
            })

        readonly property var modeByCMD: {
            let m = {};
            for (const e in modeByEnum) {
                m[modeByEnum[e].cmd] = parseInt(e);
            }
            return m;
        }

        function findMode(cmd) {
            return modeByCMD[cmd] ?? Main.SGFXMode.None;
        }

        readonly property var powerByEnum: ({
                [Main.SGFXPower.Active]: {
                    enumValue: Main.SGFXPower.Active,
                    cmd: "active",
                    label: "Active",
                    icon: "power"
                },
                [Main.SGFXPower.Suspended]: {
                    enumValue: Main.SGFXPower.Suspended,
                    cmd: "suspended",
                    label: "Suspended",
                    icon: "zzz"
                },
                [Main.SGFXPower.Off]: {
                    enumValue: Main.SGFXPower.Off,
                    cmd: "off",
                    label: "Off",
                    icon: "power-off"
                },
                [Main.SGFXPower.DgpuDisabled]: {
                    enumValue: Main.SGFXPower.DgpuDisabled,
                    cmd: "dgpu_disabled",
                    label: "ASUS Disabled",
                    icon: "plug-off"
                },
                [Main.SGFXPower.AsusMuxDiscreet]: {
                    enumValue: Main.SGFXPower.AsusMuxDiscreet,
                    cmd: "asus_mux_discreet",
                    label: "ASUS MUX Discreet",
                    icon: "gauge"
                },
                [Main.SGFXPower.Unknown]: {
                    enumValue: Main.SGFXPower.Unknown,
                    cmd: "unknown",
                    label: pluginApi.tr("unknown"),
                    icon: "question-mark"
                }
            })

        readonly property var powerByCMD: {
            let m = {};
            for (const e in powerByEnum) {
                m[powerByEnum[e].cmd] = parseInt(e);
            }
            return m;
        }

        function findPower(cmd) {
            return powerByCMD[cmd] ?? Main.SGFXPower.Unknown;
        }

        readonly property var actionByEnum: ({
                [Main.SGFXAction.Nothing]: {
                    enumValue: Main.SGFXAction.Nothing,
                    cmd: "No action required",
                    label: "",
                    icon: "circle-check"
                },
                [Main.SGFXAction.Logout]: {
                    enumValue: Main.SGFXAction.Logout,
                    cmd: "Logout required to complete mode change",
                    label: I18n.tr("session-menu.logout") + " " + pluginApi.tr("action.required"),
                    icon: "logout"
                },
                [Main.SGFXAction.Reboot]: {
                    enumValue: Main.SGFXAction.Reboot,
                    cmd: "Reboot required to complete mode change",
                    label: I18n.tr("session-menu.reboot") + " " + pluginApi.tr("action.required"),
                    icon: "rotate-clockwise"
                },
                [Main.SGFXAction.SwitchToIntegrated]: {
                    enumValue: Main.SGFXAction.SwitchToIntegrated,
                    cmd: "You must switch to Integrated first",
                    label: pluginApi.tr("action.switch"),
                    icon: "cpu"
                },
                [Main.SGFXAction.AsusEgpuDisable]: {
                    enumValue: Main.SGFXAction.AsusEgpuDisable,
                    cmd: "The mode must be switched to Integrated or Hybrid first",
                    label: pluginApi.tr("action.disable_egpu"),
                    icon: "external-link-off"
                }
            })

        readonly property var actionByCMD: {
            let m = {};
            for (const e in actionByEnum) {
                m[actionByEnum[e].cmd] = parseInt(e);
            }
            return m;
        }

        function findAction(cmd) {
            return actionByCMD[cmd] ?? Main.SGFXAction.Nothing;
        }

        function isVersionGreater(a, b) {
            return a.localeCompare(b, undefined, {
                numeric: true
            }) > 0;
        }

        function parseOutput(text, flags) {
            const lines = text.trim().split("\n");
            let index = 0;

            function readLine() {
                if (index >= lines.length) {
                    root.warn("expected", flags.length, "got", lines.length, "while parsing output");
                    return "";
                }
                return lines[index++].trim();
            }

            const handlers = {
                "--version": () => {
                    d.version = readLine();
                    d.available = true;
                },
                "--get": () => {
                    d.mode = d.findMode(readLine());
                },
                "--supported": () => {
                    const raw = readLine();
                    const body = raw.substring(1, raw.length - 1);
                    const items = body.length ? body.split(",") : [];

                    let result = [];
                    for (let s of items) {
                        const e = d.findMode(s.trim());
                        if (e !== undefined) {
                            result.push(e);
                        }
                    }

                    // compatibility bug fix
                    // https://gitlab.com/asus-linux/supergfxctl/-/merge_requests/44
                    if (!d.isVersionGreater(d.version, "5.2.7") && result.length === 1 && result[0] === Main.SGFXMode.AsusMuxDgpu) {
                        root.warn("fixing supergfxctl bug [merge request #44]: adding missing Integrated and Hybrid modes");
                        result.push(Main.SGFXMode.Integrated, Main.SGFXMode.Hybrid);
                    }

                    d.supportedModes = result;
                },
                "--status": () => {
                    d.power = d.findPower(readLine());
                },

                // pending action is unreliable after mode switch per
                // https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361
                "--pend-action": () => {
                    if (d.pendingAction === Main.SGFXAction.Nothing) {
                        d.pendingAction = d.findAction(readLine());
                    }
                },

                // pending mode is unreliable after mode switch per
                // https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361
                "--pend-mode": () => {
                    if (d.pendingMode === Main.SGFXMode.None) {
                        d.pendingMode = d.findMode(readLine());
                    }
                }
            };

            for (const flag of flags) {
                const fn = handlers[flag];
                if (fn) {
                    fn();
                } else {
                    root.warn("Unknown flag:", flag);
                }
            }

            root.log("parsed:", JSON.stringify({
                version: d.version,
                mode: d.mode,
                supported: d.supportedModes,
                power: d.power,
                pendingAction: d.pendingAction,
                pendingMode: d.pendingMode
            }));
        }

        // based on https://gitlab.com/asus-linux/supergfxctl/-/blob/main/src/actions.rs?ref_type=heads#L48
        // TODO: get rid of once I understand why supergfxctl is so unreliable after mode switch
        function determineRequiredAction(newMode, currentMode) {
            switch (newMode) {
            case Main.SGFXMode.Hybrid:
                switch (currentMode) {
                case Main.SGFXMode.Integrated:
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                case Main.SGFXMode.Vfio:
                    return Main.SGFXAction.SwitchToIntegrated;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.Integrated:
                switch (currentMode) {
                case Main.SGFXMode.Hybrid:
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.NvidiaNoModeset:
                switch (currentMode) {
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.Vfio:
                switch (currentMode) {
                case Main.SGFXMode.AsusEgpu:
                case Main.SGFXMode.Hybrid:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.AsusEgpu:
                switch (currentMode) {
                case Main.SGFXMode.Integrated:
                case Main.SGFXMode.Hybrid:
                case Main.SGFXMode.NvidiaNoModeset:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.Vfio:
                    return Main.SGFXAction.SwitchToIntegrated;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.AsusMuxDgpu:
                return Main.SGFXAction.Reboot;
            default:
                return Main.SGFXAction.Nothing;
            }
        }
    }

    Process {
        id: refreshProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                d.parseOutput(text, refreshProc.command.slice(1));
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.error("failed to refresh status");
            }
        }
    }

    Process {
        id: setModeProc
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                root.error(text);
            }
        }

        onExited: exitCode => {
            root.refresh();

            if (exitCode !== 0) {
                root.error("failed to set mode, supergfxctl exited with code", exitCode);
                // TODO: get rid of once I understand why supergfxctl is so unreliable after mode switch
                d.pendingMode = Main.SGFXMode.None;
                return;
            }

            // TODO: get rid of once I understand why supergfxctl is so unreliable after mode switch
            d.pendingAction = d.determineRequiredAction(d.pendingMode, d.mode);
        }
    }
}
