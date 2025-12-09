/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
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

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string density: Settings.data.bar.density
    readonly property bool isBarVertical: {
        let pos = Settings.data.bar.position;
        return pos === "left" || pos === "right";
    }

    readonly property var supergfxctl: pluginApi.mainInstance

    property var currentMode: supergfxctl.modeInfo(supergfxctl.mode)

    property string tooltipText: {
        if (!root.supergfxctl.available)
            return "";
        if (!supergfxctl.hasPendingAction)
            return currentMode.label;
        return currentMode.label + " | " + supergfxctl.actionInfo(supergfxctl.pendingAction).label;
    }

    property real availabilityOpacity: supergfxctl.available ? 1.0 : 0.5

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill
        opacity: root.availabilityOpacity
        screen: root.screen
        density: root.density
        oppositeDirection: BarService.getPillDirection(root)
        icon: root.currentMode.icon
        autoHide: false
        forceOpen: !root.isBarVertical
        forceClose: root.isBarVertical
        tooltipText: root.tooltipText

        onClicked: root.pluginApi.openPanel(root.screen)

        onRightClicked: {
            var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
            if (popupMenuWindow) {
                popupMenuWindow.showContextMenu(contextMenu);
                const pos = BarService.getContextMenuPosition(pill, contextMenu.implicitWidth, contextMenu.implicitHeight);
                contextMenu.openAtItem(pill, pos.x, pos.y);
            }
        }

        Rectangle {
            id: badge
            visible: root.supergfxctl.hasPendingAction
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 2
            anchors.topMargin: 1
            z: 2
            height: 8
            width: height
            radius: Style.radiusXS
            color: Color.mError
            border.color: Color.mSurface
            border.width: Style.borderS
        }
    }

    NPopupContextMenu {
        id: contextMenu
        model: {
            let items = [];

            items.push({
                "label": "Current: " + root.currentMode.label,
                "action": "current",
                "icon": root.currentMode.icon,
                "enabled": false
            });

            items.push({
                "label": pluginApi.tr("context-menu.refresh"),
                "action": "refresh",
                "icon": "refresh"
            });

            items.push({
                // "label": I18n.tr("context-menu.widget-settings"),
                "label": "Access settings in the control center",
                "action": "widget-settings",
                "icon": "settings",
                "enabled": false
            });

            return items;
        }

        onTriggered: action => {
            var popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.close();
            }

            switch (action) {
            case "widget-settings":
                // this doesnt work
                // BarService.openWidgetSettings(root.screen, root.section, root.sectionWidgetIndex, root.widgetId);
                break;
            case "refresh":
                root.supergfxctl.refresh();
                break;
            }
        }
    }
}
