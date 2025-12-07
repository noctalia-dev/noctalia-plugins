# Noctalia Plugins Registry

Official plugin registry for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell).

## Overview

This repository hosts community and official plugins for Noctalia Shell. The `registry.json` file is automatically maintained and provides a centralized index of all available plugins.

## Plugin Structure

Each plugin must have the following structure:

```
plugin-name/
├── manifest.json      # Plugin metadata (required)
├── Main.qml           # Main component for IPCTarget or general logic (optional)
├── BarWidget.qml      # Bar widget component (optional)
├── Panel.qml          # Panel component (optional)
├── Settings.qml       # Settings UI (optional)
├── preview.png        # Preview image used noctalia's website
└── README.md          # Plugin documentation
```

### manifest.json

Every plugin must include a `manifest.json` file with the following fields:

```json
{
  "id": "plugin-id",
  "name": "Plugin Name",
  "version": "1.0.0",
  "minNoctaliaVersion": "3.6.0",
  "author": "Your Name",
  "license": "MIT",
  "repository": "https://github.com/noctalia-dev/noctalia-plugins",
  "description": "Brief plugin description",
  "entryPoints": {
    "main": "Main.qml",
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml",
    "settings": "Settings.qml"
  },
  "dependencies": {
    "plugins": []
  },
  "metadata": {
    "defaultSettings": {}
  }
}
```

## Adding a Plugin

1. **Fork this repository**

2. **Create your plugin directory**
   ```bash
   mkdir your-plugin-name
   cd your-plugin-name
   ```

3. **Create manifest.json** with all required fields

4. **Implement your plugin** using QML components

5. **Test your plugin** with Noctalia Shell

6. **Submit a pull request**
   - The `registry.json` will be automatically updated by GitHub Actions
   - Ensure your manifest.json is valid and complete

## Registry Automation

The plugin registry is automatically maintained using GitHub Actions:

- **Automatic Updates**: Registry updates when manifest.json files are modified
- **PR Validation**: Pull requests show if registry will be updated

See [.github/workflows/README.md](.github/workflows/README.md) for technical details.

## Available Plugins

Check [registry.json](registry.json) for the complete list of available plugins.

## Development

```bash
# Update registry manually
node .github/workflows/update-registry.js
```

## License

MIT - See individual plugin licenses in their respective directories.
