#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make sure that we are in root directory of the repository
if [ ! -d "./.git/" ]; then
    echo "Ensure that this script is running from the root of the repository."
    exit 1
fi
