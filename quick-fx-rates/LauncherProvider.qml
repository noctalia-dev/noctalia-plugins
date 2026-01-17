import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  // Provider metadata
  property string name: "FX"
  property var launcher: null
  property bool handleSearch: false
  property string supportedLayouts: "list"
  property bool supportsAutoPaste: false

  // Icon mode (tabler vs native)
  property string iconMode: Settings.data.appLauncher.iconMode
  function icon(tablerName, nativeName) {
    return iconMode === "tabler" ? tablerName : nativeName;
  }

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property string defaultSourceCurrency: cfg.defaultSourceCurrency || defaults.defaultSourceCurrency || ""
  property string defaultTargetCurrency: cfg.defaultTargetCurrency || defaults.defaultTargetCurrency || "USD"

  // Rate cache
  property var cachedRates: ({})
  property string baseCurrency: "USD"
  property bool loading: false
  property bool loaded: false
  property real lastFetch: 0
  property int cacheMinutes: 5

  // Supported currencies (frankfurter.app)
  property var currencyNames: ({
    "AUD": "Australian Dollar",
    "BRL": "Brazilian Real",
    "CAD": "Canadian Dollar",
    "CHF": "Swiss Franc",
    "CNY": "Chinese Renminbi Yuan",
    "CZK": "Czech Koruna",
    "DKK": "Danish Krone",
    "EUR": "Euro",
    "GBP": "British Pound",
    "HKD": "Hong Kong Dollar",
    "HUF": "Hungarian Forint",
    "IDR": "Indonesian Rupiah",
    "ILS": "Israeli New Shekel",
    "INR": "Indian Rupee",
    "ISK": "Icelandic Króna",
    "JPY": "Japanese Yen",
    "KRW": "South Korean Won",
    "MXN": "Mexican Peso",
    "MYR": "Malaysian Ringgit",
    "NOK": "Norwegian Krone",
    "NZD": "New Zealand Dollar",
    "PHP": "Philippine Peso",
    "PLN": "Polish Złoty",
    "RON": "Romanian Leu",
    "SEK": "Swedish Krona",
    "SGD": "Singapore Dollar",
    "THB": "Thai Baht",
    "TRY": "Turkish Lira",
    "USD": "United States Dollar",
    "ZAR": "South African Rand"
  })

  function init() {
    if (!loading && !loaded) {
      fetchRates();
    }
  }

  // API call process
  Process {
    id: apiProcess
    running: false

    command: [
      "curl",
      "-s",
      "https://api.frankfurter.app/latest?from=USD"
    ]

    stdout: StdioCollector {}

    onExited: exitCode => {
      loading = false;
      if (exitCode === 0) {
        try {
          var response = JSON.parse(stdout.text);
          if (response.rates) {
            // Add USD to rates (it's the base)
            response.rates["USD"] = 1.0;
            cachedRates = response.rates;
            loaded = true;
            lastFetch = Date.now();
            Logger.i("FXLauncher", "Rates loaded:", Object.keys(cachedRates).length, "currencies");
            if (launcher) {
              launcher.updateResults();
            }
          }
        } catch (e) {
          Logger.e("FXLauncher", "Failed to parse rates:", e);
        }
      } else {
        Logger.e("FXLauncher", "Failed to fetch rates, exit code:", exitCode);
      }
    }
  }

  function fetchRates() {
    var now = Date.now();
    var cacheMs = cacheMinutes * 60 * 1000;

    if (loading) return;
    if (loaded && (now - lastFetch) < cacheMs) return;

    loading = true;
    apiProcess.running = true;
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">fx");
  }

  function commands() {
    return [{
      "name": ">fx",
      "description": "Quick currency conversion (e.g., >fx 100 USD EUR)",
      "icon": icon("cash", "accessories-calculator"),
      "isTablerIcon": iconMode === "tabler",
      "isImage": false,
      "onActivate": function() {
        launcher.setSearchText(">fx ");
      }
    }];
  }

  function getResults(searchText) {
    if (!searchText.startsWith(">fx")) {
      return [];
    }

    // Ensure rates are loaded
    fetchRates();

    if (loading && !loaded) {
      return [{
        "name": "Loading exchange rates...",
        "description": "Fetching from frankfurter.app",
        "icon": icon("refresh", "view-refresh"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    if (!loaded) {
      return [{
        "name": "Could not load rates",
        "description": "Click to retry",
        "icon": icon("alert-circle", "dialog-warning"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {
          loaded = false;
          fetchRates();
        }
      }];
    }

    var query = searchText.slice(3).trim().toUpperCase();

    if (query === "") {
      return getUsageHelp();
    }

    var parsed = parseQuery(query);
    if (!parsed) {
      return getUsageHelp();
    }

    // Handle invalid/unknown currency
    if (parsed.error) {
      return [{
        "name": parsed.error,
        "description": "Try a valid currency code (e.g., USD, EUR, PLN)",
        "icon": icon("alert-circle", "dialog-warning"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    return doConversion(parsed.amount, parsed.from, parsed.to);
  }

  function parseQuery(query) {
    // Normalize: split "100PLN" into "100 PLN"
    query = query.replace(/(\d)([A-Z])/g, "$1 $2");

    // Split and filter out empty parts and "TO" keyword
    var parts = query.split(/\s+/).filter(p => p.length > 0 && p !== "TO");

    if (parts.length === 0) {
      return null;
    }

    var amount = 1;
    var from = null;
    var to = defaultTargetCurrency;

    // Try to parse amount from first part
    var firstNum = parseFloat(parts[0]);
    var startIdx = 0;

    if (!isNaN(firstNum) && firstNum > 0) {
      amount = firstNum;
      startIdx = 1;
    }

    var currencies = parts.slice(startIdx);

    if (currencies.length === 0) {
      // No currency specified - use defaults if source is set
      if (defaultSourceCurrency && defaultSourceCurrency.length === 3) {
        from = defaultSourceCurrency;
        to = defaultTargetCurrency;
      } else {
        return null;
      }
    } else if (currencies.length === 1) {
      from = currencies[0];
      // If source equals default target, flip to EUR
      if (from === defaultTargetCurrency) {
        to = "EUR";
      }
    } else {
      from = currencies[0];
      to = currencies[1];
    }

    // Wait for complete currency codes (3 chars) before validating
    if (from.length < 3) {
      return null;
    }

    // Validate currencies
    if (!cachedRates[from]) {
      return { error: "Unknown currency: " + from };
    }
    if (to.length >= 3 && !cachedRates[to]) {
      return { error: "Unknown currency: " + to };
    }
    if (to.length < 3) {
      return null;
    }

    return { amount: amount, from: from, to: to };
  }

  function doConversion(amount, from, to) {
    // Convert through USD (base currency)
    var fromRate = cachedRates[from] || 1;
    var toRate = cachedRates[to] || 1;

    // Convert: amount in FROM -> USD -> TO
    var inUsd = amount / fromRate;
    var result = inUsd * toRate;

    var rate = toRate / fromRate;
    var resultStr = formatNumber(result);
    var rateStr = formatNumber(rate);

    var results = [];

    // Main result
    results.push({
      "name": amount + " " + from + " = " + resultStr + " " + to,
      "description": "Rate: 1 " + from + " = " + rateStr + " " + to + " | Click to copy",
      "icon": icon("cash", "accessories-calculator"),
      "isTablerIcon": iconMode === "tabler",
      "isImage": false,
      "onActivate": function() {
        copyToClipboard(resultStr);
        launcher.close();
      }
    });

    // Reverse conversion
    var reverseRate = fromRate / toRate;
    var reverseResult = amount / fromRate * toRate;
    results.push({
      "name": "1 " + to + " = " + formatNumber(reverseRate) + " " + from,
      "description": "Reverse rate | Click to copy",
      "icon": icon("arrows-exchange", "view-refresh"),
      "isTablerIcon": iconMode === "tabler",
      "isImage": false,
      "onActivate": function() {
        copyToClipboard(formatNumber(reverseRate));
        launcher.close();
      }
    });

    return results;
  }

  function formatNumber(num) {
    if (num >= 1000) {
      return num.toLocaleString('en-US', { maximumFractionDigits: 2 });
    } else if (num >= 1) {
      return num.toFixed(2);
    } else {
      return num.toFixed(4);
    }
  }

  function copyToClipboard(text) {
    var escaped = text.replace(/'/g, "'\\''");
    Quickshell.execDetached(["sh", "-c", "printf '%s' '" + escaped + "' | wl-copy"]);
  }

  function getUsageHelp() {
    return [
      {
        "name": ">fx 100 USD EUR",
        "description": "Convert 100 USD to EUR",
        "icon": icon("cash", "accessories-calculator"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {
          launcher.setSearchText(">fx 100 USD EUR");
        }
      },
      {
        "name": ">fx 50 BRL",
        "description": "Convert 50 BRL to USD (default)",
        "icon": icon("cash", "accessories-calculator"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {
          launcher.setSearchText(">fx 50 BRL");
        }
      },
      {
        "name": ">fx EUR GBP",
        "description": "Show rate for 1 EUR to GBP",
        "icon": icon("percentage", "accessories-calculator"),
        "isTablerIcon": iconMode === "tabler",
        "isImage": false,
        "onActivate": function() {
          launcher.setSearchText(">fx EUR GBP");
        }
      }
    ];
  }
}
