/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
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

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    // SmartPanel properties (required for panel behavior)
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property real contentPreferredWidth: 450 * Style.uiScaleRatio
    readonly property real contentPreferredHeight: 180 * Style.uiScaleRatio

    readonly property bool available: pluginCore?.available ?? false
    readonly property bool busy: pluginCore?.busy ?? false

    readonly property string currentIcon: pluginCore?.getModeIcon(pluginCore?.mode) ?? ""
    readonly property string currentLabel: pluginCore?.getModeLabel(pluginCore?.mode) ?? ""

    readonly property int pendingAction: pluginCore?.pendingAction ?? Main.SGFXAction.Nothing
    readonly property int pendingMode: pluginCore?.pendingMode ?? Main.SGFXMode.None

    anchors.fill: parent

    component GPUButton: Rectangle {
        id: gpuButton

        required property int mode

        readonly property bool _current: mode === root.pluginCore?.mode
        readonly property bool _pending: mode === root.pluginCore?.pendingMode
        readonly property bool _supported: root.pluginCore?.isModeSupported(mode) ?? false

        readonly property bool _hovered: mouse.hovered
        readonly property string text: root.pluginCore?.getModeLabel(mode) ?? ""
        readonly property string icon: root.pluginCore?.getModeIcon(mode) ?? ""

        readonly property bool _enabled: {
            const available = root.available && !root.busy;
            return available && _supported;
        }

        readonly property bool _interactive: {
            // make sure that we can only switch back to current mode
            // this is useful because it allows us to "cancel"
            // the switch
            // TODO: investigate how supergfxctl behaves after switching back and
            // forth without performing necessary steps (pending action) to apply the mode switch
            const active = _current && root.pluginCore.pendingMode === Main.SGFXMode.None;

            return _enabled && !_pending && !active;
        }

        readonly property color textColor: {
            // instead of using _enabled
            // retain text color if busy
            // lower opacity will signal the button is currently disabled
            if (!root.available || !_supported) {
                return Color.mOutline;
            }

            if (_hovered) {
                return Color.mTertiary;
            }

            if (_pending) {
                return Color.mOnTertiary;
            }

            if (_current) {
                return Color.mOnPrimary;
            }

            return Color.mPrimary;
        }

        readonly property color backgroundColor: {
            // retain background color if busy
            // opacity will signal the button is currently disabled
            if (!root.available || !_supported) {
                return Qt.lighter(Color.mSurfaceVariant, 1.2);
            }

            if (_hovered) {
                return Color.transparent;
            }

            if (_current) {
                return Color.mPrimary;
            }

            if (_pending) {
                return Color.mTertiary;
            }

            // non-current default
            return Color.transparent;
        }

        readonly property color borderColor: {
            if (!_enabled) {
                return Color.mOutline;
            }

            if (_pending || _hovered) {
                return Color.mTertiary;
            }

            return Color.mPrimary;
        }

        readonly property ColorAnimation animationBehaviour: ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        Layout.fillWidth: true
        implicitWidth: contentRow.implicitWidth + (Style.marginL * 2)
        implicitHeight: contentRow.implicitHeight + (Style.marginL * 2)

        radius: Style.iRadiusS
        color: backgroundColor
        border.width: Style.borderM
        border.color: borderColor

        opacity: _enabled ? 1.0 : 0.6

        Behavior on color {
            animation: gpuButton.animationBehaviour
        }

        Behavior on border.color {
            animation: gpuButton.animationBehaviour
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
                    animation: gpuButton.animationBehaviour
                }
            }

            NText {
                text: gpuButton.text
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: gpuButton.textColor

                Behavior on color {
                    animation: gpuButton.animationBehaviour
                }
            }
        }

        TapHandler {
            enabled: gpuButton._interactive
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.pluginCore?.setMode(gpuButton.mode)
        }

        HoverHandler {
            id: mouse
            enabled: gpuButton._interactive
            cursorShape: Qt.PointingHandCursor
        }
    }

    component Header: NBox {
        id: header

        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

        readonly property string _pendingActionIcon: root.pluginCore?.getActionIcon(root.pendingAction) ?? ""
        readonly property string _pendingActionLabel: root.pluginCore?.getActionLabel(root.pendingAction) ?? ""
        readonly property string _label: root.pluginApi?.tr("gpu") ?? ""

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NIcon {
                icon: root.currentIcon
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            NText {
                text: header._label
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
                Layout.fillWidth: true
            }

            NIcon {
                icon: header._pendingActionIcon
                // baseSize: Style.baseWidgetSize * 0.8
                color: Color.mTertiary
                // tooltipText: header._pendingActionLabel
                visible: root.pluginCore?.hasPendingAction ?? false
            }

            NIconButton {
                id: refreshButton
                icon: "refresh"
                tooltipText: I18n.tr("tooltips.refresh")
                baseSize: Style.baseWidgetSize * 0.8
                enabled: root.available && !root.busy
                onClicked: root.pluginCore?.refresh()

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
                onClicked: root.pluginApi?.withCurrentScreen(screen => {
                    root.pluginApi?.closePanel(screen);
                })
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.transparent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM

            Header {}

            RowLayout {
                Layout.fillWidth: true
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
