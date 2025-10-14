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

Use the `-b` or `--brew` option to skip system software updates and only update Homebrew packages:

```bash
./macup.sh -b
```

### start-ssh-agent.sh -- start ssh-agent and load your SSH key

This script starts the `ssh-agent` if it's not already running and automatically loads your SSH key. This is particularly useful when connecting to your Mac via a remote session (e.g., SSH), where the ssh-agent may not be running.

**Important:** This script should be **sourced** (not executed) to ensure the ssh-agent environment variables are set in your current shell:

```bash
source start-ssh-agent.sh
```

By default, the script loads `~/.ssh/id_ed25519`. You can specify a different key name using the `-n` option:

```bash
source start-ssh-agent.sh -n id_rsa
```

The script will display a warning if the specified key file is not found.

### .aliases -- shell aliases for productivity

A collection of useful shell aliases adapted from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles). This file provides shortcuts and enhancements for common tasks on macOS.

**Key features:**

* **Navigation shortcuts** - Quick directory navigation (`..`, `...`, `....`) and common locations (`d` for Dropbox, `dl` for Downloads, `dt` for Desktop, `r` for repos)
* **Enhanced ls commands** - Colorized directory listings with shortcuts (`l`, `la`, `lsd`)
* **Network utilities** - Get your IP address (`ip`, `localip`), show active interfaces (`ifactive`), flush DNS cache (`flush`)
* **macOS-specific** - Show/hide hidden files (`show`/`hide`), toggle desktop icons (`showdesktop`/`hidedesktop`), clean up `.DS_Store` files (`cleanup`)
* **System maintenance** - Empty trash (`emptytrash`), reload shell (`reload`), Spotlight control (`spoton`/`spotoff`)
* **Developer tools** - Git shortcut (`g`), HTTP method aliases (`GET`, `POST`, etc.), Chrome launcher

**Usage:** Source this file in your shell configuration (`.bashrc`, `.zshrc`, etc.):

```bash
source ~/.aliases
```

Or source it directly from this repository:

```bash
source /path/to/mac-bash/.aliases
```
