#!/bin/bash

# Check if command exists
_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

# Script to update pacman packages via paru and Flatpak packages

# Colors for output
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "\n\n${RESET}░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█░░░█░█░█▀█░█▀▄░█▀█░▀█▀░█▀▀
░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█░░░█░█░█▀▀░█░█░█▀█░░█░░█▀▀
░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░░░▀▀▀░▀░░░▀▀░░▀░▀░░▀░░▀▀▀${RESET}"

# Prompt the user for confirmation
if [[ $(_checkCommandExists "gum") == 0 ]]; then
    gum confirm "" || exit 1
else
    echo "gum is required to run the update script."
    read -r
fi

# Update pacman packages via paru
echo -e "${BLUE}\n░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█░░░█▀█░█▀█░█▀▀░█░█░█▀█░█▀▀░█▀▀░█▀▀
░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█░░░█▀▀░█▀█░█░░░█▀▄░█▀█░█░█░█▀▀░▀▀█
░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░░░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀▀▀\n${RESET}"
if [[ $(_checkCommandExists "pacman") == 0 ]]; then

    check_lock_files() {
        local pacman_lock="/var/lib/pacman/db.lck"
        local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"

        while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
            sleep 1
        done
    }

    check_lock_files

    yay_installed="false"
    paru_installed="false"
    if [[ $(_checkCommandExists "yay") == 0 ]]; then
        yay_installed="true"
    fi
    if [[ $(_checkCommandExists "paru") == 0 ]]; then
        paru_installed="true"
    fi
    if [[ $yay_installed == "true" ]]; then
        aur_helper="yay"
    elif [[ $paru_installed == "true" ]]; then
        aur_helper="paru"
    else
        aur_helper="none"
    fi

    if [[ $yay_installed == "true" ]] || [[ $paru_installed == "true" ]]; then
        echo -e "Looking for updates..."
        $aur_helper -Syu --noconfirm
    else
       	echo
        echo -e "${RED}Failed to update AUR packages. No AUR helper found.${RESET}"
    fi
fi

if [[ $(_checkCommandExists "dnf") == 0 ]]; then
    sudo dnf upgrade
    echo
elif [[ $(_checkCommandExists "xbps-install") == 0 ]]; then
    echo -e "${BLUE}░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█░░░█▀█░█▀█░█▀▀░█░█░█▀█░█▀▀░█▀▀░█▀▀
░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█░░░█▀▀░█▀█░█░░░█▀▄░█▀█░█░█░█▀▀░▀▀█
░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░░░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀▀▀\n${RESET}"
    sudo xbps-install -Su
    echo
else
    echo
fi

if [[ $(_checkCommandExists "flatpak") == 0 ]]; then
    echo -e "${BLUE}░█▀▀░█░░░█▀█░▀█▀░█▀█░█▀█░█░█░░░█▀█░█▀█░█▀▀░█░█░█▀▀
░█▀▀░█░░░█▀█░░█░░█▀▀░█▀█░█▀▄░░░█▀▀░█▀█░█░░░█▀▄░▀▀█
░▀░░░▀▀▀░▀░▀░░▀░░▀░░░▀░▀░▀░▀░░░▀░░░▀░▀░▀▀▀░▀░▀░▀▀▀${RESET}"
    # Update Flatpak packages
    echo
    if flatpak update -y; then
        echo -e ""
    else
        echo -e "${RED}Failed to update Flatpak packages.${RESET}"
        echo -e "\n Press any key to close"
        exit 1
    fi
fi
echo
echo -e "${GREEN}░█▀▀░█▀█░█▄█░█▀█░█░░░█▀▀░▀█▀░█▀▀░█▀▄
░█░░░█░█░█░█░█▀▀░█░░░█▀▀░░█░░█▀▀░█░█
░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀░░▀░░▀▀▀░▀▀░${RESET}"

echo -e "\nPress enter key to close"

read -r
