#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make sure that we are in root directory of the repository
if [ ! -d "./.git/" ]; then
    echo "Ensure that this script is running from the root of the repository."
    exit 1
fi

# Load AddToPath script to ensure necessary paths are set
source ./Scripts/Helpers/AddToPath.unix.sh

# Get rokit version from rokit.version, trim whitespace
ROKIT_VERSION=$(tr -d " \t\n\r" < "./rokit.version")

# Check if rokit is installed, if not, install it
if ! command -v rokit &> /dev/null; then
    echo "Dependency \"rokit\" not found. Installing rokit..."
    curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/blob/v$ROKIT_VERSION/scripts/install.sh | bash -s -- $ROKIT_VERSION

    # Ensure $HOME/.rokt/bin/rokit exists
    if [ ! -f "$HOME/.rokit/bin/rokit" ]; then
        echo "Dependency \"rokit\" failed to install. File \"$HOME/.rokit/bin/rokit\" not found."
        exit 1
    fi

    # Add $HOME/.rokit/bin to PATH
    add_to_path "$HOME/.rokit/bin"

    # Ensure rokit is now available
    if ! command -v rokit &> /dev/null; then
        echo "Dependency \"rokit\" failed to install. The \"rokit\" command is not available."
        exit 1
    fi

    echo "Dependency \"rokit\" installed successfully."
else
    echo "Dependency \"rokit\" is already installed."
fi

# Set ROKIT and ROKIT_TOOLS environment variables
export ROKIT=$(command -v rokit)
export ROKIT_TOOLS=$(dirname "$ROKIT")

# Install rokit dependencies
"$ROKIT" install --no-trust-check
