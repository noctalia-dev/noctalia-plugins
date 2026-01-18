import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.System
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    // TRANSLATION: Default checking text
    property string currentDnsName: pluginApi?.tr("status.checking") || "Checking..."
    property bool isChanging: false

    // --- 1. DATA STORAGE ---
    readonly property var defaultProviders: [
        {id: "google", label: "Google", ip: "8.8.8.8 8.8.4.4"},
        {id: "cloudflare", label: "Cloudflare", ip: "1.1.1.1 1.0.0.1"},
        {id: "opendns", label: "OpenDNS", ip: "208.67.222.222 208.67.220.220"},
        {id: "adguard", label: "AdGuard", ip: "94.140.14.14 94.140.15.15"},
        {id: "quad9", label: "Quad9", ip: "9.9.9.9 149.112.112.112"}
    ]
    property var customProviders: []

    function loadCustomServers() {
        if (!pluginApi) return
            try {
                var json = pluginApi.pluginSettings.savedServers || "[]"
                customProviders = JSON.parse(json)
            } catch(e) { customProviders = [] }
    }

    function addCustomServer(name, ip) {
        if (!name || !ip) return
            var list = customProviders
            list.push({label: name, ip: ip, isCustom: true})
            customProviders = list
            saveCustomServers()
    }

    function removeCustomServer(index) {
        var list = customProviders
        list.splice(index, 1)
        customProviders = list
        saveCustomServers()
    }

    function saveCustomServers() {
        if (pluginApi) {
            pluginApi.pluginSettings.savedServers = JSON.stringify(customProviders)
            pluginApi.saveSettings()
        }
    }
    Component.onCompleted: loadCustomServers()

    // --- 2. DETECTION LOGIC ---
    function getDnsName(ip) {
        // Check Defaults
        if (ip.includes("8.8.8.8")) return "Google";
        if (ip.includes("1.1.1.1")) return "Cloudflare";
        if (ip.includes("208.67.222.222")) return "OpenDNS";
        if (ip.includes("94.140.14.14")) return "AdGuard";
        if (ip.includes("9.9.9.9")) return "Quad9";

        // Check Custom
        for (var i = 0; i < customProviders.length; i++) {
            var srv = customProviders[i];
            if (ip.includes(srv.ip.split(" ")[0])) return srv.label;
        }

        // TRANSLATION: Default Status
        if (ip === "" || ip.includes("192.168") || ip.includes("127.0"))
            return pluginApi?.tr("status.default") || "Default (ISP)";

        // TRANSLATION: Custom IP Status
        return pluginApi?.tr("status.custom", { ip: ip }) || "Custom (" + ip + ")";
    }

    Timer {
        interval: 3000;
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: checkProcess.running = true
    }

    Process {
        id: checkProcess
        command: ["sh", "-c", "nmcli -f IP4.DNS dev show | head -n 1 | awk '{print $2}'"]
        stdout: StdioCollector {
            onTextChanged: {
                var ip = text.trim();
                root.currentDnsName = getDnsName(ip);
            }
        }
    }

    // --- 3. APPLY LOGIC ---
    function setDns(payload) {
        if (isChanging) return;
        isChanging = true;

        // TRANSLATION: Switching Status
        root.currentDnsName = pluginApi?.tr("status.switching") || "Switching...";

        var dnsIp = payload;
        var preset = defaultProviders.find(p => p.id === payload);
        if (preset) dnsIp = preset.ip;
        if (payload === "default") dnsIp = "";

        var cmd = "CON=$(nmcli -t -f NAME connection show --active | head -n 1); " +
        "if [ -z \"$CON\" ]; then exit 1; fi; " +
        "if [ -z \"" + dnsIp + "\" ]; then " +
        "nmcli con mod \"$CON\" ipv4.dns \"\" ipv4.ignore-auto-dns no; " +
        "else " +
        "nmcli con mod \"$CON\" ipv4.dns \"" + dnsIp + "\" ipv4.ignore-auto-dns yes; " +
        "fi; " +
        "nmcli con down \"$CON\"; nmcli con up \"$CON\"";

        changeProcess.command = ["pkexec", "sh", "-c", cmd];
        changeProcess.running = true;
    }

    Process {
        id: changeProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            root.isChanging = false;
            checkProcess.running = true;
        }
    }
}
