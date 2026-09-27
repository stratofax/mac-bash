#!/bin/bash
# update Mac software

usage() {
    echo "Usage: $0 [-b|--brew]"
    echo "  -b, --brew    Skip system software update, only run Homebrew updates"
    exit 1
}

printf "${0##*/} updates Mac system software,\n" 
printf "plus software and apps managed with Homebrew\n\n"

SKIP_SOFTWARE_UPDATE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--brew)
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

echo "Admin password needed once for system, cask, and App Store updates:"
sudo -v || exit 1
# Refresh the sudo timestamp so long upgrades don't hit the 5-minute timeout
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ "$SKIP_SOFTWARE_UPDATE" = false ]; then
    echo "Updating Mac system software ..." 
    echo "  (use --brew flag to skip)"
    sudo softwareupdate --all --install
else
    echo "Skipping system software update (--brew flag used)"
fi

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