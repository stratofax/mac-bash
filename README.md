# bash-mac
Bash scripts for setting up and maintaining your Mac

# Why bash?

Maybe you aren't using the bash shell on your Mac when you go to the command line -- I prefer fish myself. Since macOS Catalina, the default shell is zsh. Still, bash is installed on every Mac that runs OS X. As a result, these scripts will run on most every Mac. 

Because of this, I only use bash commands that are available on the standard Mac installation of bash.

# The scripts

An overview of the scripts: what they do, why you'd want to use them.

## macup.sh -- update your Mac

This script uses Apple's `softwareupdate` tool, and [Homebrew, The Missing Package Manager for macOS](https://brew.sh/), to update all the software on your Mac, including:

* System software (handled by `softwareupdate`)
* Software tools managed by homebrew
* Apps managed by the Mac App Store, using the `mas` tool in homebrew

### To Do

* Handle command line arguments for verbose / silent, write log file
