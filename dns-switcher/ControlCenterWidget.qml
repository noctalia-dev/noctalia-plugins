import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

NIconButton {
    id: root

    // --- Injected Properties ---
    property var pluginApi: null
    property var screen: null
    readonly property var mainInstance: pluginApi?.mainInstance

    // --- Appearance ---
    // 1. Icon Logic
    icon: {
        var name = mainInstance?.currentDnsName || "";
        if (name === "Google") return "brand-google";
        if (name === "Cloudflare") return "cloud";
        if (name === "AdGuard") return "shield-check";
        if (name === "Quad9") return "lock";
        return "globe";
    }

    // 2. Active State (Colored if not using Default/ISP)
    property bool isActive: (mainInstance?.currentDnsName || "") !== "Default (ISP)"

    // 3. Colors (Primary when active, Gray when inactive)
    colorBg: isActive ? Color.mPrimary : Color.mSurfaceVariant
    colorFg: isActive ? Color.mOnPrimary : Color.mOnSurface

    // 4. Tooltip
    tooltipText: mainInstance?.currentDnsName || "DNS Switcher"

    // --- Interaction ---
    onClicked: {
        if (pluginApi) {
            // Open the panel attached to THIS button
            pluginApi.openPanel(root.screen, root)
        }
    }
}
