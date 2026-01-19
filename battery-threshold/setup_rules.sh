#!/usr/bin/env bash

# ------------------------------
# Battery Threshold Udev Setup
# ------------------------------
# This script sets up udev rules to allow a non-root user to write to
# /sys/class/power_supply/BAT0/charge_control_end_threshold.
# It creates a group 'battery_ctl' and adds the target user to this group.
#
# Usage:
#  $ sudo ./setup_rules.sh        # uses SUDO_USER (with sudo)
#  $ ./setup_rules.sh username    # use provided username (if ran as root)
# ------------------------------
set -e

RULE_FILE="99-battery-threshold.rules"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
	echo "Error: This script must be run as root (use sudo)"
	exit 1
fi

# Determine target user
TARGET_USER=${SUDO_USER:-$1}

if [ -z "$TARGET_USER" ]; then
	echo "Error: No target user specified." >&2
	exit 1
fi

if [ ! -f "$RULE_FILE" ]; then
	echo "Error: $RULE_FILE not found in current directory" >&2
	exit 1
fi

if ! getent group battery_ctl >/dev/null; then
	echo "Creating battery_ctl group..."
	groupadd battery_ctl
fi

echo "Adding $TARGET_USER to battery_ctl group..."
usermod -aG battery_ctl "$TARGET_USER"

echo "Installing $RULE_FILE"

cp "$RULE_FILE" /etc/udev/rules.d/

echo "Reloading rules..."

udevadm control --reload-rules && udevadm trigger

echo "You may need a reboot for the plugin's write access to take effect"
echo "Done!"

