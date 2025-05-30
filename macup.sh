#!/bin/bash
# update Mac software

usage() {
    echo "Usage: $0 [-b|--brew]"
    echo "  -b, --brew    Skip system software update, only run Homebrew updates"
    exit 1
}

# Parse command line arguments
SKIP_SOFTWARE_UPDATE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--brew)
            SKIP_SOFTWARE_UPDATE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

printf "${0##*/} updates Mac system software, plus\n" 
printf "software and apps managed with Homebrew\n\n"

$QUIET=&>/dev/null

if [ "$SKIP_SOFTWARE_UPDATE" = false ]; then
    echo "Updating Mac system software ..."
    softwareupdate --all --install
else
    echo "Skipping system software update (--brew flag used)"
fi

echo "Upgrading tools and apps (casks) tracked by homebrew."
if test $(which brew); then 
    echo "Checking for brew packages to upgrade ..."
    brew update
    echo "Homebrew packages checked for upgrades:"
    brew list
    printf "\nUpgrading out-of-date packages ...\n"
    brew upgrade
    printf "\nHomebrew upgrade complete.\nCleaning up ...\n"
    brew cleanup
    echo "Cleanup complete. Time for a checkup ..."
    brew doctor
    # mas requires homebrew
    echo "Updating Mac App Store (mas) apps ..."
    if test $(which mas); then
        echo "Mac App Store (mas) apps checked:"
        mas list
        echo "Checking for outdated Mac App Store software ..."
        mas outdated
        mas upgrade
    else
        echo "Homebrew tool mas (Mac App Store) unavailable."
    fi
else
    echo "Homebrew unavailable."
    exit 1
fi