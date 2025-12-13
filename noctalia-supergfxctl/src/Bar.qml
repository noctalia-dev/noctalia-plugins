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

    property var gpuApi: pluginApi?.mainInstance  // now equals sgfx wrapper

    readonly property string currentIcon: gpuApi.getModeIcon(gpuApi.mode)
    readonly property string currentLabel: gpuApi.getModeLabel(gpuApi.mode)
    readonly property real currentIconOpacity: gpuApi?.available ? 1.0 : 0.5

    readonly property string pendingActionLabel: {
        if (!gpuApi)
            return "";
        const info = gpuApi.actionInfo ? gpuApi.actionInfo(gpuApi.pendingAction) : null;
        return info?.label ?? "";
    }

    readonly property string tooltipText: {
        if (!gpuApi?.available)
            return "";
        if (!gpuApi?.hasPendingAction)
            return currentLabel;
        return currentLabel + " | " + pendingActionLabel;
    }

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill
        opacity: root.currentIconOpacity
        screen: root.screen
        density: root.density
        oppositeDirection: BarService.getPillDirection(root)
        icon: root.currentIcon
        autoHide: false
        tooltipText: root.tooltipText

        onClicked: root.pluginApi?.openPanel(root.screen)

        onRightClicked: {
            var popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.showContextMenu(contextMenu);
                const pos = BarService.getContextMenuPosition(pill, contextMenu.implicitWidth, contextMenu.implicitHeight);
                contextMenu.openAtItem(pill, pos.x, pos.y);
            }
        }

        Rectangle {
            id: badge
            visible: root.gpuApi?.hasPendingAction
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

        model: {
            let items = [];

            items.push({
                "label": "Current: " + root.currentLabel,
                "action": "current",
                "icon": root.currentIcon,
                "enabled": false
            });

            items.push({
                "label": root.pluginApi?.tr("context-menu.refresh"),
                "action": "refresh",
                "icon": "refresh"
            });

            items.push({
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
            case "refresh":
                root.gpuApi?.refresh();
                break;
            case "widget-settings":
                // unsupported for now
                break;
            }
        }
    }
}
