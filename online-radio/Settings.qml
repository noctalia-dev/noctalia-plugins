import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property string currentIconName: pluginApi?.pluginSettings?.currentIconName || 
                                     pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName

    spacing: Style.marginL

    property string stationNname: ""
    property string stationUrl: ""
    property string stationFile: "" 
    property int currentNumber: pluginApi?.pluginSettings?.station_count

    // Блок: Выбор иконки
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM
            
            // Заголовок
            NText {
                text: pluginApi?.tr("iconLabel")
                color: Color.mPrimary
                font.pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }
            
            NDivider {
                Layout.fillWidth: true
            }
            
            RowLayout {
                spacing: Style.marginL
                Layout.fillWidth: true
                
                NLabel {
                    description: pluginApi?.tr("iconDescription") 
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: Style.radiusS
                    color: Color.mSurface
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: root.currentIconName
                        color: Color.mPrimary
                        width: 24
                        height: 24
                    }
                }

                NText {
                    text: root.currentIconName
                    color: Color.mOnSurfaceVariant
                    font.pointSize: Style.fontSizeS
                }

                NButton {
                    text: pluginApi?.tr("changeIconButton")
                    onClicked: {
                        iconPicker.open();
                    }
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker
        onIconSelected: function (icon) {
            root.currentIconName = icon;
            saveSettings();
        }
    }

    // Блок: Выбор файла
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM
            
            NText {
                text: pluginApi?.tr("fileTitle")
                color: Color.mPrimary
                font.pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }
            
            NDivider {
                Layout.fillWidth: true
            }
            
            RowLayout {
                spacing: Style.marginL
                Layout.fillWidth: true
                
                NLabel {
                    description:  pluginApi?.tr("fileDescription")
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: Style.radiusS
                    color: Color.mSurface
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: "json"
                        color: Color.mPrimary
                        width: 24
                        height: 24
                    }
                }

                NText {
                    text: {
                        if (root.stationFile) {
                            var fileName = root.stationFile.split('/').pop();
                            return fileName.length > 20 ? fileName.substring(0, 20) + "..." : fileName;
                        }
                        return pluginApi?.tr("fileNotExist");
                    }
                    font.pointSize: Style.fontSizeS
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                NButton {
                    text: pluginApi?.tr("fileSelect")
                    onClicked: {
                        filePicker.openFilePicker();
                    }
                }
            }
        }
    }

    NFilePicker {
        id: filePicker
        title: pluginApi?.tr("fileSelectTitle")
        selectionMode: "files"
        nameFilters: ["*.json"]
        
        onAccepted: function(paths) {
            if (paths.length > 0) {
                root.stationFile = paths[0];
            }
        }
        
        onCancelled: {
            // Файл не выбран
        }
    }

    // Блок: Добавить станцию
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 250
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM
            
            // Заголовок
            NText {
                text: pluginApi?.tr("addTitle")
                color: Color.mPrimary
                font.pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }
            
            NDivider {
                Layout.fillWidth: true
            }
            
            ColumnLayout {
                spacing: Style.marginM
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                NTextInput {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    label: pluginApi?.tr("addNameLabel")
                    description: pluginApi?.tr("addNameDescription")
                    placeholderText: pluginApi?.tr("addNameHolder")
                    text: ""
                    onTextChanged: root.stationNname = text
                }

                NTextInput {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    label: pluginApi?.tr("addUrlLabel")
                    description: pluginApi?.tr("addUrlDescription")
                    placeholderText: pluginApi?.tr("addUrlHolder")
                    onTextChanged: root.stationUrl = text
                }
            }
        }
    }

    // Функция сохранения настроек
    function saveSettings() {
        if (!pluginApi) {
            return;
        }
        
        pluginApi.pluginSettings.currentIconName = root.currentIconName;

        var name = stationNname.trim();
        var url = stationUrl.trim();

        if (root.stationFile !== ""){
            pluginApi.pluginSettings["stations_json"] = root.stationFile;
        }
        
        if (name !== "" && url !== "") {
            pluginApi.pluginSettings.station_count = currentNumber + 1;
            pluginApi.pluginSettings["station_" + currentNumber + "_name"] = name;
            pluginApi.pluginSettings["station_" + currentNumber + "_url"] = url;
        }

        pluginApi.saveSettings();
        
        if (pluginApi.closePanel) {
            pluginApi.closePanel();
        }
    }
}