#!/usr/bin/env bash

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

# -----------------------------------------------------
# Check for updates
# -----------------------------------------------------

# Arch
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
    if [[ $yay_installed == "true" ]] && [[ $paru_installed == "false" ]]; then
        aur_helper="yay"
    elif [[ $yay_installed == "false" ]] && [[ $paru_installed == "true" ]]; then
        aur_helper="paru"
    else
        aur_helper="yay"
    fi
    updates_aur=$($aur_helper -Qum | wc -l)
    updates_pacman=$(checkupdates | wc -l)
    updates=$((updates_aur+updates_pacman))

# Fedora
elif [[ $(_checkCommandExists "dnf") == 0 ]]; then
    updates=$(dnf check-update -q | grep -c ^[a-z0-9])
# Others
else
    updates=0
fi

printf "$updates"
