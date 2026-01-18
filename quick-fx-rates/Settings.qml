import QtQuick
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

  property string valueDefaultSourceCurrency: cfg.defaultSourceCurrency || defaults.defaultSourceCurrency || ""
  property string valueDefaultTargetCurrency: cfg.defaultTargetCurrency || defaults.defaultTargetCurrency || "USD"

  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.defaultSourceCurrency = valueDefaultSourceCurrency;
    pluginApi.pluginSettings.defaultTargetCurrency = valueDefaultTargetCurrency;
    pluginApi.saveSettings();
  }

  property var currencies: [
    "AUD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR",
    "GBP", "HKD", "HUF", "IDR", "ILS", "INR", "ISK", "JPY",
    "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON",
    "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
  ]

  property var currencyNames: ({
    "AUD": "Australian Dollar (AUD)",
    "BRL": "Brazilian Real (BRL)",
    "CAD": "Canadian Dollar (CAD)",
    "CHF": "Swiss Franc (CHF)",
    "CNY": "Chinese Renminbi Yuan (CNY)",
    "CZK": "Czech Koruna (CZK)",
    "DKK": "Danish Krone (DKK)",
    "EUR": "Euro (EUR)",
    "GBP": "British Pound (GBP)",
    "HKD": "Hong Kong Dollar (HKD)",
    "HUF": "Hungarian Forint (HUF)",
    "IDR": "Indonesian Rupiah (IDR)",
    "ILS": "Israeli New Shekel (ILS)",
    "INR": "Indian Rupee (INR)",
    "ISK": "Icelandic Króna (ISK)",
    "JPY": "Japanese Yen (JPY)",
    "KRW": "South Korean Won (KRW)",
    "MXN": "Mexican Peso (MXN)",
    "MYR": "Malaysian Ringgit (MYR)",
    "NOK": "Norwegian Krone (NOK)",
    "NZD": "New Zealand Dollar (NZD)",
    "PHP": "Philippine Peso (PHP)",
    "PLN": "Polish Złoty (PLN)",
    "RON": "Romanian Leu (RON)",
    "SEK": "Swedish Krona (SEK)",
    "SGD": "Singapore Dollar (SGD)",
    "THB": "Thai Baht (THB)",
    "TRY": "Turkish Lira (TRY)",
    "USD": "United States Dollar (USD)",
    "ZAR": "South African Rand (ZAR)"
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

  property var sourceCurrencyModel: {
    var model = [{ "key": "", "name": "None (disabled)" }];
    for (var i = 0; i < currencies.length; i++) {
      model.push({
        "key": currencies[i],
        "name": currencyNames[currencies[i]] || currencies[i]
      });
    }
    return model;
  }

  Text {
    text: "Quick FX Rates Settings"
    font.pointSize: 14
    font.weight: Font.Bold
    color: "#FFFFFF"
    Layout.fillWidth: true
  }

  NComboBox {
    label: "Default Source Currency"
    description: "If set, >fx 100 converts from this currency. Leave as None to require specifying currency."
    Layout.fillWidth: true
    model: sourceCurrencyModel
    currentKey: valueDefaultSourceCurrency
    onSelected: key => {
      valueDefaultSourceCurrency = key;
    }
  }

  NComboBox {
    label: "Default Target Currency"
    description: "Currency to convert to when only one currency is specified (e.g., >fx 100 PLN)"
    Layout.fillWidth: true
    model: currencyModel
    currentKey: valueDefaultTargetCurrency
    onSelected: key => {
      valueDefaultTargetCurrency = key;
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
