import QtQuick
import Quickshell.Io
import qs.Commons
Item {
    id: root
    property var pluginApi: null
    
    // Основные свойства для управления воспроизведением
    property string currentPlayingStation: ""
    property string currentPlayingProcessState: "" // "start" или ""
    
    // FileView для работы с JSON файлом
    FileView {
        id: jsonFile
        path: pluginApi.pluginSettings.stations_json
        blockLoading: false
        
        onTextChanged: {
            if (jsonFile.text()) {
                try {
                    var jsonData = JSON.parse(jsonFile.text());
                    
                    // Сохраняем текущую играющую станцию перед очисткой
                    var savedStation = currentPlayingStation || "";
                    var savedState = currentPlayingProcessState || "";
                    
                    // Очищаем предыдущие данные
                    for (var key in pluginApi.pluginSettings) {
                        if (key.startsWith("station_")) {
                            delete pluginApi.pluginSettings[key];
                        }
                    }
                    
                    // Сохраняем каждую станцию как station_X_name и station_X_url
                    if (Array.isArray(jsonData)) {
                        for (var i = 0; i < jsonData.length; i++) {
                            var station = jsonData[i];
                            pluginApi.pluginSettings["station_" + i + "_name"] = station.name || "";
                            pluginApi.pluginSettings["station_" + i + "_url"] = station.url || "";
                        }
                        // Сохраняем количество станций
                        pluginApi.pluginSettings.station_count = jsonData.length;
                    }
                    
                    // Восстанавливаем текущую станцию, если она все еще существует
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
        // Восстанавливаем состояние из настроек
        if (pluginApi && pluginApi.pluginSettings) {
            currentPlayingStation = pluginApi.pluginSettings.currentPlayingStation || "";
            currentPlayingProcessState = pluginApi.pluginSettings.currentPlayingProcessState || "";
        }
        
        if (!jsonFile.text()) {
            jsonFile.reload();
        }
    }
    
    // Функция для запуска станции
    function playStation(stationName, stationUrl) {
        // Останавливаем текущее воспроизведение
        stopPlayback();
        
        // Сохраняем состояние
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
    
    // Функция для остановки воспроизведения
    function stopPlayback() {
        // Убиваем все процессы VLC
        var killProcess = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
        killProcess.command = ["sh", "-c", "kill -9 $(ps aux | grep -E '[c]vlc|[v]lc' | awk '{print $2}') 2>/dev/null || true"];
        
        killProcess.exited.connect(function() {
            killProcess.destroy();
        });
        
        killProcess.startDetached();
        
        // Очищаем состояние
        currentPlayingStation = "";
        currentPlayingProcessState = "";
        
        if (pluginApi) {
            pluginApi.pluginSettings.currentPlayingStation = "";
            pluginApi.pluginSettings.currentPlayingProcessState = "";
            pluginApi.saveSettings();
        }
    }
    
    // Функция для получения списка станций
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

