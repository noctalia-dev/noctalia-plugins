[![noctalia-supergfxctl](./preview.png)](https://github.com/cod3ddot/noctalia-supergfxctl)

# noctalia-supergfxctl

Minimum noctalia version: `3.7.5`

Brings GPU control to your noctalia shell.  
Available modes are detected automatically. Current mode is highlighted in the main color, pending mode will be in tertiary.

This plugin attempts to guess the action the user needs to take (generally one of logout/reboot/nothing) after mode switch. It is unknown whether supergfxctl reports reliable information after the switch, be it the current mode or the pending action needed to get to that mode. In the future, proposed actions will be customizable. For now, DO NOT rely on the plugin's proposed action.

Made possible by [supergfxctl](https://gitlab.com/asus-linux/supergfxctl).  
Thanks [asusctl](https://gitlab.com/asus-linux/asusctl), [rog-control-center](https://gitlab.com/asus-linux/asusctl/-/tree/main/rog-control-center) for code inspiration.

## Quick development setup

Follow [plugin development overview](https://docs.noctalia.dev/development/plugins/overview/).

## Project Structure

```
├── LICENCES/               # REUSE licenses (See README)
├── i18n/					# Translations
├── src/
│   ├── Bar.qml				# Bar widget UI
│   ├── Main.qml			# Entrypoint, common logic
│   ├── Panel.qml			# Panel UI
│   └── Settings.qml        # Settings UI
├── CHANGES.md              # Changelog
├── COPYING                 # MIT (See README)
├── manifest.json           # https://docs.noctalia.dev/plugins/manifest/
└── README.md               # This file
```

## License

This project strives to be [REUSE](https://reuse.software/) compliant.

Generally:
- Documentation is under CC-BY-NC-SA-4.0
- Code is under MIT
- Config and translation files are under CC0-1.0

```
    noctalia-supergfxctl: GPU control with supergfxctl for noctalia
    Copyright (C) 2025 cod3ddot@proton.me
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
