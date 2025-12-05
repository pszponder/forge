# Centralized configuration for Forge runtime and installer.
# This file is sourced directly by forge.sh and install.sh; other scripts
# receive any needed values via function arguments from those entrypoints.

# Installation directories
export FORGE_BIN_DIR="${HOME}/.local/bin"
export FORGE_BIN_PATH="${FORGE_BIN_DIR}/forge"
export FORGE_DATA_DIR="${HOME}/.local/share/forge"

# Repository information
export FORGE_REPO="pszponder/forge"
export FORGE_BRANCH="main"

# Dotfiles info
export DOTFILES_REPO="pszponder/dotfiles"
export DOTFILES_BRANCH="main"
export DOTFILES_DIR="${HOME}/Development/repos/github/pszponder/dotfiles"

# Ensure directories are defined consistently across all scripts
