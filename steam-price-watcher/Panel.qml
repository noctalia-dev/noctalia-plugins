import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Plugin API (injected by PluginPanelSlot)
  property var pluginApi: null
  
  // SmartPanel properties
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 500 * Style.uiScaleRatio
  property real contentPreferredHeight: 500 * Style.uiScaleRatio
  readonly property bool allowAttach: true
  
  anchors.fill: parent

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Local state
  property var watchlist: cfg.watchlist || defaults.watchlist || []
  property var gamesWithPrices: []
  property bool loading: false
  property string currency: cfg.currency || defaults.currency || "br"
  property string currencySymbol: cfg.currencySymbol || defaults.currencySymbol || "R$"

  onWatchlistChanged: {
    if (watchlist.length > 0 && gamesWithPrices.length === 0) {
      gamesWithPrices = watchlist.slice();
      Qt.callLater(refreshPrices);
    }
  }

  Component.onCompleted: {
    // Initialize with watchlist data
    if (watchlist.length > 0) {
      gamesWithPrices = watchlist.slice();
      Qt.callLater(refreshPrices);
    }
  }

  function refreshPrices() {
    if (watchlist.length === 0) {
      loading = false;
      return;
    }
    
    loading = true;
    // Don't clear the list, just update prices
    if (gamesWithPrices.length === 0) {
      gamesWithPrices = watchlist.slice();
    }
    
    for (var i = 0; i < watchlist.length; i++) {
      fetchGamePrice(watchlist[i]);
    }
  }

  property int pendingFetches: 0

  Component {
    id: priceProcessComponent
    Process {
      property var gameData: null
      property string gameAppId: ""
      running: false
      command: ["curl", "-s", "https://store.steampowered.com/api/appdetails?appids=" + gameAppId + "&cc=" + root.currency]
      stdout: StdioCollector {}
      
      onExited: (exitCode) => {
        if (exitCode === 0) {
          try {
            var response = JSON.parse(stdout.text);
            var appData = response[gameAppId];
            if (appData && appData.success && appData.data) {
              var priceData = appData.data.price_overview;
              if (priceData) {
                gameData.currentPrice = priceData.final / 100;
                gameData.currency = priceData.currency;
                gameData.discountPercent = priceData.discount_percent || 0;
                root.addGameWithPrice(gameData);
              } else {
                gameData.currentPrice = 0;
                gameData.currency = "BRL";
                gameData.error = "Preço não disponível";
                root.addGameWithPrice(gameData);
              }
            }
          } catch (e) {
            console.error("Error parsing Steam API response:", e);
            gameData.error = "Erro ao buscar preço";
            root.addGameWithPrice(gameData);
          }
        }
        
        root.pendingFetches--;
        if (root.pendingFetches === 0) {
          root.loading = false;
        }
        
        destroy();
      }
    }
  }

  function fetchGamePrice(game) {
    pendingFetches++;
    
    var process = priceProcessComponent.createObject(root, {
      gameData: game,
      gameAppId: game.appId.toString()
    });
    process.running = true;
  }

  function addGameWithPrice(game) {
    var temp = gamesWithPrices.slice();
    var found = false;
    
    // Update existing game or add new one
    for (var i = 0; i < temp.length; i++) {
      if (temp[i].appId === game.appId) {
        temp[i] = game;
        found = true;
        break;
      }
    }
    
    if (!found) {
      temp.push(game);
    }
    
    // Sort: games at target price first, then others
    temp.sort(function(a, b) {
      var aAtTarget = a.currentPrice && a.currentPrice <= a.targetPrice;
      var bAtTarget = b.currentPrice && b.currentPrice <= b.targetPrice;
      
      if (aAtTarget && !bAtTarget) return -1;
      if (!aAtTarget && bAtTarget) return 1;
      return 0;
    });
    
    gamesWithPrices = temp;
  }

  function removeGame(appId) {
    var temp = [];
    for (var i = 0; i < watchlist.length; i++) {
      if (watchlist[i].appId !== appId) {
        temp.push(watchlist[i]);
      }
    }
    
    if (pluginApi && pluginApi.pluginSettings) {
      pluginApi.pluginSettings.watchlist = temp;
      
      // Remover jogo da lista de notificados
      var notifiedGames = pluginApi.pluginSettings.notifiedGames || [];
      var notifiedTemp = [];
      for (var j = 0; j < notifiedGames.length; j++) {
        if (notifiedGames[j] !== appId) {
          notifiedTemp.push(notifiedGames[j]);
        }
      }
      pluginApi.pluginSettings.notifiedGames = notifiedTemp;
      
      pluginApi.saveSettings();
      
      // Atualizar a lista local
      root.watchlist = temp;
      root.gamesWithPrices = temp.slice();
      
      console.log("Steam Price Watcher: Removed game", appId, "and cleared from notifications");
    }
    
    refreshPrices();
  }

  function updateTargetPrice(appId, newPrice) {
    if (pluginApi && pluginApi.pluginSettings) {
      for (var i = 0; i < pluginApi.pluginSettings.watchlist.length; i++) {
        if (pluginApi.pluginSettings.watchlist[i].appId === appId) {
          pluginApi.pluginSettings.watchlist[i].targetPrice = newPrice;
          break;
        }
      }
      pluginApi.saveSettings();
      console.log("Steam Price Watcher: Updated target price for", appId, "to", newPrice);
      
      // Remove from notified games to allow re-notification
      var notified = pluginApi.pluginSettings.notifiedGames || [];
      var newNotified = [];
      for (var j = 0; j < notified.length; j++) {
        if (notified[j] !== appId) {
          newNotified.push(notified[j]);
        }
      }
      pluginApi.pluginSettings.notifiedGames = newNotified;
      pluginApi.saveSettings();
      
      refreshPrices();
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      // Header
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: headerContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NIcon {
              icon: "package"
              pointSize: Style.fontSizeXXL
              color: Color.mPrimary
            }

            NText {
              text: "Steam Price Watcher"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NIconButton {
              icon: "refresh"
              tooltipText: pluginApi?.tr("steam-price-watcher.refresh") || "Atualizar preços"
              baseSize: Style.baseWidgetSize * 0.8
              enabled: !loading
              onClicked: refreshPrices()
            }
          }
        }
      }

      // Games list
      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
          id: gamesListView
          model: root.gamesWithPrices
          spacing: Style.marginM

          header: ColumnLayout {
            width: gamesListView.width
            spacing: Style.marginS

            NText {
              Layout.fillWidth: true
              Layout.margins: Style.marginM
              text: root.loading ? 
                (pluginApi?.tr("steam-price-watcher.loading-prices") || "Carregando preços...") :
                root.watchlist.length === 0 ?
                  (pluginApi?.tr("steam-price-watcher.no-games-message") || "Nenhum jogo na watchlist.\nAdicione jogos nas configurações.") :
                  `${root.gamesWithPrices.length} ${root.gamesWithPrices.length === 1 ? (pluginApi?.tr("steam-price-watcher.game") || "jogo") : (pluginApi?.tr("steam-price-watcher.games") || "jogos")}`
              color: Color.mOnSurface
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              horizontalAlignment: Text.AlignHCenter
            }

            // Section header for games at target price
            NText {
              Layout.fillWidth: true
              Layout.leftMargin: Style.marginM
              Layout.rightMargin: Style.marginM
              text: pluginApi?.tr("steam-price-watcher.on-target-section") || "🎯 Jogos no preço-alvo"
              color: Color.mPrimary
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              visible: root.gamesWithPrices.some(g => g.currentPrice && g.currentPrice <= g.targetPrice)
            }
          }

          delegate: ColumnLayout {
            required property var modelData
            required property int index

            width: gamesListView.width
            spacing: 0

            // Separator before first game not at target
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: separatorContent.implicitHeight + Style.marginM * 2
              visible: {
                if (index === 0) return false;
                var currentAtTarget = modelData.currentPrice && modelData.currentPrice <= modelData.targetPrice;
                var previousAtTarget = root.gamesWithPrices[index - 1].currentPrice && 
                                      root.gamesWithPrices[index - 1].currentPrice <= root.gamesWithPrices[index - 1].targetPrice;
                return previousAtTarget && !currentAtTarget;
              }

              ColumnLayout {
                id: separatorContent
                anchors.fill: parent
                spacing: Style.marginS

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 1
                  Layout.leftMargin: Style.marginM
                  Layout.rightMargin: Style.marginM
                  color: Color.mOutline
                }

                NText {
                  Layout.fillWidth: true
                  Layout.leftMargin: Style.marginM
                  Layout.rightMargin: Style.marginM
                  text: pluginApi?.tr("steam-price-watcher.monitoring-section") || "👀 Monitorando"
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeM
                  font.weight: Style.fontWeightBold
                }
              }
            }

            // Game card
            NBox {
              Layout.fillWidth: true
              implicitHeight: gameContent.implicitHeight + Style.marginM * 2
              color: Color.mSurfaceVariant
              border.color: modelData.currentPrice && modelData.currentPrice <= modelData.targetPrice ? 
                Color.mPrimary : "transparent"
              border.width: modelData.currentPrice && modelData.currentPrice <= modelData.targetPrice ? 2 : 0

              RowLayout {
                id: gameContent
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

              // Game image
              Rectangle {
                Layout.preferredWidth: 184 * Style.uiScaleRatio * 0.8
                Layout.preferredHeight: 69 * Style.uiScaleRatio * 0.8
                Layout.alignment: Qt.AlignTop
                color: Color.mSurface
                radius: Style.iRadiusS
                border.color: Color.mOutline
                border.width: 1
                
                Image {
                  anchors.fill: parent
                  anchors.margins: 1
                  source: `https://cdn.cloudflare.steamstatic.com/steam/apps/${modelData.appId}/capsule_184x69.jpg`
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  
                  Rectangle {
                    anchors.fill: parent
                    color: Color.mSurface
                    visible: parent.status === Image.Loading || parent.status === Image.Error
                    radius: Style.iRadiusS
                    
                    NIcon {
                      anchors.centerIn: parent
                      icon: "gamepad"
                      color: Color.mOnSurfaceVariant
                      pointSize: 24
                    }
                  }
                }
              }

              // Game info
              ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.marginXS

                // Name and actions
                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  NText {
                    text: modelData.name
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeL
                    font.weight: Style.fontWeightBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                  }

                  RowLayout {
                    spacing: Style.marginXS

                    NIconButton {
                      icon: "pencil"
                      tooltipText: pluginApi?.tr("steam-price-watcher.edit-price") || "Edit"
                      baseSize: Style.baseWidgetSize * 0.7
                      colorBg: Color.mSurface
                      colorFg: Color.mOnSurface
                      onClicked: editPriceDialog.open(modelData)
                    }

                    NIconButton {
                      icon: "trash"
                      tooltipText: pluginApi?.tr("steam-price-watcher.remove") || "Remover"
                      baseSize: Style.baseWidgetSize * 0.7
                      colorBg: Color.mError
                      colorFg: Color.mOnError
                      onClicked: removeGame(modelData.appId)
                    }
                  }
                }

                NText {
                  text: modelData.addedDate ? 
                    `📅 ${new Date(modelData.addedDate).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' })}` :
                    `🔢 App ID: ${modelData.appId}`
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeXS
                  opacity: 0.8
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 1
                  color: Color.mOutline
                  opacity: 0.3
                }

                // Prices in grid
                GridLayout {
                  Layout.fillWidth: true
                  columns: 3
                  columnSpacing: Style.marginL
                  rowSpacing: Style.marginXS

                  // Preço alvo
                  NText {
                    text: pluginApi?.tr("steam-price-watcher.target-price") || "🎯 Target:"
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightMedium
                  }

                  NText {
                    text: `${root.currencySymbol} ${modelData.targetPrice.toFixed(2)}`
                    color: Color.mPrimary
                    pointSize: Style.fontSizeXL
                    font.weight: Style.fontWeightBold
                  }

                  Item { Layout.fillWidth: true }

                  // Preço atual
                  NText {
                    text: pluginApi?.tr("steam-price-watcher.current-price") || "💰 Current:"
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightMedium
                  }

                  ColumnLayout {
                    spacing: 2

                    NText {
                      text: modelData.error ? modelData.error : 
                        modelData.currentPrice !== undefined ? 
                          `${root.currencySymbol} ${modelData.currentPrice.toFixed(2)}` :
                          "..."
                      color: modelData.error ? Color.mError : Color.mOnSurface
                      pointSize: Style.fontSizeXL
                      font.weight: Style.fontWeightBold
                    }

                    RowLayout {
                      spacing: Style.marginS
                      visible: modelData.currentPrice !== undefined && !modelData.error

                      // Diferença em relação ao alvo
                      NText {
                        text: {
                          if (modelData.currentPrice <= modelData.targetPrice) {
                            var saved = ((modelData.targetPrice - modelData.currentPrice) / modelData.targetPrice * 100).toFixed(0)
                            var belowText = pluginApi?.tr("steam-price-watcher.below-target") || "below target";
                            var targetReachedText = pluginApi?.tr("steam-price-watcher.target-reached") || "✓ Target reached";
                            return saved > 0 ? `↓ ${saved}% ${belowText}` : targetReachedText
                          } else {
                            var above = ((modelData.currentPrice - modelData.targetPrice) / modelData.targetPrice * 100).toFixed(0)
                            var aboveText = pluginApi?.tr("steam-price-watcher.above-target") || "above";
                            return `↑ ${above}% ${aboveText}`
                          }
                        }
                        color: modelData.currentPrice <= modelData.targetPrice ? Color.mPrimary : Color.mError
                        pointSize: Style.fontSizeXS
                        font.weight: Style.fontWeightMedium
                      }

                      // Desconto da Steam
                      Rectangle {
                        visible: (modelData.discountPercent && modelData.discountPercent > 0) ? true : false
                        Layout.preferredWidth: steamDiscountText.implicitWidth + Style.marginS
                        Layout.preferredHeight: steamDiscountText.implicitHeight + 2
                        radius: Style.iRadiusS
                        color: Color.mError

                        NText {
                          id: steamDiscountText
                          anchors.centerIn: parent
                          text: `-${modelData.discountPercent}%`
                          color: Color.mOnError
                          pointSize: Style.fontSizeXS
                          font.weight: Style.fontWeightBold
                        }
                      }
                    }
                  }

                  Item { Layout.fillWidth: true }
                }
              }
            }
          }
        }
      }
    }
  }
  }

  // Edit Price Dialog
  Popup {
    id: editPriceDialog
    anchors.centerIn: parent
    width: 350 * Style.uiScaleRatio
    height: contentItem.implicitHeight + Style.marginL * 2
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var gameData: null

    function open(game) {
      gameData = game;
      newPriceInput.text = game.targetPrice.toFixed(2);
      visible = true;
    }

    background: Rectangle {
      color: Color.mSurface
      radius: Style.iRadiusL
      border.color: Color.mOutline
      border.width: Style.borderM
    }

    contentItem: ColumnLayout {
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("steam-price-watcher.edit-target-price") || "Editar Preço-Alvo"
        color: Color.mOnSurface
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
      }

      NText {
        text: editPriceDialog.gameData ? editPriceDialog.gameData.name : ""
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: root.currencySymbol
          color: Color.mOnSurface
          pointSize: Style.fontSizeM
        }

        NTextInput {
          id: newPriceInput
          Layout.fillWidth: true
          Layout.preferredHeight: Style.baseWidgetSize
          text: "0.00"
          
          property var numberValidator: DoubleValidator {
            bottom: 0
            decimals: 2
            notation: DoubleValidator.StandardNotation
          }
          
          Component.onCompleted: {
            if (inputItem) {
              inputItem.validator = numberValidator;
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Item { Layout.fillWidth: true }

        NButton {
          text: pluginApi?.tr("steam-price-watcher.cancel") || "Cancelar"
          onClicked: editPriceDialog.close()
        }

        NButton {
          text: pluginApi?.tr("steam-price-watcher.save") || "Salvar"
          onClicked: {
            var newPrice = parseFloat(newPriceInput.text);
            if (!isNaN(newPrice) && newPrice > 0) {
              updateTargetPrice(editPriceDialog.gameData.appId, newPrice);
              editPriceDialog.close();
            }
          }
        }
      }
    }
  }
}
