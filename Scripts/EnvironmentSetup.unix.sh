#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make sure that we are in root directory of the repository
if [ ! -d "./.git/" ]; then
    echo "Ensure that this script is running from the root of the repository."
    exit 1
fi

# Run RokitSetup script to ensure rokit is installed and set up
./Scripts/Helpers/RokitSetup.unix.sh

# Run setup scripts for lune and wally
lune setup --no-update-luaurc
wally install

# Iterate over all files in ./Scripts/Actions and create a shell executor for each action
INITIALIZER_SOURCE=$(cat "./Scripts/Helpers/Initializer.unix.sh")
for luau_action_file in ./Scripts/Actions/*; do
    ACTION_NAME=$(basename $luau_action_file .luau)
    SHELL_EXECUTOR_PATH="./Scripts/$ACTION_NAME.gen.unix.sh"

    printf "$INITIALIZER_SOURCE\n\n" > $SHELL_EXECUTOR_PATH
    printf "# Run the $ACTION_NAME script using lune\n" >> $SHELL_EXECUTOR_PATH
    printf "lune run ./Scripts/Actions/${ACTION_NAME}.luau \"\$@\"\n" >> $SHELL_EXECUTOR_PATH

    chmod +x $SHELL_EXECUTOR_PATH
done
