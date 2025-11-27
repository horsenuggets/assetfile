#!/usr/bin/env bash

# Get the shell name
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    echo "Unsupported shell "$SHELL_NAME"."
    exit 1
fi

# Add a directory to PATH if it's not already there, and also adds it to .bashrc or .zshrc
add_to_path() {

    # If no argument is provided, exit with error
    if [ -z "$1" ]; then
        echo "No directory provided to \"add_to_path()\" function."
        exit 1
    fi

    # Get the directory to add
    local DIR="$1"

    # Make sure the directory exists
    if [ ! -d "$DIR" ]; then
        echo "Directory \""$DIR"\" does not exist."
        exit 1
    fi

    # Check if the directory is already in PATH, if not, add it
    if [[ ":$PATH:" != *":$DIR:"* ]]; then
        export PATH="$DIR:$PATH"
        if ! grep -q "export PATH=\"$DIR:\$PATH\"" "$SHELL_CONFIG"; then
            echo "export PATH=\"$DIR:\$PATH\"" >> "$SHELL_CONFIG"
            echo "Added "$DIR" to PATH in "$SHELL_CONFIG"."
            echo "You may need to run \"source $SHELL_CONFIG\" or restart your terminal for the changes to take effect."
        fi
    fi
}
