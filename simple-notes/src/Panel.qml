/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root

    property var pluginApi: null

    property var geometryPlaceholder: panelContainer
    property bool allowAttach: true

    readonly property real contentPreferredWidth: 450 * Style.uiScaleRatio
    readonly property real contentPreferredHeight: 180 * Style.uiScaleRatio

    anchors.fill: parent

    readonly property var gpuApi: pluginApi?.mainInstance
    readonly property bool available: gpuApi?.available ?? false
    readonly property bool busy: gpuApi?.busy ?? false

    readonly property string currentIcon: gpuApi.getModeIcon(gpuApi.mode)
    readonly property string currentLabel: gpuApi.getModeLabel(gpuApi.mode)

    readonly property int pendingAction: gpuApi.pendingAction
    readonly property int pendingMode: gpuApi.pendingMode

    component GPUButton: Rectangle {
        id: gpuButton

        property int mode

        readonly property bool isCurrentMode: mode === root.gpuApi.mode
        readonly property bool isPendingMode: mode === root.gpuApi.pendingMode
        readonly property bool isSupported: root.gpuApi.isModeSupported(mode)

        property string text: root.gpuApi.getModeLabel(mode)
        property string icon: root.gpuApi.getModeIcon(mode)
        property bool hovered: mouse.hovered

        // Not clickable when current or unsupported
        readonly property bool interactive: {
            if (root.busy) {
                return false;
            }

            if (!isSupported) {
                return false;
            }

            if (isPendingMode) {
                return false;
            }

            if (isCurrentMode && root.gpuApi.pendingMode === Main.SGFXMode.None) {
                return false;
            }

            return true;
        }

        readonly property color textColor: {
            if (!isSupported) {
                return Color.mOutline;
            }

            if (hovered) {
                return Color.mTertiary;
            }

            if (isPendingMode) {
                return Color.mOnTertiary;
            }

            if (isCurrentMode) {
                return Color.mOnPrimary;
            }

            return Color.mPrimary;
        }

        Layout.fillWidth: true
        implicitWidth: contentRow.implicitWidth + (Style.marginL * 2)
        implicitHeight: contentRow.implicitHeight + (Style.marginL * 2)

        radius: Style.iRadiusS

        color: {
            if (!isSupported) {
                return Qt.lighter(Color.mSurfaceVariant, 1.2);
            }

            if (hovered) {
                return Color.transparent;
            }

            if (isCurrentMode) {
                return Color.mPrimary;
            }

            if (isPendingMode) {
                return Color.mTertiary;
            }

            // non-current default
            return Color.transparent;
        }

        border.width: Style.borderM
        border.color: {
            if (!isSupported) {
                return Color.mOutline;
            }

            if (isPendingMode || hovered) {
                return Color.mTertiary;
            }

            return Color.mPrimary;
        }

        opacity: isSupported ? 1.0 : 0.6

        Behavior on color {
            ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            NIcon {
                icon: gpuButton.icon
                pointSize: Style.fontSizeL
                color: gpuButton.textColor

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            NText {
                text: gpuButton.text
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: gpuButton.textColor

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        TapHandler {
            enabled: gpuButton.interactive
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.gpuApi.setMode(gpuButton.mode)
        }

        HoverHandler {
            id: mouse
            enabled: gpuButton.interactive
            cursorShape: Qt.PointingHandCursor
        }
    }

    component Header: NBox {
        id: headerBox
        Layout.fillWidth: true
        Layout.preferredHeight: header.implicitHeight + Style.marginM * 2

        readonly property string pendingActionIcon: root.gpuApi.getActionIcon(root.pendingAction)
        readonly property string pendingActionLabel: root.gpuApi.getActionLabel(root.pendingAction)

        readonly property string label: root.pluginApi.tr("gpu")

        RowLayout {
            id: header
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NIcon {
                icon: root.currentIcon
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            NText {
                text: headerBox.label
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
                Layout.fillWidth: true
            }

            NIconButtonHot {
                icon: headerBox.pendingActionIcon
                baseSize: Style.baseWidgetSize * 0.8
                color: Color.mTertiary
                hot: true
                tooltipText: headerBox.pendingActionLabel
                visible: root.gpuApi.hasPendingAction
            }

            NIconButton {
                id: refreshButton
                icon: "refresh"
                tooltipText: I18n.tr("tooltips.refresh")
                baseSize: Style.baseWidgetSize * 0.8
                enabled: root.available && !root.busy
                onClicked: root.gpuApi.refresh()

                RotationAnimation {
                    id: rotationAnimator
                    target: refreshButton
                    property: "rotation"
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                    running: root.busy
                }
            }

            NIconButton {
                icon: "close"
                tooltipText: I18n.tr("tooltips.close")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.pluginApi.closePanel(root.screen)
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.transparent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL

            Header {}

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.marginM + 50
                spacing: Style.marginM

                GPUButton {
                    mode: Main.SGFXMode.Integrated
                }
                GPUButton {
                    mode: Main.SGFXMode.Hybrid
                }
                GPUButton {
                    mode: Main.SGFXMode.AsusMuxDgpu
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                GPUButton {
                    mode: Main.SGFXMode.AsusEgpu
                }
                GPUButton {
                    mode: Main.SGFXMode.Vfio
                }
            }
        }
    }
}
