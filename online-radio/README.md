# Online Radio Plugin

A plugin for Noctalia Shell that provides online radio streaming functionality directly from the system bar.

## Dependencies

- **VLC Media Player**: Required for audio streaming playback. Install with:
  - Ubuntu/Debian: `sudo apt install vlc`
  - Fedora: `sudo dnf install vlc`
  - Arch: `sudo pacman -S vlc`
  - ALT: `sudo apt-get install vlc`


## JSON Format for Stations List

The plugin supports importing radio stations from a JSON file. The file should contain an array of station objects, each with `name` and `url` properties.

### Example JSON Format:
```json
[
  {
    "name": "Example Radio 1",
    "url": "http://example.com/radio1.mp3"
  },
  {
    "name": "Rock Classics",
    "url": "http://radio.example.com:8000/rock"
  }
]
```

## Components

- **BarWidget.qml**: Compact widget shown in the system bar
- **Panel.qml**: Expanded panel showing station list and playback controls
- **Main.qml**: Core logic for radio playback and station management
- **Settings.qml**: Configuration interface for customizing the plugin