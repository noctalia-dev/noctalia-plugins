import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
  id: root
  spacing: 0

  property var pluginApi: null

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Settings values
  property int windowWidth: cfg.windowWidth ?? defaults.windowWidth ?? 1400
  property int windowHeight: cfg.windowHeight ?? defaults.windowHeight ?? 0
  property bool autoHeight: cfg.autoHeight ?? defaults.autoHeight ?? true
  property int columnCount: cfg.columnCount ?? defaults.columnCount ?? 3
  // NOWA ZMIENNA TUTAJ:
  property string modKeyVariable: cfg.modKeyVariable || defaults.modKeyVariable || "$mod"
  property string hyprlandConfigPath: cfg.hyprlandConfigPath || defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf"
  property string niriConfigPath: cfg.niriConfigPath || defaults.niriConfigPath || "~/.config/niri/config.kdl"

  NScrollView {
    id: scrollView
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    ColumnLayout {
      id: contentColumn
      width: scrollView.width
      spacing: Style.marginM

      // Header
      NText {
        text: pluginApi?.tr("keybind-cheatsheet.settings.title") || "Keybind Cheatsheet Settings"
        pointSize: Style.fontSizeXXL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NText {
        text: pluginApi?.tr("keybind-cheatsheet.settings.description") ||
          "Configure the appearance and keybind sources for the cheatsheet panel."
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      // Window Size Settings
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: sizeContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: sizeContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.window-size") || "Window Size"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          // Width setting
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("keybind-cheatsheet.settings.width") || "Width:"
              color: Color.mOnSurface
              pointSize: Style.fontSizeM
              Layout.preferredWidth: 120
            }

            NTextInput {
              id: widthInput
              Layout.preferredWidth: 100 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              text: windowWidth.toString()

              onTextChanged: {
                var val = parseInt(text);
                if (!isNaN(val) && val >= 400 && val <= 3000) {
                  if (pluginApi && pluginApi.pluginSettings) {
                    pluginApi.pluginSettings.windowWidth = val;
                  }
                }
              }
            }

            NText {
              text: "px (400-3000)"
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
            }
          }

          // Height setting
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("keybind-cheatsheet.settings.height") || "Height:"
              color: Color.mOnSurface
              pointSize: Style.fontSizeM
              Layout.preferredWidth: 120
            }

            NToggle {
              id: autoHeightToggle
              label: "Auto"
              checked: root.autoHeight
              onToggled: function(checked) {
                root.autoHeight = checked;
                if (pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.autoHeight = checked;
                }
              }
            }

            NTextInput {
              id: heightInput
              Layout.preferredWidth: 100 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              text: windowHeight > 0 ? windowHeight.toString() : "850"
              enabled: !autoHeightToggle.checked
              opacity: enabled ? 1.0 : 0.5

              onTextChanged: {
                var val = parseInt(text);
                if (!isNaN(val) && val >= 300 && val <= 2000) {
                  if (pluginApi && pluginApi.pluginSettings) {
                    pluginApi.pluginSettings.windowHeight = val;
                  }
                }
              }
            }

            NText {
              text: "px (300-2000)"
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              opacity: autoHeightToggle.checked ? 0.5 : 1.0
            }
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.auto-height-hint") ||
              "When 'Auto' is enabled, height adjusts automatically based on content."
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }
      }

      // Column Count Settings
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: columnContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: columnContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.layout") || "Layout"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("keybind-cheatsheet.settings.columns") || "Number of columns:"
              color: Color.mOnSurface
              pointSize: Style.fontSizeM
            }

            NComboBox {
              id: columnCombo
              Layout.preferredWidth: 150 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              model: ListModel {
                ListElement { name: "1"; key: "1" }
                ListElement { name: "2"; key: "2" }
                ListElement { name: "3"; key: "3" }
                ListElement { name: "4"; key: "4" }
              }
              currentKey: columnCount.toString()
              onSelected: key => {
                if (pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.columnCount = parseInt(key);
                }
              }
            }
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.columns-hint") ||
              "More columns work better with wider windows."
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }
      }

      // Config File Paths & Parsing
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: pathsContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: pathsContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.config-paths") || "Configuration Files"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.config-paths-description") ||
              "Specify custom paths and variables for your keybinds."
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
          
          // NOWA SEKCJA: Mod Variable Setting
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            RowLayout {
                spacing: Style.marginS
                NIcon {
                    icon: "keyboard"
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurface
                }
                NText {
                    text: pluginApi?.tr("keybind-cheatsheet.settings.mod-var") || "Mod Key Variable"
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightBold
                }
            }

            NTextInput {
                id: modVarInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: modKeyVariable
                placeholderText: "$mod"

                onTextChanged: {
                    if (text.length > 0 && pluginApi && pluginApi.pluginSettings) {
                        pluginApi.pluginSettings.modKeyVariable = text;
                    }
                }
            }
            
            NText {
                text: pluginApi?.tr("keybind-cheatsheet.settings.mod-var-hint") || 
                    "The variable name used for your Super key (e.g., $mod or $mainMod)."
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Color.mOutline
            opacity: 0.3
          }

          // Hyprland path
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              NIcon {
                icon: "terminal"
                pointSize: Style.fontSizeM
                color: Color.mPrimary
              }
              NText {
                text: "Hyprland Path"
                color: Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: hyprlandPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: hyprlandConfigPath
              placeholderText: "~/.config/hypr/hyprland.conf"

              onTextChanged: {
                if (text.length > 0 && pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.hyprlandConfigPath = text;
                }
              }
            }

            NText {
              text: pluginApi?.tr("keybind-cheatsheet.settings.hyprland-format-hint") ||
                "Expected format: bind = $mod, KEY, action #\"description\""
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Color.mOutline
            opacity: 0.3
          }

          // Niri path
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              NIcon {
                icon: "layout"
                pointSize: Style.fontSizeM
                color: Color.mSecondary
              }
              NText {
                text: "Niri Path"
                color: Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: niriPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: niriConfigPath
              placeholderText: "~/.config/niri/config.kdl"

              onTextChanged: {
                if (text.length > 0 && pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.niriConfigPath = text;
                }
              }
            }

            NText {
              text: pluginApi?.tr("keybind-cheatsheet.settings.niri-format-hint") ||
                "The plugin will find and parse the 'binds { }' block automatically."
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }
        }
      }

      // Reset and Refresh buttons
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: actionsContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: actionsContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.actions") || "Actions"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NButton {
              text: pluginApi?.tr("keybind-cheatsheet.settings.refresh-keybinds") || "Refresh Keybinds"
              icon: "refresh"
              onClicked: {
                if (pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.cheatsheetData = [];
                  pluginApi.pluginSettings.detectedCompositor = "";
                  pluginApi.saveSettings();
                  ToastService.showNotice(
                    pluginApi?.tr("keybind-cheatsheet.settings.refresh-message") ||
                    "Keybinds will be reloaded when you open the panel."
                  );
                }
              }
            }

            NButton {
              text: pluginApi?.tr("keybind-cheatsheet.settings.reset-defaults") || "Reset to Defaults"
              icon: "rotate"
              onClicked: {
                if (pluginApi && pluginApi.pluginSettings) {
                  pluginApi.pluginSettings.windowWidth = defaults.windowWidth || 1400;
                  pluginApi.pluginSettings.windowHeight = defaults.windowHeight || 0;
                  pluginApi.pluginSettings.autoHeight = defaults.autoHeight ?? true;
                  pluginApi.pluginSettings.columnCount = defaults.columnCount || 3;
                  // RESET DLA NOWEJ ZMIENNEJ:
                  pluginApi.pluginSettings.modKeyVariable = defaults.modKeyVariable || "$mod";
                  pluginApi.pluginSettings.hyprlandConfigPath = defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf";
                  pluginApi.pluginSettings.niriConfigPath = defaults.niriConfigPath || "~/.config/niri/config.kdl";
                  pluginApi.pluginSettings.cheatsheetData = [];
                  pluginApi.pluginSettings.detectedCompositor = "";
                  pluginApi.saveSettings();

                  // Update UI
                  widthInput.text = (defaults.windowWidth || 1400).toString();
                  heightInput.text = "850";
                  autoHeightToggle.checked = true;
                  columnCombo.currentKey = "3";
                  // AKTUALIZACJA UI DLA NOWEJ ZMIENNEJ:
                  modVarInput.text = defaults.modKeyVariable || "$mod";
                  hyprlandPathInput.text = defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf";
                  niriPathInput.text = defaults.niriConfigPath || "~/.config/niri/config.kdl";

                  ToastService.showNotice(
                    pluginApi?.tr("keybind-cheatsheet.settings.reset-message") ||
                    "Settings have been reset to defaults."
                  );
                }
              }
            }
          }
        }
      }

      // Keybind Command Info
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: keybindContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: keybindContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.keybind-setup") || "Keybind Setup"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.keybind-setup-description") ||
              "To open the cheatsheet with a keyboard shortcut, add this bind to your compositor config:"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: commandText.implicitHeight + Style.marginS * 2
            color: Color.mSurface
            radius: Style.radiusS

            NText {
              id: commandText
              anchors.fill: parent
              anchors.margins: Style.marginS
              text: "qs -c \"noctalia-shell\" ipc call \"keybind-cheatsheet\" \"toggle\""
              font.family: "monospace"
              pointSize: Style.fontSizeS
              color: Color.mPrimary
              wrapMode: Text.WrapAnywhere
            }
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.keybind-example-hyprland") ||
              "Hyprland example: bind = $mod, F1, exec, qs -c \"noctalia-shell\" ipc call \"keybind-cheatsheet\" \"toggle\""
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }

          NText {
            text: pluginApi?.tr("keybind-cheatsheet.settings.keybind-example-niri") ||
              "Niri example: Super+F1 { spawn \"qs\" \"-c\" \"noctalia-shell\" \"ipc\" \"call\" \"keybind-cheatsheet\" \"toggle\"; }"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }
      }

      // Bottom spacing
      Item {
        Layout.preferredHeight: Style.marginL
      }
    }
  }

  // Save function called by settings dialog
  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.saveSettings();
    ToastService.showNotice(
      pluginApi?.tr("keybind-cheatsheet.settings.saved") ||
      "Settings saved successfully."
    );
  }
}
