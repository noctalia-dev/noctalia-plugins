import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    
    readonly property bool isVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

    // Configuration
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string githubToken: cfg.githubToken || defaults.githubToken || ""
    readonly property int checkInterval: cfg.checkInterval ?? defaults.checkInterval ?? 300
    readonly property bool showOnlyUnread: cfg.showOnlyUnread ?? defaults.showOnlyUnread ?? false
    readonly property int maxNotifications: cfg.maxNotifications ?? defaults.maxNotifications ?? 30

    // State
    property var notifications: []
    property int unreadCount: 0
    property bool loading: false
    property bool error: false
    property string errorMessage: ""
    
    // Expose state to pluginApi for Panel access
    onNotificationsChanged: {
        if (pluginApi) {
            pluginApi.sharedData = pluginApi.sharedData || {};
            pluginApi.sharedData.notifications = notifications;
        }
    }
    onLoadingChanged: {
        if (pluginApi) {
            pluginApi.sharedData = pluginApi.sharedData || {};
            pluginApi.sharedData.loading = loading;
        }
    }
    onErrorChanged: {
        if (pluginApi) {
            pluginApi.sharedData = pluginApi.sharedData || {};
            pluginApi.sharedData.error = error;
        }
    }
    onErrorMessageChanged: {
        if (pluginApi) {
            pluginApi.sharedData = pluginApi.sharedData || {};
            pluginApi.sharedData.errorMessage = errorMessage;
        }
    }
    
    // Expose functions to pluginApi for Panel access
    Component.onCompleted: {
        console.log("GitHub Notifications: Widget loaded");
        console.log("GitHub Notifications: pluginApi is", pluginApi ? "available" : "null");
        console.log("GitHub Notifications: cfg:", JSON.stringify(cfg));
        console.log("GitHub Notifications: defaults:", JSON.stringify(defaults));
        console.log("GitHub Notifications: Token present:", githubToken ? "yes (" + githubToken.substring(0, 10) + "...)" : "no");
        console.log("GitHub Notifications: Check interval:", checkInterval);
        
        if (pluginApi) {
            pluginApi.sharedData = pluginApi.sharedData || {};
            pluginApi.triggerRefresh = fetchNotifications;
            pluginApi.markAsRead = markAsRead;
            pluginApi.markAllAsRead = markAllAsRead;
        }
    }

    implicitWidth: Math.max(60, isVertical ? (Style.capsuleHeight || 32) : contentWidth)
    implicitHeight: Math.max(32, isVertical ? contentHeight : (Style.capsuleHeight || 32))
    radius: Style.radiusM || 8
    color: Style.fillColorSecondary || "#2A2A2A"

    readonly property real contentWidth: rowLayout.implicitWidth + (Style.marginM || 8) * 2
    readonly property real contentHeight: rowLayout.implicitHeight + (Style.marginM || 8) * 2

    // Timer for periodic updates
    Timer {
        id: updateTimer
        interval: checkInterval * 1000
        running: githubToken !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            console.log("GitHub Notifications: Timer triggered");
            fetchNotifications();
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
            
            console.log("GitHub Notifications: Process exited with code", exitCode);
            console.log("GitHub Notifications: stdout length:", stdout.text.length);
            console.log("GitHub Notifications: stderr:", stderr.text);
            
            if (exitCode !== 0) {
                console.error("GitHub Notifications: curl failed with exit code", exitCode);
                console.error("GitHub Notifications: stderr:", stderr.text);
                console.error("GitHub Notifications: stdout:", stdout.text);
                error = true;
                return;
            }
            
            if (!stdout.text || stdout.text.trim() === "") {
                console.error("GitHub Notifications: Empty response from API");
                error = true;
                return;
            }
            
            try {
                const data = JSON.parse(stdout.text);
                console.log("GitHub Notifications: Parsed data, got", Array.isArray(data) ? data.length : 0, "notifications");
                
                if (data && data.message) {
                    console.error("GitHub Notifications: API error:", data.message);
                    error = true;
                    errorMessage = data.message;
                    notifications = [];
                    unreadCount = 0;
                    return;
                }
                
                if (Array.isArray(data)) {
                    notifications = data;
                    unreadCount = data.filter(n => n.unread).length;
                    console.log("GitHub Notifications: Unread count:", unreadCount);
                } else {
                    console.error("GitHub Notifications: Response is not an array");
                    error = true;
                }
            } catch (e) {
                console.error("GitHub Notifications: Parse error:", e);
                console.error("GitHub Notifications: Raw stdout:", stdout.text.substring(0, 200));
                error = true;
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
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: Style.marginS || 4

        // GitHub Icon
        Text {
            text: "\uf09b" // Nerd Font GitHub icon
            font.family: "Symbols Nerd Font"
            font.pixelSize: Style.fontSizeL || 16
            color: Style.textColor || "#FFFFFF"
        }

        // Unread badge
        Rectangle {
            visible: unreadCount > 0
            implicitWidth: badgeText.implicitWidth + 12
            implicitHeight: badgeText.implicitHeight + 6
            radius: height / 2
            color: Style.accentColor || "#FF6B6B"

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: unreadCount > 99 ? "99+" : unreadCount.toString()
                font.pixelSize: Style.fontSizeS || 11
                font.bold: true
                color: "#FFFFFF"
            }
        }
    }

    // Loading indicator
    BusyIndicator {
        anchors.centerIn: parent
        width: 20
        height: 20
        visible: loading
        running: loading
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(screen);
            }
        }
        cursorShape: Qt.PointingHandCursor
    }

    function fetchNotifications() {
        if (!githubToken || loading) {
            console.log("GitHub Notifications: Skipping fetch - token:", githubToken ? "present" : "missing", "loading:", loading);
            return;
        }
        
        console.log("GitHub Notifications: Fetching notifications...");
        loading = true;
        error = false;
        errorMessage = "";
        
        const url = showOnlyUnread 
            ? "https://api.github.com/notifications"
            : "https://api.github.com/notifications?all=true";
        
        console.log("GitHub Notifications: URL:", url);
        console.log("GitHub Notifications: Token:", githubToken.substring(0, 10) + "...");
        console.log("GitHub Notifications: showOnlyUnread:", showOnlyUnread);
        
        fetchProcess.command = [
            "curl", "-s",
            "-H", "Authorization: token " + githubToken,
            "-H", "Accept: application/vnd.github.v3+json",
            url
        ];
        console.log("GitHub Notifications: Command:", JSON.stringify(fetchProcess.command));
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
}
