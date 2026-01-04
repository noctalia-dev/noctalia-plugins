/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    // noctalia plugin api, injected dynamically
    property QtObject pluginApi: null
    readonly property QtObject pluginSettings: pluginApi?.mainInstance.pluginSettings

    spacing: Style.marginM

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
    NText {
        text: "ROG Control Center"
        color: Color.mSecondary

        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    RowLayout {
        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
        NIcon {
            icon: "barrier-block"
            pointSize: Style.fontSizeL
            color: Color.mTertiary
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
        NToggle {
            Layout.fillWidth: true
            // TODO: enable once implemented
            enabled: false
            label: root.pluginApi.tr("settings.rogcc.listenToNotifications.label")
            description: root.pluginApi.tr("settings.rogcc.listenToNotifications.description")
            checked: root.pluginSettings.rogcc.listenToNotifications
            onToggled: checked => root.pluginSettings.rogcc.listenToNotifications = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
        NText {
            text: "supergfxctl"
            color: Color.mSecondary
            Layout.topMargin: Style.marginM
            Layout.bottomMargin: Style.marginM
        }

        NDivider {
            Layout.fillWidth: true
        }
    }

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
    NToggle {
        Layout.fillWidth: true
        label: root.pluginApi.tr("settings.supergfxctl.patchPending.label")
        description: root.pluginApi.tr("settings.supergfxctl.patchPending.description")
        checked: root.pluginSettings.supergfxctl.patchPending
        onToggled: checked => root.pluginSettings.supergfxctl.patchPending = checked
    }

    RowLayout {
        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
        NIcon {
            icon: "flask"
            pointSize: Style.fontSizeL
            color: Color.mTertiary
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
        NToggle {
            Layout.fillWidth: true
            label: root.pluginApi.tr("settings.supergfxctl.polling.label")
            description: root.pluginApi.tr("settings.supergfxctl.polling.description")
            checked: root.pluginSettings.supergfxctl.polling
            onToggled: checked => root.pluginSettings.supergfxctl.polling = checked
        }
    }

    NValueSlider {
        isSettings: true
        text: root.pluginSettings.supergfxctl.pollingInterval + "ms"
        enabled: root.pluginSettings.supergfxctl.polling
        from: 1000
        to: 5000
        stepSize: 250
        value: root.pluginSettings.supergfxctl.pollingInterval
        onMoved: value => root.pluginSettings.supergfxctl.pollingInterval = value
    }

    RowLayout {
        Layout.fillWidth: true

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
        NText {
            text: "Miscellaneous"
            color: Color.mSecondary
            Layout.topMargin: Style.marginM
            Layout.bottomMargin: Style.marginM
        }

        NDivider {
            Layout.fillWidth: true
        }
    }

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
    NToggle {
        Layout.fillWidth: true
        label: root.pluginApi.tr("settings.debug.label")
        description: root.pluginApi.tr("settings.debug.description")
        checked: root.pluginSettings.debug
        onToggled: checked => root.pluginSettings.debug = checked
    }

    // This function is called by noctalia dialog
    function saveSettings(): void {
        if (!root.pluginSettings) {
            return console.error("supergfxctl", "[Settings]: plugin core (Main.qml) is not loaded");
        }

        if (!root.pluginApi) {
            return console.error("supergfxctl", "[Settings]: cannot save settings: pluginApi is null");
        }

        // TODO: move to pluginCore.pluginSettings
        root.pluginApi.pluginSettings = {
            debug: root.pluginSettings.debug,
            rogcc: {
                listenToNotifications: root.pluginSettings.rogcc.listenToNotifications
            },
            supergfxctl: {
                patchPending: root.pluginSettings.supergfxctl.patchPending,
                polling: root.pluginSettings.supergfxctl.polling,
                pollingInterval: root.pluginSettings.supergfxctl.pollingInterval
            }
        };

        // Persist to disk
        root.pluginApi.saveSettings();

        root.pluginCore?.log("saved settings");
    }
}
