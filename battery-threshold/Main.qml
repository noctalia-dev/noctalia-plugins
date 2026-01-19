import QtQuick

// Start the BatteryThresholdService to restore a previously set charge
// threshold when the plugin is loaded. This is needed as FW may reset
// the charge threshold when the device is fully powered off.
Item {
    property var pluginApi: null

    BatteryThresholdService {
        id: service
        pluginApi: parent.pluginApi
    }
}
