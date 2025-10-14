# Start ssh-agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# Optional: auto-add your key (will prompt for passphrase once)
if ! ssh-add -l &>/dev/null; then
    ssh-add ~/.ssh/id_ed25519
fi

