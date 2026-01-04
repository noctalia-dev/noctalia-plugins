import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 280 * Style.uiScaleRatio
    property real contentPreferredHeight: 400 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusM
        
        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM
                
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Color.mSurfaceVariant
                    
                    NIcon {
                        anchors.centerIn: parent
                        icon: pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName
                        color: Color.mPrimary
                        width: 20
                        height: 20
                    }
                }
                
                ColumnLayout {
                    spacing: Style.marginXS
                    Layout.fillWidth: true
                    
                    NText {
                        text: pluginApi?.tr("radioList") || "Radio Stations"
                        color: Color.mOnSurface
                        font.pointSize: Style.fontSizeL
                        font.weight: Font.Bold
                    }
                    
                    NText {
                        text: pluginApi && pluginApi.mainInstance ? 
                              pluginApi.mainInstance.getStations().length + " " + pluginApi?.tr("available") : ""
                        color: Color.mOnSurfaceVariant
                        font.pointSize: Style.fontSizeS
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                border.width: Style.borderS
                border.color: Color.mOutline

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    contentWidth: width
                    contentHeight: column.implicitHeight
                    clip: true
                    
                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        policy: ScrollBar.AsNeeded
                        width: 6
                        contentItem: Rectangle {
                            implicitWidth: 6
                            implicitHeight: 100
                            radius: 3
                            color: Color.mOnSurfaceVariant
                            opacity: 0.5
                            
                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                        }
                        
                        background: Rectangle {
                            color: Color.transparent
                        }
                    }

                    Column {
                        id: column
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: pluginApi && pluginApi.mainInstance ? 
                                   pluginApi.mainInstance.getStations() : []

                            Rectangle {
                                id: stationButton
                                width: column.width
                                height: 56
                                color: {
                                    var isPlaying = (pluginApi && pluginApi.mainInstance &&
                                                    pluginApi.mainInstance.currentPlayingProcessState === "start" &&
                                                    pluginApi.mainInstance.currentPlayingStation === modelData.name);
                                    
                                    if (isPlaying) {
                                        return Color.mSurfaceVariant;
                                    } else if (mouseArea.containsPress) {
                                        return Qt.darker(Color.mSurface, 1.1);
                                    } else if (mouseArea.containsMouse) {
                                        return Qt.darker(Color.mSurface, 1.05);
                                    } else {
                                        return Color.mSurface;
                                    }
                                }
                                radius: Style.radiusS
                                border.width: Style.borderS
                                border.color: mouseArea.containsMouse ? Color.mOutline : Color.transparent

                                property string stationName: modelData.name
                                property string stationUrl: modelData.url

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Style.marginM
                                    spacing: Style.marginM

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: stationButton.isPlaying ? Color.mPrimary : Color.mSurface
                                        border.width: Style.borderS
                                        border.color: stationButton.isPlaying ? Color.mPrimary : Color.mOutline
                                        
                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: stationButton.isPlaying ? "player-play-filled" : "radio"
                                            color: stationButton.isPlaying ? Color.mOnPrimary : Color.mPrimary
                                            width: 16
                                            height: 16
                                        }
                                    }

                                    NText {
                                        text: modelData.name
                                        color: Color.mOnSurface
                                        font.pointSize: Style.fontSizeS
                                        font.weight: stationButton.isPlaying ? Font.Bold : Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: Color.transparent
                                        
                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: stationButton.isPlaying ? "player-play" : "activity"
                                            color: stationButton.isPlaying ? Color.mPrimary : Color.mOnSurfaceVariant
                                            width: stationButton.isPlaying ? 16 : 12
                                            height: stationButton.isPlaying ? 16 : 12
                                            opacity: stationButton.isPlaying ? 1 : 0.5
                                        }
                                    }
                                }

                                readonly property bool isPlaying: (pluginApi && pluginApi.mainInstance &&
                                                                  pluginApi.mainInstance.currentPlayingProcessState === "start" &&
                                                                  pluginApi.mainInstance.currentPlayingStation === modelData.name)

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (pluginApi && pluginApi.mainInstance) {
                                            var main = pluginApi.mainInstance;
                                            var isCurrentlyPlaying = (main.currentPlayingProcessState === "start" &&
                                                                     main.currentPlayingStation === stationName);
                                            
                                            if (isCurrentlyPlaying) {
                                                main.stopPlayback();
                                            } else {
                                                main.playStation(stationName, stationUrl);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: column.width
                            height: 120
                            visible: column.children.length === 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Style.marginM
                                
                                NIcon {
                                    icon: "radio"
                                    color: Color.mOnSurfaceVariant
                                    width: 48
                                    height: 48
                                    opacity: 0.5
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                NText {
                                    text: pluginApi?.tr("NotLoaded")
                                    color: Color.mOnSurfaceVariant
                                    font.pointSize: Style.fontSizeM
                                    font.weight: Font.Medium
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                NText {
                                    text: pluginApi?.tr("addStations")
                                    color: Color.mOnSurfaceVariant
                                    font.pointSize: Style.fontSizeS
                                    opacity: 0.7
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: currentPlayingContainer
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 60 : 0
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                border.width: Style.borderS
                border.color: Color.mOutline
                
                visible: pluginApi && pluginApi.mainInstance && 
                        pluginApi.mainInstance.currentPlayingProcessState === "start" && 
                        pluginApi.mainInstance.currentPlayingStation !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Color.mPrimary
                        
                        NIcon {
                            anchors.centerIn: parent
                            icon: "volume"
                            color: Color.mOnPrimary
                            width: 20
                            height: 20
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        
                        NText {
                            text: pluginApi?.tr("nowPlay")
                            color: Color.mOnSurfaceVariant
                            font.pointSize: Style.fontSizeXS
                            font.weight: Font.Medium
                            opacity: 0.8
                        }
                        
                        NText {
                            text: pluginApi && pluginApi.mainInstance ? 
                                  pluginApi.mainInstance.currentPlayingStation || "" : ""
                            color: Color.mOnSurface
                            font.pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: stopButton.containsPress ? Qt.darker(Color.mPrimary, 1.2) : 
                              stopButton.containsMouse ? Qt.darker(Color.mPrimary, 1.1) : 
                              Color.mPrimary

                        NIcon {
                            anchors.centerIn: parent
                            icon: "stop"
                            color: Color.mOnPrimary
                            width: 18
                            height: 18
                        }

                        MouseArea {
                            id: stopButton
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (pluginApi && pluginApi.mainInstance) {
                                    pluginApi.mainInstance.stopPlayback();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}