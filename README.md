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
