#!/bin/bash
# update Mac software

usage() {
    echo "Usage: $0 [-b|--brew-only]"
    echo "  -b, --brew-only    Skip system software update, only run Homebrew updates"
    exit 1
}

printf "${0##*/} updates Mac system software,\n" 
printf "plus software and apps managed with Homebrew\n\n"

SKIP_SOFTWARE_UPDATE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--brew-only)
            SKIP_SOFTWARE_UPDATE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script is designed to run on macOS only." >&2
    exit 1
fi

echo "macOS detected,"

echo "Admin password needed once for system, cask, and App Store updates."
read -r -s -p "Password for $USER: " ADMIN_PASS
echo
sudo -k  # drop any cached credential so the typed password is actually verified
if ! printf '%s\n' "$ADMIN_PASS" | sudo -S -p '' -v 2>/dev/null; then
    echo "Error: incorrect password or $USER is not an admin." >&2
    exit 1
fi
# Refresh the sudo timestamp so long upgrades don't hit the 5-minute timeout
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ "$SKIP_SOFTWARE_UPDATE" = false ]; then
    echo "Checking for Mac system software updates ..."
    echo "  (use -b or --brew-only to skip)"
    current_major=$(sw_vers -productVersion | cut -d. -f1)
    # Emits "INSTALL<TAB>label" or "SKIP<TAB>label"; macOS items with a newer major version are skipped
    update_list=$(softwareupdate --list 2>/dev/null | awk -v cur="$current_major" '
        /^[[:space:]]*\* Label: / { label = $0; sub(/^[[:space:]]*\* Label: /, "", label); next }
        /Title: / && label != "" {
            action = "INSTALL"
            if ($0 ~ /Title: macOS/) {
                ver = $0; sub(/.*Version: /, "", ver); sub(/,.*/, "", ver)
                split(ver, v, ".")
                if (v[1] + 0 > cur + 0) action = "SKIP"
            }
            print action "\t" label
            label = ""
        }')

    labels=()
    while IFS=$'\t' read -r action label; do
        [ -z "$label" ] && continue
        if [ "$action" = "SKIP" ]; then
            echo "  Skipping major macOS upgrade: $label (install manually when ready)"
        else
            labels+=("$label")
        fi
    done <<< "$update_list"

    if [ ${#labels[@]} -eq 0 ]; then
        echo "No system software updates to install."
    else
        echo "Installing: ${labels[*]}"
        # Apple Silicon OS updates need volume-owner auth, which root alone doesn't satisfy
        if [ "$(uname -m)" = "arm64" ]; then
            printf '%s\n' "$ADMIN_PASS" | sudo softwareupdate --install "${labels[@]}" --user "$USER" --stdinpass
        else
            sudo softwareupdate --install "${labels[@]}"
        fi
    fi
else
    echo "Skipping system software update (-b/--brew-only flag used)"
fi
unset ADMIN_PASS

printf "\nUpgrading tools and apps (casks) tracked by homebrew ...\n"
if command -v brew >/dev/null; then
    echo "Homebrew found. Checking for brew packages to upgrade ..."
    brew update
    echo "Homebrew packages checked for upgrades:"
    brew list
    echo "Upgrading out-of-date packages ..."
    brew upgrade --yes
    echo "Homebrew upgrade complete. Cleaning up ..."
    brew cleanup
    echo "Cleanup complete. Time for a checkup ..."
    brew doctor
    # mas requires homebrew
    printf "\nUpdating Mac App Store (mas) apps ...\n"
    if command -v mas >/dev/null; then
        echo "Mac App Store (mas) apps checked:"
        mas list
        echo "Checking for outdated Mac App Store software ..."
        mas outdated
        sudo mas upgrade
    else
        echo "Homebrew tool mas (Mac App Store) unavailable"
        echo "Install with:"
        echo "  brew install mas"
    fi
else
    echo "Homebrew unavailable"
    echo "Visit https://brew.sh/ to install"
    exit 1
fi

echo "Mac update complete."