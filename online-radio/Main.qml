import QtQuick
import Quickshell.Io
import qs.Commons
Item {
    id: root
    property var pluginApi: null
    
    // Basic properties for playback control
    property string currentPlayingStation: ""
    property string currentPlayingProcessState: ""
    
    // FileView for working with a JSON file
    FileView {
        id: jsonFile
        path: pluginApi.pluginSettings.stations_json
        blockLoading: false
        
        onTextChanged: {
            if (jsonFile.text()) {
                try {
                    var jsonData = JSON.parse(jsonFile.text());
                    
                    // Saving the current playing station before cleaning
                    var savedStation = currentPlayingStation || "";
                    var savedState = currentPlayingProcessState || "";
                    
                    // Clearing the previous data
                    for (var key in pluginApi.pluginSettings) {
                        if (key.startsWith("station_")) {
                            delete pluginApi.pluginSettings[key];
                        }
                    }
                    
                    // Saving each station as station_X_name and station_X_url
                    if (Array.isArray(jsonData)) {
                        for (var i = 0; i < jsonData.length; i++) {
                            var station = jsonData[i];
                            pluginApi.pluginSettings["station_" + i + "_name"] = station.name || "";
                            pluginApi.pluginSettings["station_" + i + "_url"] = station.url || "";
                        }
                        // Saving the number of stations
                        pluginApi.pluginSettings.station_count = jsonData.length;
                    }
                    
                    // Restoring the current station, if it still exists
                    var stationStillExists = false;
                    if (savedStation && Array.isArray(jsonData)) {
                        for (var j = 0; j < jsonData.length; j++) {
                            if (jsonData[j].name === savedStation) {
                                stationStillExists = true;
                                break;
                            }
                        }
                    }
                    
                    if (!stationStillExists) {
                        currentPlayingStation = "";
                        currentPlayingProcessState = "";
                        pluginApi.pluginSettings.currentPlayingStation = "";
                        pluginApi.pluginSettings.currentPlayingProcessState = "";
                    }
                    
                    pluginApi.saveSettings();
                    
                } catch(error) {
                    console.error("JSON parse error:", error);
                }
            }
        }
    }
    
    Component.onCompleted: {
        // Restoring the state from the settings
        if (pluginApi && pluginApi.pluginSettings) {
            currentPlayingStation = pluginApi.pluginSettings.currentPlayingStation || "";
            currentPlayingProcessState = pluginApi.pluginSettings.currentPlayingProcessState || "";
        }
        
        if (!jsonFile.text()) {
            jsonFile.reload();
        }
    }
    
    // Function to start the station
    function playStation(stationName, stationUrl) {
        // Stopping the current playback
        stopPlayback();
        
        // Saving the state
        currentPlayingStation = stationName;
        currentPlayingProcessState = "start";
        
        if (pluginApi) {
            pluginApi.pluginSettings.currentPlayingStation = stationName;
            pluginApi.pluginSettings.currentPlayingProcessState = "start";
            pluginApi.saveSettings();
        }
        
        var process = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
        process.command = ["sh", "-c", "cvlc --no-video --play-and-exit '" + stationUrl.replace(/'/g, "'\"'\"'") + "'"];
        
        process.exited.connect(function() {
            if (root.currentPlayingStation === stationName) {
                root.stopPlayback();
            }
            process.destroy();
        });
        process.startDetached();
    }
    
    // Function to stop playback
    function stopPlayback() {
        // Killing all VLC processes
        var killProcess = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
        killProcess.command = ["sh", "-c", "kill -9 $(ps aux | grep -E '[c]vlc|[v]lc' | awk '{print $2}') 2>/dev/null || true"];
        
        killProcess.exited.connect(function() {
            killProcess.destroy();
        });
        
        killProcess.startDetached();
        
        // Clearing the state
        currentPlayingStation = "";
        currentPlayingProcessState = "";
        
        if (pluginApi) {
            pluginApi.pluginSettings.currentPlayingStation = "";
            pluginApi.pluginSettings.currentPlayingProcessState = "";
            pluginApi.saveSettings();
        }
    }
    
    // Function for getting a list of stations
    function getStations() {
        var stations = [];
        
        if (pluginApi && pluginApi.pluginSettings) {
            var settings = pluginApi.pluginSettings;
            
            var i = 0;
            while (true) {
                var nameKey = "station_" + i + "_name";
                var urlKey = "station_" + i + "_url";
                
                if (settings.hasOwnProperty(nameKey) && settings.hasOwnProperty(urlKey)) {
                    var name = settings[nameKey];
                    var url = settings[urlKey];
                    
                    if (name && url) {
                        stations.push({
                            index: i,
                            name: name,
                            url: url
                        });
                    }
                    i++;
                } else {
                    break;
                }
            }
        }
        
        return stations;
    }
}

