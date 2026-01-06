import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 450 * Style.uiScaleRatio
    property real contentPreferredHeight: 600 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    
    anchors.fill: parent

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string githubToken: cfg.githubToken || defaults.githubToken || ""
    readonly property bool showOnlyUnread: cfg.showOnlyUnread ?? defaults.showOnlyUnread ?? false
    readonly property int maxNotifications: cfg.maxNotifications ?? defaults.maxNotifications ?? 30

    property var notifications: []
    property bool loading: false
    property bool error: false
    property string errorMessage: ""

    Component.onCompleted: {
        if (githubToken) {
            Qt.callLater(fetchNotifications);
        }
    }

    onVisibleChanged: {
        if (visible && githubToken && !loading) {
            console.log("GitHub Notifications Panel: Opened, fetching notifications...");
            Qt.callLater(fetchNotifications);
        }
    }

    Process {
        id: fetchProcess
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        
        property bool isFetching: false
        
        onExited: exitCode => {
            if (!isFetching) return;
            isFetching = false;
            loading = false;
            
            if (exitCode !== 0) {
                console.error("GitHub Notifications Panel: curl failed with code", exitCode);
                console.error("GitHub Notifications Panel: stderr:", stderr.text);
                error = true;
                return;
            }
            
            if (!stdout.text || stdout.text.trim() === "") {
                console.error("GitHub Notifications Panel: Empty response");
                error = true;
                return;
            }
            
            try {
                const data = JSON.parse(stdout.text);
                if (data && data.message) {
                    error = true;
                    errorMessage = data.message;
                    notifications = [];
                    return;
                }
                
                if (Array.isArray(data)) {
                    notifications = data.slice(0, maxNotifications);
                    console.log("GitHub Notifications Panel: Got", notifications.length, "notifications");
                } else {
                    console.error("GitHub Notifications Panel: Response is not an array");
                    error = true;
                }
            } catch (e) {
                console.error("GitHub Notifications Panel: Parse error:", e);
                error = true;
            }
        }
    }

    Timer {
        id: refreshDelayTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: {
            console.log("GitHub Notifications Panel: Triggering BarWidget refresh after delay");
            if (pluginApi?.triggerRefresh) {
                pluginApi.triggerRefresh();
            }
        }
    }

    Process {
        id: markReadProcess
        running: false
        stdout: StdioCollector {}
        
        onExited: exitCode => {
            if (exitCode === 0) {
                fetchNotifications();
                // Notify BarWidget to refresh after delay (give time for GitHub API to process)
                refreshDelayTimer.start();
            }
        }
    }

    Process {
        id: markAllReadProcess
        running: false
        stdout: StdioCollector {}
        
        onExited: exitCode => {
            if (exitCode === 0) {
                fetchNotifications();
                // Notify BarWidget to refresh after delay (give time for GitHub API to process)
                refreshDelayTimer.start();
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Style.backgroundColor || "#1E1E1E"
        radius: Style.radiusL || 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM || 12
            spacing: Style.marginM || 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM || 12

                Text {
                    text: pluginApi?.tr("widget.title", "GitHub Notifications") || "GitHub Notifications"
                    font.pixelSize: Style.fontSizeL || 18
                    font.bold: true
                    color: Style.textColor || "#FFFFFF"
                    Layout.fillWidth: true
                }

                Text {
                    visible: notifications.length > 0
                    text: notifications.filter(n => n.unread).length + " unread"
                    font.pixelSize: Style.fontSizeM || 14
                    color: Style.textColorSecondary || "#888888"
                }

                NButton {
                    text: pluginApi?.tr("widget.markAllRead", "Mark all as read") || "Mark all as read"
                    enabled: notifications.filter(n => n.unread).length > 0 && !loading
                    onClicked: markAllAsRead()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Style.borderColor || "#333333"
            }

            // Content
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    model: notifications
                    spacing: Style.marginS || 8

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: notifLayout.implicitHeight + 16
                        color: modelData.unread ? (Style.fillColorTertiary || "#2A2A2A") : (Style.fillColorSecondary || "#1A1A1A")
                        radius: Style.radiusM || 8

                        Rectangle {
                            visible: modelData.unread
                            width: 3
                            height: parent.height
                            color: Style.accentColor || "#4A9EFF"
                            radius: 1.5
                        }

                        RowLayout {
                            id: notifLayout
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: Style.marginS || 8

                            Text {
                                text: getNotificationIcon(modelData)
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: Style.fontSizeL || 18
                                color: Style.textColor || "#FFFFFF"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: modelData.subject?.title || "Notification"
                                    font.pixelSize: Style.fontSizeM || 14
                                    font.bold: modelData.unread
                                    color: Style.textColor || "#FFFFFF"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.repository?.full_name || ""
                                    font.pixelSize: Style.fontSizeS || 12
                                    color: Style.textColorSecondary || "#888888"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.unread) {
                                    markAsRead(modelData.id);
                                }
                                if (modelData.subject?.url) {
                                    Qt.openUrlExternally(convertApiUrlToWeb(modelData));
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Style.borderColor || "#333333"
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: notifications.length + " notifications"
                    font.pixelSize: Style.fontSizeS || 12
                    color: Style.textColorSecondary || "#888888"
                    Layout.fillWidth: true
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            width: 40
            height: 40
            visible: loading
            running: loading
        }
    }

    function fetchNotifications() {
        if (!githubToken || loading) return;
        
        console.log("GitHub Notifications Panel: Fetching...");
        loading = true;
        error = false;
        errorMessage = "";
        
        const url = showOnlyUnread 
            ? "https://api.github.com/notifications"
            : "https://api.github.com/notifications?all=true";
        
        fetchProcess.command = [
            "curl", "-s",
            "-H", "Authorization: token " + githubToken,
            "-H", "Accept: application/vnd.github.v3+json",
            url
        ];
        fetchProcess.isFetching = true;
        fetchProcess.running = true;
    }

    function markAsRead(notificationId) {
        if (!githubToken) return;
        
        const url = `https://api.github.com/notifications/threads/${notificationId}`;
        
        markReadProcess.command = [
            "curl", "-s", "-X", "PATCH",
            "-H", "Authorization: token " + githubToken,
            "-H", "Accept: application/vnd.github.v3+json",
            url
        ];
        markReadProcess.running = true;
    }

    function markAllAsRead() {
        if (!githubToken) return;
        
        const url = "https://api.github.com/notifications";
        
        markAllReadProcess.command = [
            "curl", "-s", "-X", "PUT",
            "-H", "Authorization: token " + githubToken,
            "-H", "Accept: application/vnd.github.v3+json",
            url
        ];
        markAllReadProcess.running = true;
    }

    function getNotificationIcon(notification) {
        const type = notification.subject?.type || "";
        switch (type) {
            case "Issue": return "\uf41b";
            case "PullRequest": return "\uea64";
            case "Release": return "\uea84";
            case "CheckSuite": return "\uf418";
            case "Discussion": return "\uf442";
            default: return "\uf0a1";
        }
    }

    function convertApiUrlToWeb(notification) {
        const url = notification.subject?.url || "";
        if (url.includes("/repos/")) {
            return url.replace("api.github.com/repos/", "github.com/")
                      .replace("/pulls/", "/pull/")
                      .replace("/issues/", "/issues/");
        }
        return url;
    }
}
