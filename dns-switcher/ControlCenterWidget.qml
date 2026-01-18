import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property var screen: null
    readonly property var mainInstance: pluginApi?.mainInstance

    icon: {
        var name = mainInstance?.currentDnsName || "";
        if (name === "Google") return "brand-google";
        if (name === "Cloudflare") return "cloud";
        if (name === "AdGuard") return "shield-check";
        if (name === "Quad9") return "lock";
        return "globe";
    }

    // TRANSLATION: Status check against translated string
    property bool isActive: (mainInstance?.currentDnsName || "") !== (pluginApi?.tr("status.default") || "Default (ISP)")

    colorBg: isActive ? Color.mPrimary : Color.mSurfaceVariant
    colorFg: isActive ? Color.mOnPrimary : Color.mOnSurface

    // TRANSLATION: Tooltip
    tooltipText: mainInstance?.currentDnsName || pluginApi?.tr("plugin.title") || "DNS Switcher"

    onClicked: {
        if (pluginApi) {
            pluginApi.openPanel(root.screen, root)
        }
    }
}
