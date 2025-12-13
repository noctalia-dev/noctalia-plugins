import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

// Settings UI Component for Hello World Plugin
ColumnLayout {
    id: root

    // Plugin API (injected by the settings dialog system)
    property var pluginApi: null

    // Local state - track changes before saving
    property string valueLayout: pluginApi?.pluginSettings?.layout || pluginApi?.manifest?.metadata?.defaultSettings?.layout || "qwerty"
    property string valueStyle: pluginApi?.pluginSettings?.size || pluginApi?.manifest?.metadata?.defaultSettings?.size || "compact"
    
    spacing: Style.marginM

    FolderListModel {
        id: jsonFiles
        folder: "file://" + Settings.configDir + "plugins/virtual-keyboard/layouts/"
        nameFilters: ["*.json"]
    }
    
    NComboBox {
        id: layouts
        label: pluginApi?.tr("settings.layout.label")
        description: pluginApi?.tr("settings.layout.description")
        model: []
        currentKey: root.valueLayout
        onSelected: key => root.valueLayout = key
    }

    Repeater {
        model: jsonFiles

        Item {
            width: 0
            height: 0
            
            FileView {
                path: model.filePath

                onLoaded: {
                    try {
                        let name = model.fileName.slice(0, -5)
                        layouts.model.push({
                            "key": name,
                            "name": name
                        })
                        layouts.currentKey = root.valueLayout
                    } catch(e) {
                        Logger.e("Keyboard", "JSON Error in", model.fileName, ":", e)
                    }
                }
            }
        }
    }

    NComboBox {
        id: styles
        label: pluginApi?.tr("settings.size.label")
        description: pluginApi?.tr("settings.size.description")
        model: [
            {
                "key": "compact",
                "name": pluginApi?.tr("options.size.compact")
            },
            {
                "key": "full",
                "name": pluginApi?.tr("options.size.full")
            }
        ]
        currentKey: root.valueStyle
        onSelected: key => root.valueStyle = key
    }

    Component.onCompleted: {
        Logger.i("Keyboard", "Settings UI loaded");
    }

    // This function is called by the dialog to save settings
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("VirtualKeyboard", "Cannot save settings: pluginApi is null");
            return;
        }

        // Update the plugin settings object
        pluginApi.pluginSettings.layout = root.valueLayout;
        pluginApi.pluginSettings.size = root.valueStyle;
        
        // Save to disk and reload keyboard
        if (pluginApi.pluginSettings.enabled == true) {
            pluginApi.pluginSettings.enabled = false
            pluginApi.saveSettings()
            pluginApi.pluginSettings.enabled = true
            pluginApi.saveSettings()
        }
        else {
            pluginApi.saveSettings();
        }

        Logger.i("VirtualKeyboard", "Settings saved successfully");
    }
}