#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Resolve Forge root (this script lives in the repo or data root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$SCRIPT_DIR"

# Source shared configuration and dependencies
# shellcheck disable=SC1090
source "$FORGE_ROOT/config.sh"
# shellcheck disable=SC1090
source "$FORGE_ROOT/scripts/utils/_utils.sh"

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