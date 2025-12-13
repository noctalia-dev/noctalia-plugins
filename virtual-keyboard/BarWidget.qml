import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets
import qs.Services.UI

NIconButton {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  icon: "keyboard"
  tooltipText: pluginApi?.tr("tooltip.toggle-button") || "Toggle Virtual Keyboard"
  tooltipDirection: BarService.getTooltipDirection()
  baseSize: Style.capsuleHeight
  applyUiScale: false
  density: Settings.data.bar.density
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  Process {
    id: resetScript
    command: ["qs", "-p", Quickshell.shellDir, "ipc", "call", "plugin:virtual-keyboard", "reset"]
  }

  onClicked: {
    if (pluginApi){
        pluginApi.pluginSettings.enabled = !pluginApi.pluginSettings.enabled;
        if (pluginApi.pluginSettings.enabled === false) {
          resetScript.running = true
        }
        pluginApi.saveSettings();
        Logger.i("Keyboard", "Virtual Keyboard Toggled");
    }
  }
}