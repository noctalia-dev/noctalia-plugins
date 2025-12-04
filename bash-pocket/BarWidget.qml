import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    implicitWidth: mainButton.implicitWidth
    implicitHeight: Style.barHeight
    color: "transparent"

    readonly property string pluginDir: Quickshell.env("HOME") + "/.config/noctalia/plugins/bash-pocket/pockets"

    Component.onCompleted: {
        ensureDir.running = true
    }

    Process {
        id: ensureDir
        command: ["mkdir", "-p", root.pluginDir]
        onExited: refreshPockets()
    }

    property var pockets: []

    function refreshPockets() {
        listProcess.running = true
    }

    Process {
        id: listProcess
        command: ["sh", "-c", "ls \"" + root.pluginDir + "\" | grep -E '^[0-9]+\\.sh$' | sed 's/\\.sh//' | sort -n"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n');
                var newPockets = [];
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") {
                        newPockets.push(parseInt(lines[i].trim()));
                    }
                }
                root.pockets = newPockets;
                updateMenuModel();
            }
        }
    }

    function addPocket() {
        var newIndex = 0;
        for (var i = 0; i < root.pockets.length; i++) {
            if (root.pockets[i] === newIndex) {
                newIndex++;
            } else {
                break;
            }
        }
        createProcess.newIndex = newIndex
        // Create file with shebang, then make it executable
        // Using printf instead of echo to handle newline properly
        createProcess.command = ["sh", "-c", "printf '#!/bin/bash\\n' > \"" + root.pluginDir + "/" + newIndex + ".sh\" && chmod +x \"" + root.pluginDir + "/" + newIndex + ".sh\""]
        createProcess.running = true
    }

    Process {
        id: createProcess
        property int newIndex: -1
        onExited: {
            if (exitCode === 0) {
                refreshPockets();
                editPocket(newIndex);
            }
        }
    }

    function editPocket(index) {
        var path = root.pluginDir + "/" + index + ".sh";
        
        // If $EDITOR is set, use it; otherwise use kitty -e nano
        var cmd = "if [ -n \"$EDITOR\" ]; then $EDITOR \"" + path + "\"; else kitty -e nano \"" + path + "\"; fi";
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function deletePocket(index) {
        deleteProcess.command = ["rm", root.pluginDir + "/" + index + ".sh"]
        deleteProcess.running = true
    }

    Process {
        id: deleteProcess
        onExited: refreshPockets()
    }

    function executePocket(index) {
        var path = root.pluginDir + "/" + index + ".sh";
        Quickshell.execDetached([path]);
    }

    property var menuModel: []

    function updateMenuModel() {
        var model = [];
        
        // Add existing pockets
        for (var i = 0; i < root.pockets.length; i++) {
            var index = root.pockets[i];
            model.push({
                "label": "Pocket " + index,
                "icon": "terminal",
                "action": "exec_" + index
            });
            model.push({
                "label": "Edit " + index,
                "icon": "pencil",
                "action": "edit_" + index
            });
            model.push({
                "label": "Delete " + index,
                "icon": "trash",
                "action": "delete_" + index
            });
            // Add separator if not last
            if (i < root.pockets.length - 1) {
                 // NContextMenu doesn't support separators natively in the model structure used here easily without custom delegate logic or model types, 
                 // but we can just list them sequentially.
            }
        }

        // Add "Add Pocket" action
        if (model.length > 0) {
             // Separator logic would be nice but let's just append
        }
        
        model.push({
            "label": "Add Pocket",
            "icon": "plus",
            "action": "add"
        });

        root.menuModel = model;
    }

    // Main Button (Icon only)
    NIconButton {
        id: mainButton
        icon: "terminal"
        onClicked: {
            var popupWindow = PanelService.getPopupMenuWindow(screen);
            if (popupWindow) {
                popupWindow.showContextMenu(pocketMenu);
                
                // Adjust Y to be below the bar
                var offsetY = Style.barHeight;
                if (Settings.data.bar.position === "bottom") {
                    offsetY = -pocketMenu.implicitHeight;
                }
                
                pocketMenu.openAtItem(mainButton, 0, offsetY);
            }
        }
    }

    PopupWindow {
        id: pocketMenu
        width: 260
        // Calculate height based on content
        implicitHeight: contentLayout.implicitHeight + Style.marginS * 2
        
        // Anchor properties required for PopupWindow
        property var anchorItem: null
        property real anchorX: 0
        property real anchorY: 0
        
        anchor.item: anchorItem
        anchor.rect.x: anchorX
        anchor.rect.y: anchorY
        
        visible: false
        color: Color.transparent

        function openAtItem(item, x, y) {
            anchorItem = item;
            anchorX = x;
            anchorY = y;
            visible = true;
        }
        
        function close() {
            visible = false;
            var popupWindow = PanelService.getPopupMenuWindow(screen);
            if (popupWindow) {
                popupWindow.close();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            border.color: Color.mOutline
            border.width: Style.borderS
            radius: Style.radiusM
            
            ColumnLayout {
                id: contentLayout
                width: parent.width
                anchors.centerIn: parent
                spacing: Style.marginS
                
                // Header / Title (Optional, but good for spacing)
                Item { height: Style.marginXS; width: 1 }

                Repeater {
                    model: root.pockets
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Style.marginS
                        Layout.rightMargin: Style.marginS
                        spacing: Style.marginS
                        
                        NButton {
                            text: "Pocket " + modelData
                            Layout.fillWidth: true
                            onClicked: {
                                root.executePocket(modelData);
                                pocketMenu.close();
                            }
                        }
                        
                        NIconButton {
                            icon: "pencil"
                            baseSize: Style.capsuleHeight * 0.8
                            onClicked: {
                                root.editPocket(modelData);
                                pocketMenu.close();
                            }
                        }
                        
                        NIconButton {
                            icon: "trash"
                            baseSize: Style.capsuleHeight * 0.8
                            colorFg: Color.mError
                            onClicked: {
                                root.deletePocket(modelData);
                            }
                        }
                    }
                }
                
                // Add Button
                NButton {
                    text: "+ Add Pocket"
                    Layout.fillWidth: true
                    Layout.margins: Style.marginS
                    onClicked: {
                        root.addPocket();
                    }
                }
                
                Item { height: Style.marginXS; width: 1 }
            }
        }
    }

}
