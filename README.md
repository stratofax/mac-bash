# mac-bash

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

#### Requirements

* [Homebrew](https://brew.sh/)
* `mas` for Mac App Store updates (optional): `brew install mas`
* `jq`, which ships with macOS at `/usr/bin/jq` (macOS 15 Sequoia and later)

#### Usage

| Command | What it does | Password? |
| --- | --- | --- |
| `./macup.sh` | Homebrew formulae and app-only casks; reports everything it skipped | No |
| `./macup.sh -a` | Everything: macOS updates, all casks, Mac App Store apps | At the start, plus Homebrew's own prompts |
| `./macup.sh -a -b` | Same as `-a`, but skips macOS system updates | At the start, plus Homebrew's own prompts |

By default the script runs unattended with no password. It upgrades Homebrew formulae and casks that simply copy an `.app` into place, runs `brew cleanup` and `brew doctor`, then lists anything it skipped because it needs an admin password:

* macOS system updates (checked with `softwareupdate --list`, which needs no password)
* Casks that use a `.pkg` installer (e.g. Microsoft Teams, Tailscale)
* Casks whose installed `.app` isn't writable by you (e.g. Google Chrome after its own updater changes the owner to root)
* Outdated Mac App Store apps (`mas upgrade` requires root)

With `-a` / `--all`, the script asks for your admin password at the start and uses it for macOS updates and Mac App Store apps. On Apple Silicon, macOS updates also need volume-owner authentication beyond root, so the script passes the same password to `softwareupdate --stdinpass` rather than prompting a second time. The password is held only in a shell variable and cleared after the system update step.

Homebrew resets the `sudo` timestamp every time `brew` runs, a deliberate security measure so that scripts Homebrew runs can't reuse your cached credentials. The script therefore does all of its own `sudo` work before the first `brew` command. Homebrew then asks for your password itself for any cask that needs it, usually once per `brew` command that needs admin rights.

Major macOS upgrades (e.g. 26 → 27) are always skipped, even with `--all`; install those manually when you're ready.

#### Running on a schedule

`launchd/com.stratofax.macup.plist` runs the default (password-free) mode every day at 02:00 and logs to `~/Library/Logs/macup.log`. If the Mac is asleep at 02:00, the job runs when it next wakes.

The plist sets its own environment, because launchd doesn't read your shell config:

* `PATH` must include `/usr/sbin` (for `softwareupdate`) and `/opt/homebrew/bin`
* `HOMEBREW_CASK_OPTS` sets the cask install folder (`--appdir=...`). Change or remove it to match the Mac you're installing on.

Install or update the job:

```bash
cp launchd/com.stratofax.macup.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u)/com.stratofax.macup 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.stratofax.macup.plist
```

Check its status and last exit code:

```bash
launchctl print gui/$(id -u)/com.stratofax.macup | grep -E 'state|last exit'
```

The plist runs `macup.sh` from this repo's working copy, at the path in `ProgramArguments`. Edit that path if you cloned the repo somewhere else.

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
