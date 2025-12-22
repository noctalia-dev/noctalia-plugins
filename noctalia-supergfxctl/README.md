[![noctalia-supergfxctl](./preview.png)](https://github.com/cod3ddot/noctalia-supergfxctl)

# noctalia-supergfxctl

Minimum noctalia version: `3.6.0`

Brings supergfxctl control to your noctalia shell.  
Available modes are detected automatically. Current mode is highlighted in the main color, pending mode will be in tertiary.

Made possible by [supergfxctl](https://gitlab.com/asus-linux/supergfxctl).  
Thanks [asusctl](https://gitlab.com/asus-linux/asusctl), [rog-control-center](https://gitlab.com/asus-linux/asusctl/-/tree/main/rog-control-center) for code inspiration.

## Quick Setup

Follow [plugin development overview](https://docs.noctalia.dev/plugins/overview/).

## Project Structure

```
├── LICENCES/               # REUSE licenses (See README)
├── i18n/					# Translations
├── src/
│   ├── Bar.qml				# Bar widget ui
│   ├── Main.qml			# Entrypoint, common logic
│   ├── Panel.qml			# Panel ui
│   └── Settings.qml        # Settings ui
├── CHANGES.md              # Changelog
├── COPYING                 # AGPL-3.0-or-later (See README)
├── manifest.json           # https://docs.noctalia.dev/plugins/manifest/
└── README.md               # This file
```

## License

This project strives to be [REUSE](https://reuse.software/) compliant.

Generally:
- Documentation is under CC-BY-NC-SA-4.0
- Code is under AGPL-3.0-or-later
- Config files are under CC0-1.0

```
    noctalia-supergfxctl: GPU control with supergfxctl for noctalia
    Copyright (C) 2025 cod3ddot@proton.me

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
