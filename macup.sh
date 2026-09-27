#!/bin/bash
# update Mac software

usage() {
    echo "Usage: $0 [-a|--all] [-b|--brew-only]"
    echo "  (default)          Password-free updates only: Homebrew formulae and app-only casks"
    echo "  -a, --all          Also run updates that need an admin password:"
    echo "                     macOS updates, .pkg-based casks, Mac App Store apps"
    echo "  -b, --brew-only    With --all, skip macOS system updates"
    exit "${1:-1}"
}

printf "${0##*/} updates Mac system software,\n" 
printf "plus software and apps managed with Homebrew\n\n"

RUN_ALL=false
SKIP_SOFTWARE_UPDATE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            RUN_ALL=true
            shift
            ;;
        -b|--brew-only)
            SKIP_SOFTWARE_UPDATE=true
            shift
            ;;
        -h|--help)
            usage 0
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

if [ "$SKIP_SOFTWARE_UPDATE" = true ] && [ "$RUN_ALL" = false ]; then
    echo "Note: -b/--brew-only has no effect without -a/--all"
fi

# Updates that need a password; listed at the end in default mode
SKIPPED=()

if [ "$RUN_ALL" = true ]; then
    echo "Admin password needed for system and App Store updates."
    echo "  (Homebrew resets sudo on every run, so .pkg casks may ask again.)"
    read -r -s -p "Password for $USER: " ADMIN_PASS
    echo
    sudo -k  # drop any cached credential so the typed password is actually verified
    if ! printf '%s\n' "$ADMIN_PASS" | sudo -S -p '' -v 2>/dev/null; then
        echo "Error: incorrect password or $USER is not an admin." >&2
        exit 1
    fi
    # Refresh the sudo timestamp so long upgrades don't hit the 5-minute timeout
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    KEEPALIVE_PID=$!
fi

if [ "$RUN_ALL" = true ] && [ "$SKIP_SOFTWARE_UPDATE" = true ]; then
    echo "Skipping system software update (-b/--brew-only flag used)"
else
    echo "Checking for Mac system software updates ..."
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
    elif [ "$RUN_ALL" = false ]; then
        for label in "${labels[@]}"; do
            SKIPPED+=("macOS update: $label")
        done
    else
        echo "Installing: ${labels[*]}"
        # Apple Silicon OS updates need volume-owner auth, which root alone doesn't satisfy
        if [ "$(uname -m)" = "arm64" ]; then
            printf '%s\n' "$ADMIN_PASS" | sudo softwareupdate --install "${labels[@]}" --user "$USER" --stdinpass
        else
            sudo softwareupdate --install "${labels[@]}"
        fi
    fi
fi
unset ADMIN_PASS

# Runs before any brew command: brew.sh resets the sudo timestamp on every invocation
printf "\nUpdating Mac App Store (mas) apps ...\n"
if command -v mas >/dev/null; then
    echo "Mac App Store (mas) apps checked:"
    mas list
    echo "Checking for outdated Mac App Store software ..."
    if [ "$RUN_ALL" = true ]; then
        mas outdated
        sudo mas upgrade
    else
        while IFS= read -r app; do
            [ -n "$app" ] && SKIPPED+=("App Store: $app")
        done < <(mas outdated)
    fi
else
    echo "Homebrew tool mas (Mac App Store) unavailable"
    echo "Install with:"
    echo "  brew install mas"
fi

[ -n "${KEEPALIVE_PID:-}" ] && kill "$KEEPALIVE_PID" 2>/dev/null

printf "\nUpgrading tools and apps (casks) tracked by homebrew ...\n"
if command -v brew >/dev/null; then
    echo "Homebrew found. Checking for brew packages to upgrade ..."
    brew update
    echo "Homebrew packages checked for upgrades:"
    brew list
    echo "Upgrading out-of-date formulae ..."
    brew upgrade --formula --yes
    if [ "$RUN_ALL" = true ]; then
        echo "Upgrading out-of-date casks ..."
        brew upgrade --cask --yes
    else
        # Casks need a password if they run a pkg/installer, or if the installed
        # .app isn't writable by us (e.g. a self-updater changed it to root)
        app_casks=()
        appdir=$(printf '%s' "${HOMEBREW_CASK_OPTS:-}" | sed -n 's/.*--appdir=\([^ ]*\).*/\1/p')
        appdir=${appdir:-/Applications}
        outdated_casks=$(brew outdated --cask -q)
        if [ -n "$outdated_casks" ]; then
            while IFS=$'\t' read -r kind token apps; do
                [ -z "$token" ] && continue
                if [ "$kind" = "app" ] && [ -n "$apps" ]; then
                    IFS='|' read -r -a app_names <<< "$apps"
                    for app_name in "${app_names[@]}"; do
                        for dir in "$appdir" /Applications; do
                            if [ -e "$dir/$app_name" ] && [ ! -w "$dir/$app_name" ]; then
                                kind="readonly"
                            fi
                        done
                    done
                fi
                case "$kind" in
                    pkg) SKIPPED+=("Homebrew cask (.pkg installer): $token") ;;
                    readonly) SKIPPED+=("Homebrew cask (installed app not writable): $token") ;;
                    *) app_casks+=("$token") ;;
                esac
            done < <(brew info --cask --json=v2 $outdated_casks | /usr/bin/jq -r '.casks[] |
                (if any(.artifacts[]; has("pkg") or has("installer")) then "pkg" else "app" end)
                + "\t" + .full_token + "\t"
                + ([.artifacts[] | .app? // empty | .[]
                    | (if type == "string" then . else (.target? // empty) end)
                    | split("/") | last] | join("|"))')
        fi
        if [ ${#app_casks[@]} -gt 0 ]; then
            echo "Upgrading out-of-date casks: ${app_casks[*]}"
            brew upgrade --cask --yes "${app_casks[@]}"
        fi
    fi
    echo "Homebrew upgrade complete. Cleaning up ..."
    brew cleanup
    echo "Cleanup complete. Time for a checkup ..."
    brew doctor
else
    echo "Homebrew unavailable"
    echo "Visit https://brew.sh/ to install"
    exit 1
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    printf "\nSkipped (need an admin password):\n"
    printf '  %s\n' "${SKIPPED[@]}"
    echo "Run '${0##*/} --all' to install these."
fi

echo "Mac update complete."