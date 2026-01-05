import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen

   
    property string currentIconName: pluginApi?.pluginSettings?.currentIconName || pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName
    property string currentPlayingStation: pluginApi?.pluginSettings?.currentPlayingStation

    readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
    readonly property string displayMode: "auto"

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill

        screen: root.screen
        density: Settings.data.bar.density
        oppositeDirection: BarService.getPillDirection(root)
        icon: root.currentIconName
        text: currentPlayingStation === "" ? pluginApi?.tr("notSelected") : [pluginApi?.tr("nowPlay"), currentPlayingStation].join(" ")
        autoHide: false
        forceOpen: false
        forceClose: false
        tooltipText: "Radio"
        
        onClicked: {
            pluginApi.openPanel(screen);
        }
    }
}