import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 700

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string valueFromCurrency: cfg.fromCurrency || defaults.fromCurrency || "USD"
  property string valueToCurrency: cfg.toCurrency || defaults.toCurrency || "BRL"
  property int valueUpdateInterval: cfg.updateInterval ?? defaults.updateInterval ?? 30
  property string valueDisplayMode: cfg.displayMode || defaults.displayMode || "both"

  function saveSettings() {
    if (!pluginApi) {
      console.error("Currency Converter: Cannot save settings - pluginApi is null");
      return;
    }
    
    // Modify settings directly on pluginApi.pluginSettings
    pluginApi.pluginSettings.fromCurrency = valueFromCurrency;
    pluginApi.pluginSettings.toCurrency = valueToCurrency;
    pluginApi.pluginSettings.updateInterval = valueUpdateInterval;
    pluginApi.pluginSettings.displayMode = valueDisplayMode;
    
    // Call saveSettings without parameters
    pluginApi.saveSettings();
    console.log("Currency Converter: Settings saved successfully");
  }

  property var currencies: [
    "USD", "EUR", "BRL", "GBP", "JPY", "CNY", "CAD", "AUD",
    "CHF", "INR", "MXN", "ARS", "CLP", "COP", "PEN", "UYU"
  ]

  property var currencyNames: ({
    "USD": "Dólar Americano (USD)",
    "EUR": "Euro (EUR)",
    "BRL": "Real Brasileiro (BRL)",
    "GBP": "Libra Esterlina (GBP)",
    "JPY": "Iene Japonês (JPY)",
    "CNY": "Yuan Chinês (CNY)",
    "CAD": "Dólar Canadense (CAD)",
    "AUD": "Dólar Australiano (AUD)",
    "CHF": "Franco Suíço (CHF)",
    "INR": "Rúpia Indiana (INR)",
    "MXN": "Peso Mexicano (MXN)",
    "ARS": "Peso Argentino (ARS)",
    "CLP": "Peso Chileno (CLP)",
    "COP": "Peso Colombiano (COP)",
    "PEN": "Sol Peruano (PEN)",
    "UYU": "Peso Uruguaio (UYU)"
  })

  property var currencyModel: {
    var model = [];
    for (var i = 0; i < currencies.length; i++) {
      model.push({
        "key": currencies[i],
        "name": currencyNames[currencies[i]] || currencies[i]
      });
    }
    return model;
  }

  Text {
    text: "Configurações do Conversor de Moedas"
    font.pointSize: 14
    font.weight: Font.Bold
    color: "#FFFFFF"
    Layout.fillWidth: true
  }

  NComboBox {
    label: "Moeda de Origem"
    description: "Selecione a moeda de origem para conversão"
    Layout.fillWidth: true
    model: currencyModel
    currentKey: valueFromCurrency
    onSelected: key => {
      valueFromCurrency = key;
    }
  }

  NComboBox {
    label: "Moeda de Destino"
    description: "Selecione a moeda de destino para conversão"
    Layout.fillWidth: true
    model: currencyModel
    currentKey: valueToCurrency
    onSelected: key => {
      valueToCurrency = key;
    }
  }

  NSpinBox {
    label: "Intervalo de Atualização"
    description: "Intervalo em minutos para atualizar as taxas de câmbio"
    Layout.fillWidth: true
    from: 5
    to: 1440
    stepSize: 5
    value: valueUpdateInterval
    suffix: " min"
    onValueChanged: valueUpdateInterval = value
  }

  NComboBox {
    label: "Modo de Exibição"
    description: "Como exibir o widget na barra"
    Layout.fillWidth: true
    model: [
      {
        "key": "both",
        "name": "Ícone e Texto"
      },
      {
        "key": "icon",
        "name": "Apenas Ícone"
      },
      {
        "key": "text",
        "name": "Apenas Texto"
      }
    ]
    currentKey: valueDisplayMode
    onSelected: key => {
      valueDisplayMode = key;
    }
  }

  Item {
    Layout.fillHeight: true
  }
}

