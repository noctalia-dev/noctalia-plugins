/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property var pluginApi: null

    // Required properties for bar widgets
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var pluginCore: pluginApi?.mainInstance

    readonly property string currentIcon: pluginCore?.getModeIcon(pluginCore.mode) ?? ""
    readonly property string currentLabel: pluginCore?.getModeLabel(pluginCore.mode) ?? ""
    readonly property real currentIconOpacity: pluginCore?.available ? 1.0 : 0.5

    readonly property string pendingActionLabel: pluginCore?.hasPendingAction ? pluginCore?.getActionLabel(pluginCore.pendingAction) : ""

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill
        opacity: root.currentIconOpacity
        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)
        icon: root.currentIcon
        autoHide: false
        tooltipText: {
            if (!root.pluginCore?.hasPendingAction) {
                return root.currentLabel;
            }
            return root.currentLabel + " | " + root.pendingActionLabel;
        }

        onClicked: root.pluginApi?.openPanel(root.screen)

        onRightClicked: {
            const popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.showContextMenu(contextMenu);
                contextMenu.openAtItem(pill, root.screen);
            }
        }

        Rectangle {
            id: badge
            visible: root.pluginCore?.hasPendingAction
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 2
            anchors.topMargin: 1
            z: 2
            height: 8
            width: 8
            radius: Style.radiusXS
            color: Color.mTertiary
            border.color: Color.mSurface
            border.width: Style.borderS
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": root.currentLabel,
                "action": "current",
                "icon": root.currentIcon,
                "enabled": false
            },
            {
                "label": root.pluginApi?.tr("context-menu.refresh"),
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": "Access settings in the control center",
                "action": "widget-settings",
                "icon": "settings",
                "enabled": false
            }
        ]

        onTriggered: action => {
            const popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.close();
                return;
            }

            switch (action) {
            case "refresh":
                root.pluginCore?.refresh();
                break;
            case "widget-settings":
                // unsupported for now
                break;
            }
        }
    }
}
