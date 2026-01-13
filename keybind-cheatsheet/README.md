# Keybind Cheatsheet for Noctalia

Universal keyboard shortcuts cheatsheet plugin for Noctalia that **automatically detects** your compositor (Hyprland or Niri) and displays your keybindings.

## Features

- **Automatic compositor detection** (Hyprland or Niri)
- **Dual parser support** - reads both config formats
- Smart categorization of keybindings
- Color-coded modifier keys (Super, Ctrl, Shift, Alt)
- Three-column balanced layout
- IPC support for global hotkey toggle
- Automatic refresh on config changes

## Supported Compositors

| Compositor | Config File | Format |
|------------|-------------|--------|
| **Hyprland** | `~/.config/hypr/keybind.conf` | Custom Hyprland format |
| **Niri** | `~/.config/niri/config.kdl` | KDL format |

## Installation

```bash
cp -r keybind-cheatsheet ~/.config/noctalia/plugins/
```

## Usage

### Bar Widget
Add the plugin to your bar configuration in Noctalia settings. The widget will automatically detect your compositor.

### Global Hotkey

#### For Hyprland
Add to your `~/.config/hypr/keybind.conf`:

```bash
bind = $mod, F1, exec, qs -c noctalia-shell ipc call plugin:keybind-cheatsheet toggle
```

#### For Niri
Add to your `~/.config/niri/config.kdl`:

```kdl
binds {
    Mod+F1 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:keybind-cheatsheet" "toggle"; }
}
```

### Manual Toggle
```bash
qs -c noctalia-shell ipc call plugin:keybind-cheatsheet toggle
```

## Config Format

### Hyprland Format

The plugin expects keybindings with descriptions in `#"..."` format:

```bash
# 1. APPLICATIONS
bind = $mod, T, exec, alacritty #"Terminal"
bind = $mod, B, exec, firefox #"Browser"

# 2. WINDOW MANAGEMENT
bind = $mod, Q, killactive, #"Close window"
bind = $mod, F, fullscreen, #"Toggle fullscreen"

# 3. WORKSPACES
bind = $mod, 1, workspace, 1 #"Switch to workspace 1"
bind = $mod SHIFT, 1, movetoworkspace, 1 #"Move window to workspace 1"
```

**Format requirements:**
- Categories must start with `# N.` where N is a number
- Keybind descriptions must be in `#"description"` at the end of the line
- Use `$mod` for Super key

### Niri Format

The plugin parses KDL config format from the `binds` block:

```kdl
binds {
    // Applications
    Mod+T { spawn "alacritty"; }
    Mod+B { spawn "firefox"; }

    // Window Management
    Mod+Q { close-window; }
    Mod+F { fullscreen-window; }

    // Navigation
    Mod+Left { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up { focus-window-up; }
    Mod+Down { focus-window-down; }

    // Workspaces
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }

    // Media Keys
    XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
    XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
}
```

**Format requirements:**
- Use `//` comments for custom category names
- Without comments, actions are auto-categorized by type
- Supports all Niri modifiers: `Mod`, `Super`, `Ctrl`, `Alt`, `Shift`

## Auto-Categorization (Niri)

When no comment category is provided, Niri keybindings are automatically grouped:

| Action prefix | Category |
|--------------|----------|
| `spawn` | Applications |
| `focus-column-*` | Column Navigation |
| `focus-window-*` | Window Focus |
| `focus-workspace-*` | Workspace Navigation |
| `move-column-*` | Move Columns |
| `move-window-*` | Move Windows |
| `close-window`, `fullscreen-window`, `consume-window`, `expel-window` | Window Management |
| `maximize-column` | Column Management |
| `set-column-width`, `switch-preset-column-width` | Column Width |
| `reset-window-height` | Window Size |
| `screenshot*` | Screenshots |
| `power-off-monitors` | Power |
| `quit` | System |
| `toggle-animation` | Animations |

## Compositor Detection

The plugin automatically detects your compositor using:

1. **Environment variables** (primary method):
   - Hyprland: `$HYPRLAND_INSTANCE_SIGNATURE`
   - Niri: `$NIRI_SOCKET`

2. **Process detection** (fallback):
   - Checks for running `hyprland` or `niri` processes

Detection happens on:
- Plugin initialization
- Panel open
- Manual IPC toggle

## Troubleshooting

### "No supported compositor detected"

**Solution:**
1. Verify your compositor is running: `pgrep -x hyprland` or `pgrep -x niri`
2. Check environment variables: `echo $HYPRLAND_INSTANCE_SIGNATURE` or `echo $NIRI_SOCKET`
3. Restart Noctalia shell

### "Cannot read config file"

**Hyprland:**
- Ensure `~/.config/hypr/keybind.conf` exists
- Check file permissions: `ls -la ~/.config/hypr/keybind.conf`

**Niri:**
- Ensure `~/.config/niri/config.kdl` exists
- Check file permissions: `ls -la ~/.config/niri/config.kdl`

### "No keybindings found"

**Hyprland:**
- Verify your keybinds have descriptions: `bind = $mod, T, exec, cmd #"Description"`
- Categories must start with `# 1.`, `# 2.`, etc.

**Niri:**
- Ensure keybinds are inside the `binds { }` block
- Check syntax: `Mod+Key { action; }`

## Requirements

- Noctalia Shell 3.6.0+
- One of the supported compositors:
  - Hyprland (any recent version)
  - Niri (v25.01+)

## License

MIT

## Credits

- Original Hyprland Cheatsheet concept
- Adapted to support multiple compositors with automatic detection
