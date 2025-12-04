#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Source Dependencies
source ./scripts/config.sh
source ./scripts/utils/_utils.sh

clear
print_logo

install_git
clone_repo "$FORGE_REPO" "$FORGE_DATA_DIR"
checkout_git_branch "$FORGE_DATA_DIR" "$FORGE_BRANCH"

# Install Forge Script
print_status "$YELLOW" "Installing forge script to $FORGE_BIN_PATH..."
mkdir -p "$FORGE_BIN_DIR"
cp "$FORGE_DATA_DIR/forge.sh" "$FORGE_BIN_PATH"
chmod +x "$FORGE_BIN_PATH"

print_status "$GREEN" "✅ Forge installed successfully!"