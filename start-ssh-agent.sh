# Parse command line options
KEY_NAME="id_ed25519"
while getopts "n:" opt; do
    case $opt in
        n)
            KEY_NAME="$OPTARG"
            ;;
        *)
            echo "Usage: $0 [-n key_name]"
            exit 1
            ;;
    esac
done

KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Start ssh-agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# Optional: auto-add your key (will prompt for passphrase once)
if ! ssh-add -l &>/dev/null; then
    if [ -f "$KEY_PATH" ]; then
        ssh-add "$KEY_PATH"
    else
        echo "Warning: SSH key $KEY_PATH not found"
    fi
fi

