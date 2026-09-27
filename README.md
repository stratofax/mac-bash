# bash-mac

Bash scripts for setting up and maintaining your Mac

## Why bash?

Maybe you aren't using the bash shell on your Mac when you go to the command line -- I prefer fish myself. Since macOS Catalina, the default shell is zsh. Still, bash is installed on every Mac that runs OS X. As a result, these scripts will run on most every Mac.

Because of this, I only use bash commands that are available on the standard Mac installation of bash.

## The scripts

An overview of the scripts: what they do, why you'd want to use them.

### macup.sh -- update your Mac

This script uses Apple's `softwareupdate` tool, and [Homebrew, The Missing Package Manager for macOS](https://brew.sh/), to update all the software on your Mac, including:

* System software (handled by `softwareupdate`)
* Software tools managed by homebrew
* Apps managed by the Mac App Store, using the `mas` tool in homebrew

By default the script runs unattended with no password: it upgrades Homebrew formulae and app-only casks, then lists anything it skipped because it needs an admin password (macOS updates, `.pkg`-based casks, Mac App Store apps).

```bash
./macup.sh
```

Use `-a` or `--all` to also install the password-protected updates. The script asks for your admin password once at the start, then runs unattended:

```bash
./macup.sh -a
```

Add `-b` or `--brew-only` to skip macOS system updates in an `--all` run:

```bash
./macup.sh -a -b
```

Major macOS upgrades (e.g. 26 → 27) are always skipped; install those manually when you're ready.

## Configuration Scripts

The `config/` directory contains scripts for configuring macOS system settings and third-party applications using the `defaults` command-line tool.

### macos-config.sh -- comprehensive macOS configuration

This extensive script configures hundreds of macOS system preferences across multiple categories:

* **General UI/UX** - Interface elements, scrollbars, save/print dialogs, window animations
* **Trackpad, mouse, keyboard** - Input device settings and keyboard behavior
* **Energy saving** - Power management and sleep settings
* **Screen** - Screen saver and display settings
* **Finder** - File browser preferences, view options, and desktop behavior
* **Dock, Dashboard, and hot corners** - Dock appearance and screen corner actions
* **Safari & WebKit** - Browser privacy, security, and behavior settings
* **Mail** - Email client preferences and spell checking
* **Terminal & iTerm 2** - Terminal emulator settings
* **Time Machine** - Backup configuration
* **Activity Monitor** - System monitoring preferences
* **Mac App Store** - App Store behavior and automatic updates
* **Photos** - Photo library and device handling
* **Messages** - Messaging app preferences

Based on [Mathias Bynens' .macos dotfiles](https://mths.be/macos) and [macos-defaults.com](https://macos-defaults.com/).

### non-apple-config.sh -- third-party app configuration

Configures settings for popular third-party applications:

* **Google Chrome** - Disable swipe navigation, configure print dialogs
* **GPGMail** - Email signing preferences
* **Opera** - Print dialog settings
* **Transmission** - BitTorrent client download locations and behavior

### spotlight-config.sh -- Spotlight search configuration

Configures macOS Spotlight search functionality:

* Disables indexing for external volumes
* Customizes search result categories and ordering
* Enables/disables specific search result types
* Rebuilds the Spotlight index with new settings
