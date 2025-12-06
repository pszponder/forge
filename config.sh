# Centralized configuration for Forge runtime and installer.
# This file is sourced directly by forge.sh and install.sh; other scripts
# receive any needed values via function arguments from those entrypoints.

# Installation directories (use provided env vars when present)
# Allow callers to override paths by exporting variables first. We only set
# defaults when the value isn't already set in the environment.
export FORGE_BIN_DIR="${FORGE_BIN_DIR:-${HOME}/.local/bin}"
export FORGE_BIN_PATH="${FORGE_BIN_PATH:-${FORGE_BIN_DIR}/forge}"
export FORGE_DATA_DIR="${FORGE_DATA_DIR:-${HOME}/.local/share/forge}"

# Repository information
export FORGE_REPO="pszponder/forge"
export FORGE_BRANCH="main"

# Dotfiles info
export DOTFILES_REPO="pszponder/dotfiles"
export DOTFILES_BRANCH="main"
export DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/Development/repos/github/pszponder/dotfiles}"

# Default SSH key specs used by forge_setup_ssh_keys
# Format per entry: "path|type|comment"
# - path: location for the private key (tilde expands)
# - type: ed25519 | rsa (optional, defaults to ed25519)
# - comment: key comment (optional)
FORGE_SSH_KEYS_SPECS=(
  "~/.ssh/key_default|ed25519|piotr@default"
  "~/.ssh/github/pszponder/key_github|ed25519|14116413+pszponder@users.noreply.github.com"
)

# Whether forge_setup_ssh_keys should ask sshkeygen.sh to add keys to ssh-agent
# Values: yes | no
FORGE_SSH_ADD_AGENT="yes"

# Ensure directories are defined consistently across all scripts
