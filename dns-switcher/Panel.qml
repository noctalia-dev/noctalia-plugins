import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    // --- API & Sizing ---
    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance

    property real contentPreferredWidth: Math.round(360 * Style.uiScaleRatio)
    property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

    readonly property var geometryPlaceholder: bg
    readonly property bool allowAttach: true

    // State for Adding
    property string newName: ""
    property string newIp: ""
    property bool isAdding: false

    // --- BACKGROUND ---
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOutline, 0.2)
        border.width: 1

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // 1. HEADER
            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: headerRow.implicitHeight + Style.marginM

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: "globe"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                    }

                    NText {
                        // TRANSLATION: Plugin Title
                        text: pluginApi?.tr("plugin.title") || "DNS Switcher"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: mainInstance?.currentDnsName || "..."
                        pointSize: Style.fontSizeS
                        color: (mainInstance?.currentDnsName === (pluginApi?.tr("status.switching") || "Switching...")) ?
                        Color.mPrimary : Color.mSecondary
                        font.weight: Font.Medium
                    }
                }
            }

            // 2. SCROLLABLE LIST
            NScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(240 * Style.uiScaleRatio)
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginS

                    // --- COMPONENT: DNS OPTION (FLICKER-FREE) ---
                    component DnsOption: Rectangle {
                        id: opt
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(50 * Style.uiScaleRatio)
                        radius: Style.radiusM

                        property string label: ""
                        property string providerIp: ""
                        property bool isCustom: false
                        property bool isActive: (mainInstance?.currentDnsName || "") === label

                        // 1. BASE COLOR (Only handles Active/Inactive)
                        color: isActive ? Color.mPrimary : Color.mSurfaceVariant
                        Behavior on color { ColorAnimation { duration: Style.animationFast } }

                        // 2. HOVER OVERLAY (Dedicated invisible layer)
                        Rectangle {
                            anchors.fill: parent
                            radius: opt.radius
                            color: (hoverArea.containsMouse && !opt.isActive) ? Color.mHover : "transparent"
                            opacity: (hoverArea.containsMouse && !opt.isActive) ? 0.2 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.marginM
                            anchors.rightMargin: Style.marginM
                            spacing: Style.marginM

                            NIcon {
                                icon: opt.isActive ? "check" : "circle"
                                pointSize: Style.fontSizeM
                                color: opt.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
                            }

                            NText {
                                text: opt.label
                                pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                color: opt.isActive ? Color.mOnPrimary : Color.mOnSurface
                                Layout.fillWidth: true
                            }

                            NIconButton {
                                visible: opt.isCustom
                                icon: "trash"
                                colorFg: opt.isActive ? Color.mOnPrimary : Color.mError
                                onClicked: if (mainInstance) mainInstance.removeCustomServer(index - 5)
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mainInstance) mainInstance.setDns(opt.providerIp)
                                    if (pluginApi) pluginApi.withCurrentScreen((s) => pluginApi.closePanel(s))
                            }
                        }
                    }

                    // --- LIST ITEMS ---
                    DnsOption { label: "Google"; providerIp: "google" }
                    DnsOption { label: "Cloudflare"; providerIp: "cloudflare" }
                    DnsOption { label: "OpenDNS"; providerIp: "opendns" }
                    DnsOption { label: "AdGuard"; providerIp: "adguard" }
                    DnsOption { label: "Quad9"; providerIp: "quad9" }

                    Repeater {
                        model: mainInstance ? mainInstance.customProviders : []
                        delegate: DnsOption {
                            label: modelData.label
                            providerIp: modelData.ip
                            isCustom: true
                        }
                    }
                }
            }

            // 3. ADD CUSTOM SERVER BUTTON
            NButton {
                Layout.fillWidth: true
                // TRANSLATION: Add/Cancel
                text: root.isAdding
                ? (pluginApi?.tr("panel.cancel") || "Cancel")
                : (pluginApi?.tr("panel.add_server") || "Add Custom Server")
                icon: root.isAdding ? "x" : "plus"
                backgroundColor: root.isAdding ? Color.mSurfaceVariant : Qt.alpha(Color.mPrimary, 0.15)
                textColor: root.isAdding ? Color.mOnSurface : Color.mPrimary
                onClicked: root.isAdding = !root.isAdding
            }

            // 4. ADD FORM
            ColumnLayout {
                Layout.fillWidth: true;
                visible: root.isAdding; spacing: Style.marginS
                RowLayout {
                    spacing: Style.marginS
                    NTextInput {
                        Layout.fillWidth: true;
                        // TRANSLATION: Name
                        label: pluginApi?.tr("panel.name_placeholder") || "Name"
                        placeholderText: pluginApi?.tr("panel.name_placeholder") || "Name"
                        onTextChanged: root.newName = text
                    }
                    NTextInput {
                        Layout.fillWidth: true;
                        // TRANSLATION: IP
                        label: pluginApi?.tr("panel.ip_placeholder") || "IP"
                        placeholderText: pluginApi?.tr("panel.ip_placeholder") || "IP"
                        onTextChanged: root.newIp = text
                    }
                }
                NButton {
                    Layout.fillWidth: true;
                    // TRANSLATION: Save
                    text: pluginApi?.tr("panel.save") || "Save"
                    icon: "check"
                    onClicked: {
                        if (mainInstance) {
                            mainInstance.addCustomServer(root.newName, root.newIp);
                            root.newName = ""; root.newIp = ""; root.isAdding = false
                        }
                    }
                }
            }

            // 5. RESET BUTTON
            NButton {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                // TRANSLATION: Reset
                text: pluginApi?.tr("panel.reset") || "Reset to Default (ISP)"
                icon: "refresh"
                backgroundColor: Qt.alpha(Color.mError, 0.15)
                textColor: Color.mError
                onClicked: {
                    if (mainInstance) mainInstance.setDns("default")
                        if (pluginApi) pluginApi.withCurrentScreen((s) => pluginApi.closePanel(s))
                }
            }
        }
    }
}
