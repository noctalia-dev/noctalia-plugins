import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property int updateInterval: pluginApi?.pluginSettings?.updateInterval || pluginApi?.manifest?.metadata?.defaultSettings?.updateInterval
    property string configuredTerminal: pluginApi?.pluginSettings?.configuredTerminal || pluginApi?.manifest?.metadata.defaultSettings?.configuredTerminal
    property string configuredIcon: pluginApi?.pluginSettings?.configuredIcon || pluginApi?.manifest?.metadata?.defaultSettings?.configuredIcon
    property bool hideOnZero: pluginApi?.pluginSettings?.hideOnZero || pluginApi?.manifest?.metadata?.defaultSettings?.hideOnZero

    spacing: Style.marginM

    Component.onCompleted: {
        Logger.i("UpdateCount", "Settings UI loaded");
    }

    NToggle {
        id: widgetSwitch
        label: "Hide Widget"
        description: "Hide widget when there are no updates available?"
        checked: root.hideOnZero
        onToggled: function (checked) {
            root.hideOnZero = checked;
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Terminal"
        description: "Configure your current terminal. Default: foot -e"
        placeholderText: "Enter your terminal emulator here..."
        text: root.configuredTerminal
        onTextChanged: root.configuredTerminal = text
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: "Check for Updates Interval"
            description: "How often to check for updates (in minutes). Default: 5 Minutes."
        }

        NSlider {
            from: 5
            to: 180
            value: root.updateInterval / 60000
            stepSize: 5
            onValueChanged: {
                root.updateInterval = value * 60000;
            }
        }

        NText {
            text: (root.updateInterval / 60000) + " minutes"
            color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
            text: "Current Icon: " + (pluginApi?.pluginSettings?.configuredIcon || pluginApi?.manifest?.metadata?.defaultSettings?.configuredIcon)
            color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
        }

        NIcon {
            icon: root.configuredIcon
            color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
        }

        NButton {
            text: "Change Icon"
            onClicked: {
                Logger.i("UpdateCount", "Icon!");
                changeIcon.open();
            }
        }

        NIconPicker {
            id: changeIcon
            onIconSelected: function (icon) {
                root.configuredIcon = icon;
            }
        }
    }

    function timeValue() {
        value = root.updateInterval / 60000;
        if (value / 60 >= 1) {
            value = value / 60;
            return " hour/s";
        } else {
            return " minutes";
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("UpdateCount", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.updateInterval = root.updateInterval;
        pluginApi.pluginSettings.configuredTerminal = root.configuredTerminal;
        pluginApi.pluginSettings.configuredIcon = root.configuredIcon;
        pluginApi.pluginSettings.hideOnZero = root.hideOnZero;

        pluginApi.saveSettings();

        Logger.i("UpdateCount", "Settings saved successfully");
        pluginApi.closePanel(root.screen);
    }
}
