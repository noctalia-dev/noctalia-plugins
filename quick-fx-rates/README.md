# Quick FX Rates

A plugin for quick currency conversion directly from the Noctalia launcher.

## Features

- **Quick Conversion**: Convert currencies without leaving the launcher
- **30+ Currencies**: Supports all major world currencies via frankfurter.app
- **Copy to Clipboard**: Click result to copy the converted amount
- **Rate Caching**: 5-minute cache to avoid excessive API calls

## Usage

1. Open the Noctalia launcher
2. Type `>fx` to enter currency mode
3. Enter your conversion query

### Examples

| Command | Result |
|---------|--------|
| `>fx 100 USD EUR` | Convert 100 USD to EUR |
| `>fx 50 BRL` | Convert 50 BRL to USD (default) |
| `>fx EUR GBP` | Show rate for 1 EUR to GBP |
| `>fx` | Show usage help |

## Supported Currencies

30 currencies supported via frankfurter.app:

AUD, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HKD, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR, NOK, NZD, PHP, PLN, RON, SEK, SGD, THB, TRY, USD, ZAR

## Requirements

- Noctalia 4.0.0 or later
- `curl` (for API requests)
- `wl-copy` (for clipboard support)

## Data Source

Exchange rates provided by [frankfurter.app](https://www.frankfurter.app/) (free, no API key required).
