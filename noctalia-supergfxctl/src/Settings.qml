/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var gpuApi: pluginApi?.mainInstance

    property bool debug: pluginApi?.pluginSettings?.debug || pluginApi?.manifest?.metadata?.defaultSettings?.debug || false

    spacing: Style.marginM

    NToggle {
        Layout.fillWidth: true
        label: "Debug"
        description: "Print debug values in console"
        checked: root.debug
        onToggled: checked => root.debug = checked
    }

    // This function is called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            gpuApi?.error("cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.debug = root.debug;

        // Save to disk
        pluginApi.saveSettings();

        gpuApi?.log("settings saved successfully");
    }
}
