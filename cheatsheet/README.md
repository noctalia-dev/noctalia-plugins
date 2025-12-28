# Cheatsheet Plugin for Noctalia Shell

A dynamic keyboard shortcuts cheatsheet plugin for Noctalia Shell that displays Hyprland keybindings in a beautiful, organized interface.

## Features

- Automatically parses and displays keybindings from your Hyprland configuration
- Organized into categories for easy navigation
- Multi-column layout for optimal space usage
- Multi-language support (13 languages included)
- Color-coded keys for different modifier types
- Real-time updates

## Supported Languages

- English (en)
- Polish (pl)
- German (de)
- Spanish (es)
- French (fr)
- Italian (it)
- Japanese (ja)
- Dutch (nl)
- Portuguese (pt)
- Russian (ru)
- Turkish (tr)
- Ukrainian (uk-UA)
- Chinese Simplified (zh-CN)

## Installation

1. Copy the plugin folder to your Noctalia plugins directory:
   ```bash
   cp -r cheatsheet-noctalia-plugin ~/.config/noctalia/plugins/cheatsheet
   ```

2. Restart Noctalia Shell or reload plugins

3. The plugin will automatically read keybindings from `~/.config/hypr/keybind.conf`

## Configuration File Format

Your `keybind.conf` should use the following format for the plugin to parse correctly:

```bash
# 1. Window Management
bind = $mod, Q, killactive #"Close active window"
bind = $mod, F, fullscreen #"Toggle fullscreen"

# 2. Workspaces
bind = $mod, 1, workspace, 1 #"Switch to workspace 1"
```

- Categories are defined with `# NUMBER. CATEGORY_NAME`
- Keybindings must include a description in quotes after `#"`

## Requirements

- Noctalia Shell >= 3.6.0
- Hyprland window manager

## Author

**blacku**

## License

MIT License

## Version

1.0.0
