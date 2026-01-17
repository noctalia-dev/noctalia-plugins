import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  IpcHandler {
    target: "plugin:fx"
    function toggle() {
      pluginApi.withCurrentScreen(screen => {
        var launcherPanel = PanelService.getPanel("launcherPanel", screen);
        if (!launcherPanel)
          return;
        var searchText = launcherPanel.searchText || "";
        var isInFxMode = searchText.startsWith(">fx");
        if (!launcherPanel.isPanelOpen) {
          launcherPanel.open();
          launcherPanel.setSearchText(">fx ");
        } else if (isInFxMode) {
          launcherPanel.close();
        } else {
          launcherPanel.setSearchText(">fx ");
        }
      });
    }
  }
}
