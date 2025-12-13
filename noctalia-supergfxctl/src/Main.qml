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

    enum SGFXMode {
        Integrated,
        Hybrid,
        AsusMuxDgpu,
        NvidiaNoModeset,
        Vfio,
        AsusEgpu,
        None
    }

    enum SGFXAction {
        Logout,
        Reboot,
        SwitchToIntegrated,
        AsusEgpuDisable,
        Nothing
    }

    readonly property bool debug: !!(pluginApi?.pluginSettings?.debug)

    readonly property bool available: sgfx.available
    readonly property bool busy: setModeProc.running || refreshProc.running

    readonly property string version: sgfx.version
    readonly property int mode: sgfx.mode
    readonly property int pendingAction: sgfx.pendingAction
    readonly property bool hasPendingAction: sgfx.pendingAction !== Main.SGFXAction.Nothing
    readonly property int pendingMode: sgfx.pendingMode

    Component.onCompleted: {
        refresh();
    }

    function isModeSupported(mode: int): bool {
        return (sgfx.supportedModesMask & (1 << mode)) !== 0;
    }

    function getModeIcon(mode: int): string {
        switch (mode) {
        case Main.SGFXMode.Integrated:
            return "cpu";
        case Main.SGFXMode.Hybrid:
            return "chart-circles";
        case Main.SGFXMode.AsusMuxDgpu:
            return "gauge";
        case Main.SGFXMode.NvidiaNoModeset:
            return "cpu-off";
        case Main.SGFXMode.Vfio:
            return "device-desktop-up";
        case Main.SGFXMode.AsusEgpu:
            return "external-link";
        default:
            return "question-mark";
        }
    }

    function getModeLabel(mode: int): string {
        switch (mode) {
        case Main.SGFXMode.Integrated:
            return root.pluginApi.tr("mode.Integrated");
        case Main.SGFXMode.Hybrid:
            return root.pluginApi.tr("mode.Hybrid");
        case Main.SGFXMode.AsusMuxDgpu:
            return root.pluginApi.tr("mode.AsusMuxDgpu");
        case Main.SGFXMode.NvidiaNoModeset:
            return root.pluginApi.tr("mode.NvidiaNoModeset");
        case Main.SGFXMode.Vfio:
            return root.pluginApi.tr("mode.Vfio");
        case Main.SGFXMode.AsusEgpu:
            return root.pluginApi.tr("mode.AsusEgpu");
        default:
            return root.pluginApi.tr("unknown");
        }
    }

    function getActionIcon(action: int): string {
        switch (action) {
        case Main.SGFXAction.Logout:
            return "logout";
        case Main.SGFXAction.Reboot:
            return "reload";
        case Main.SGFXAction.SwitchToIntegrated:
            return "cpu";
        case Main.SGFXAction.AsusEgpuDisable:
            return "external-link-off";
        case Main.SGFXAction.Nothing:
        default:
            return "check";
        }
    }

    function getActionLabel(action: int): string {
        switch (action) {
        case Main.SGFXAction.Logout:
            return I18n.tr("session-menu.logout");
        case Main.SGFXAction.Reboot:
            return I18n.tr("session-menu.reboot");
        case Main.SGFXAction.SwitchToIntegrated:
            return root.pluginApi.tr("action.SwitchToIntegrated") + " " + root.pluginApi.tr("action.required");
        case Main.SGFXAction.AsusEgpuDisable:
            return root.pluginApi.tr("action.AsusEgpuDisable") + " " + root.pluginApi.tr("action.required");
        case Main.SGFXAction.Nothing:
        default:
            return "";
        }
    }

    function refresh(): void {
        sgfx.refresh();
    }

    function setMode(mode: int): bool {
        return sgfx.setMode(mode);
    }

    function log(...msg) {
        if (debug) {
            Logger.i(root.pluginId, "(supergfxctl v" + sgfx.version + "):", ...msg);
        }
    }

    function warn(...msg) {
        if (debug) {
            Logger.w(root.pluginId, "(supergfxctl v" + sgfx.version + "):", ...msg);
        }
    }

    function error(...msg) {
        if (debug) {
            Logger.e(root.pluginId, "(supergfxctl v" + sgfx.version + "):", ...msg);
        }
    }

    Process {
        id: refreshProc
        running: false
        command: ["supergfxctl", "--version", "--get", "--supported", "--pend-action", "--pend-mode"]
        stdout: StdioCollector {
            onStreamFinished: sgfx.parseOutput(text.trim())
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                sgfx.available = false;
            }
        }
    }

    Process {
        id: setModeProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (root.debug && text) {
                    root.error(text);
                }
            }
        }
        onExited: exitCode => {
            // pending mode has been et manually in sgfx.setMode
            if (exitCode === 0) {
                sgfx.pendingAction = sgfx.requiredAction(sgfx.pendingMode, sgfx.mode);
            } else {
                sgfx.pendingMode = Main.SGFXMode.None;
            }

            // per asusctl/rog-control-center, supergfxctl output after mode switch is unreliable
            // (see https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361)
            //
            // it is unclear whether thats actually true, since per supergfxctl readme
            // (see https://gitlab.com/asus-linux/supergfxctl)
            // 			If rebootless switch fails: you may need the following:
            // 			sudo sed -i 's/#KillUserProcesses=no/KillUserProcesses=yes/' /etc/systemd/logind.conf
            // as well as
            // 			Switch GPU modes
            // 			Switching to/from Hybrid mode requires a logout only. (no reboot)
            // 			Switching between integrated/vfio is instant. (no logout or reboot)
            //
            // after some testing on my machine, both seem to be incorrect:
            // integrated <-> hybrid: reboot
            // integrated -> dgpu: just works
            // dgpu <- integrated: reboot      // !!!!
            // hybrid <-> dgpu: logout
            //
            // which is close to the *supposed* supergfxctl behaviour
            // BUT IT IS NOT
            // supergfxctl --pend-mode --pend-action reports absolute ****** nonsense
            sgfx.refresh();
        }
    }

    QtObject {
        id: sgfx

        property bool available: false
        property string version: "???"
        property int mode: Main.SGFXMode.None
        property int pendingAction: Main.SGFXAction.Nothing
        property int pendingMode: Main.SGFXMode.None
        property int supportedModesMask: 0

        function isValidMode(v: int): bool {
            return modeEnumReversed.hasOwnProperty(v);
        }

        readonly property var modeEnum: ({
                "Integrated": Main.SGFXMode.Integrated,
                "Hybrid": Main.SGFXMode.Hybrid,
                "AsusMuxDgpu": Main.SGFXMode.AsusMuxDgpu,
                "NvidiaNoModeset": Main.SGFXMode.NvidiaNoModeset,
                "Vfio": Main.SGFXMode.Vfio,
                "AsusEgpu": Main.SGFXMode.AsusEgpu,
                "None": Main.SGFXMode.None
            })

        readonly property var modeEnumReversed: Object.entries(modeEnum).reduce((obj, item) => (obj[item[1]] = item[0]) && obj, {})

        readonly property var actionEnum: ({
                "Logout required to complete mode change": Main.SGFXAction.Logout,
                "Reboot required to complete mode change": Main.SGFXAction.Reboot,
                "You must switch to Integrated first": Main.SGFXAction.SwitchToIntegrated,
                "The mode must be switched to Integrated or Hybrid first": Main.SGFXAction.AsusEgpuDisable,
                "No action required": Main.SGFXAction.Nothing
            })

        readonly property var actionMatrix: ({
                [Main.SGFXMode.Hybrid]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated
                    }),
                [Main.SGFXMode.Integrated]: ({
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.NvidiaNoModeset]: ({
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.Vfio]: ({
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.AsusEgpu]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.NvidiaNoModeset]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.AsusMuxDgpu]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.NvidiaNoModeset]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    })
            })

        function setMode(modeEnum: int): bool {
            if (!isValidMode(modeEnum)) {
                root.error("tried setting mode to invalid int", modeEnum);
                return false;
            }

            setModeProc.command = ["supergfxctl", "--mode", modeEnumReversed[modeEnum]];
            pendingMode = modeEnum;
            setModeProc.running = true;

            if (root.debug) {
                root.log(`Setting mode ${modeEnum}`);
            }

            return true;
        }

        function refresh(): void {
            if (root.debug) {
                root.log("refreshing...");
            }
            refreshProc.running = true;
        }

        function isVersionGreater(a, b) {
            return a.localeCompare(b, undefined, {
                numeric: true
            }) > 0;
        }

        function parseOutput(text: string): bool {
            if (text == "") {
                available = false;
                return available;
            }

            const lines = text.split("\n");

            if (lines.length != 5) {
                available = false;
                return available;
            }

            const lineVersion = lines[0] || "???";
            version = lineVersion;

            const lineMode = lines[1] || "None";
            const lineSupported = lines[2] || "[]";
            const linePendAction = lines[3] || "No action required";
            let linePendMode = lines[4] || "";

            if (linePendMode === "Unknown") {
                linePendMode = "None";
            }

            const newMode = modeEnum[lineMode] ?? Main.SGFXMode.None;
            const newPendMode = modeEnum[linePendMode] ?? Main.SGFXMode.None;

            let newSupportedMask = 0;
            if (lineSupported.length > 2) {
                const trimmed = lineSupported.substring(1, lineSupported.length - 1);
                const modeNames = trimmed.split(",");
                const modeEnums = modeNames.map(name => modeEnum[name.trim()] ?? Main.SGFXMode.None).filter(m => m >= 0);

                // for versions < 5.2.7, add Integrated and Hybrid if current mode is AsusMuxDgpu
                // https://gitlab.com/asus-linux/supergfxctl/-/merge_requests/44
                if (!isVersionGreater(lineVersion, "5.2.7") && newMode === Main.SGFXMode.AsusMuxDgpu) {
                    root.warn("fixing supergfxctl bug [merge request #44]: adding missing Integrated and Hybrid modes");

                    if (!modeEnums.includes(Main.SGFXMode.Integrated))
                        modeEnums.push(Main.SGFXMode.Integrated);
                    if (!modeEnums.includes(Main.SGFXMode.Hybrid))
                        modeEnums.push(Main.SGFXMode.Hybrid);
                }

                for (let i = 0; i < modeEnums.length; i++) {
                    newSupportedMask |= 1 << modeEnums[i];
                }
            }

            const newPendingAction = actionEnum[linePendAction] ?? Main.SGFXAction.Nothing;

            // does not work reliably on refresh, so
            // only set if pending mode has not been set manually
            if (pendingMode === Main.SGFXMode.None) {
                mode = newMode;
                pendingMode = newPendMode;
                pendingAction = requiredAction(sgfx.mode, newPendMode);
            }
            supportedModesMask = newSupportedMask;
            available = true;

            root.log("refreshed");

            return available;
        }

        function requiredAction(newMode: int, curMode: int): int {
            const row = actionMatrix[newMode];
            return row?.[curMode] ?? Main.SGFXAction.Nothing;
        }
    }
}
