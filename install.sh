#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Source Dependencies
source ./scripts/utils/_utils.sh

# Define Variables
FORGE_REPO="pszponder/forge"
FORGE_BRANCH="main"
FORGE_DIR="$HOME/.local/share/forge"

install_git
clone_repo "$FORGE_REPO" "$FORGE_DIR"
checkout_git_branch "$FORGE_DIR" "$FORGE_BRANCH"

# TODO: move forge shell script to ~/.local/bin and make it executable and ensure that forge can still reference ~/.local/share/forge
cp "$FORGE_DIR/forge.sh" "$HOME/.local/bin/forge"
chmod +x "$HOME/.local/bin/forge"