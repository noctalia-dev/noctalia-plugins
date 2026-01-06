import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    width: 700

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string valueGithubToken: cfg.githubToken || defaults.githubToken || ""
    property int valueCheckInterval: cfg.checkInterval ?? defaults.checkInterval ?? 300
    property bool valueShowOnlyUnread: cfg.showOnlyUnread ?? defaults.showOnlyUnread ?? false
    property int valueMaxNotifications: cfg.maxNotifications ?? defaults.maxNotifications ?? 30

    function saveSettings() {
        if (!pluginApi) {
            console.error("GitHub Notifications: Cannot save settings - pluginApi is null");
            return;
        }
        
        if (!valueGithubToken || valueGithubToken.trim() === "") {
            console.error("GitHub Notifications: Token is required");
            return;
        }
        
        pluginApi.pluginSettings.githubToken = valueGithubToken;
        pluginApi.pluginSettings.checkInterval = valueCheckInterval;
        pluginApi.pluginSettings.showOnlyUnread = valueShowOnlyUnread;
        pluginApi.pluginSettings.maxNotifications = valueMaxNotifications;
        
        pluginApi.saveSettings();
        console.log("GitHub Notifications: Settings saved successfully");
    }

    // Header
    Text {
        text: pluginApi?.tr("settings.settings-title") || "GitHub Notifications Settings"
        font.pointSize: 14
        font.weight: Font.Bold
        color: Color.mOnSurface
        Layout.fillWidth: true
    }

    // Help Button
    NButton {
        text: "📖 " + (pluginApi?.tr("settings.setup-help") || "Setup Help")
        Layout.fillWidth: true
        onClicked: helpPopup.open()
    }

    Popup {
        id: helpPopup
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(650, parent.width - 40)
        height: Math.min(550, parent.height - 40)
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusM
            border.color: Color.mOutline
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                
                Text {
                    text: pluginApi?.tr("settings.setup-help") || "Setup Help"
                    font.pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }
                
                NIconButton {
                    icon: "window-close"
                    Layout.preferredWidth: Style.baseWidgetSize * 0.8
                    Layout.preferredHeight: Style.baseWidgetSize * 0.8
                    onClicked: helpPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Color.mOutline
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginL

                    Text {
                        text: pluginApi?.tr("settings.help-step1-title") || "1. Create GitHub Personal Access Token"
                        font.pointSize: Style.fontSizeM
                        font.weight: Font.Bold
                        color: Color.mPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step1-desc") || "Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    NButton {
                        text: pluginApi?.tr("settings.visit-github") || "Visit GitHub Token Settings"
                        Layout.fillWidth: true
                        onClicked: Qt.openUrlExternally("https://github.com/settings/tokens")
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step2-title") || "2. Generate New Token (Classic)"
                        font.pointSize: Style.fontSizeM
                        font.weight: Font.Bold
                        color: Color.mPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step2-desc") || "Click 'Generate new token' → 'Generate new token (classic)'"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step3-title") || "3. Configure Token"
                        font.pointSize: Style.fontSizeM
                        font.weight: Font.Bold
                        color: Color.mPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step3-desc") || "• Note: 'Noctalia Notifications'\n• Expiration: Choose your preference\n• Select scope: ✓ notifications"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step4-title") || "4. Generate and Copy Token"
                        font.pointSize: Style.fontSizeM
                        font.weight: Font.Bold
                        color: Color.mPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step4-desc") || "Click 'Generate token' and copy the generated token (starts with 'ghp_')"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Color.mOutline
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: "⚠️ " + (pluginApi?.tr("settings.help-warning") || "Save the token now! You won't be able to see it again.")
                        font.pointSize: Style.fontSizeS
                        font.weight: Font.Bold
                        color: Color.mError
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: Style.marginS
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Color.mOutline
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step5-title") || "5. Paste Token in Plugin"
                        font.pointSize: Style.fontSizeM
                        font.weight: Font.Bold
                        color: Color.mPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: Style.marginM
                    }

                    Text {
                        text: pluginApi?.tr("settings.help-step5-desc") || "Paste the token in the 'GitHub Token' field above and click Save"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // GitHub Token
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.github-token") || "GitHub Token"
            description: pluginApi?.tr("settings.github-token-desc") || "Personal access token with 'notifications' scope"
        }

        NTextInput {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.baseWidgetSize
            text: valueGithubToken
            placeholderText: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            onTextChanged: valueGithubToken = text
        }
    }

    // Check Interval
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.check-interval") || "Check Interval"
            description: pluginApi?.tr("settings.check-interval-desc") || "How often to check for new notifications (in seconds)"
        }

        NSpinBox {
            Layout.fillWidth: true
            from: 60
            to: 3600
            stepSize: 60
            value: valueCheckInterval
            suffix: " s"
            onValueChanged: valueCheckInterval = value
        }
    }

    // Show Only Unread
    NToggle {
        label: pluginApi?.tr("settings.only-unread") || "Show Only Unread"
        description: pluginApi?.tr("settings.only-unread-desc") || "Display only unread notifications"
        checked: valueShowOnlyUnread
        onToggled: function(checked) {
            valueShowOnlyUnread = checked
        }
    }

    // Max Notifications
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.max-notifications") || "Maximum Notifications"
            description: pluginApi?.tr("settings.max-notifications-desc") || "Maximum number of notifications to display"
        }

        NSpinBox {
            Layout.fillWidth: true
            from: 5
            to: 50
            value: valueMaxNotifications
            onValueChanged: valueMaxNotifications = value
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
