# Privacy Indicator Plugin

A privacy indicator widget that monitors and displays when microphone, camera, or screen sharing is active on your system.

## Features

- **Microphone Monitoring**: Detects active microphone usage via Pipewire
- **Camera Monitoring**: Detects active camera usage by checking `/dev/video*` devices
- **Screen Sharing Detection**: Monitors screen sharing sessions via Pipewire
- **Visual Indicators**: Shows icons that change color based on active state
  - Active: Primary color
  - Inactive: Semi-transparent variant color
- **App Information**: Tooltip displays which applications are using each resource
- **Adaptive Layout**: Automatically adjusts layout for horizontal or vertical bar positions

## Usage

The widget displays three icons in the bar:
- **Microphone**: Shows when any app is using the microphone
- **Camera**: Shows when any app is accessing the camera
- **Screen Share**: Shows when screen sharing is active

Hover over the widget to see a tooltip listing which applications are using each resource.

## Requirements

- Noctalia Shell 3.6.0 or higher
- Pipewire (for microphone and screen sharing detection)
- Access to `/dev/video*` devices (for camera detection)

## Technical Details

- Updates privacy state every second
- Uses Pipewire API to monitor audio/video streams
- Checks `/proc/[0-9]*/fd/` for camera device access
- Detects screen sharing by analyzing Pipewire node properties and media class

