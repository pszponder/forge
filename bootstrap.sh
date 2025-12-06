#!/usr/bin/env bash

# Minimal, safe bootstrap used for remote installs (curl | bash)
# - Keeps logic tiny and auditable
# - Clones the repo to disk then delegates to repo's install.sh
# - Honors environment overrides (FORGE_DATA_DIR, FORGE_REPO, FORGE_BRANCH, FORGE_BIN_DIR)
# - Avoids destructive operations where possible; gives clear messages

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
  local color="$1";
  local msg="$2";
  echo -e "${color}${msg}${NC}"
}

print_logo() {
  cat <<'EOF'
    ______
   / ____/___  _________ ____
  / /_  / __ \/ ___/ __ `/ _ \
 / __/ / /_/ / /  / /_/ /  __/
/_/    \____/_/   \__, /\___/  a System Crafting Tool
                 /____/
EOF
}

# Bootstrap defaults (allow caller to override by setting env vars)
FORGE_DATA_DIR="${FORGE_DATA_DIR:-${HOME}/.local/share/forge}"
FORGE_REPO="${FORGE_REPO:-pszponder/forge}"
FORGE_BRANCH="${FORGE_BRANCH:-main}"
FORGE_BIN_DIR="${FORGE_BIN_DIR:-${HOME}/.local/bin}"
FORGE_BIN_PATH="${FORGE_BIN_PATH:-${FORGE_BIN_DIR}/forge}"

# Resolve script dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
print_logo

# If executed from a checked-out repo (SCRIPT_DIR==FORGE_DATA_DIR) and
# repo's install.sh exists, prefer delegating to the in-repo installer.
if [ "$SCRIPT_DIR" = "$FORGE_DATA_DIR" ] && [ -f "$FORGE_DATA_DIR/install.sh" ]; then
  print_status "$YELLOW" "Running in-repo installer at $FORGE_DATA_DIR/install.sh"
  exec /bin/bash "$FORGE_DATA_DIR/install.sh"
fi

# On remote runs install git if missing
if ! command -v git >/dev/null 2>&1; then
  print_status "$YELLOW" "Git not found — attempting to install (this may prompt for sudo)"
  OS="$(uname -s)"
  if [ "$OS" = "Darwin" ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
      print_status "$YELLOW" "Installing XCode CLI tools..."
      xcode-select --install
      until xcode-select -p >/dev/null 2>&1; do sleep 2; done
    fi
  elif [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y git
  elif [ -f /etc/redhat-release ]; then
    if command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y git
    else
      sudo yum install -y git
    fi
  elif [ -f /etc/arch-release ]; then
    sudo pacman -Sy --noconfirm git
  else
    print_status "$RED" "Unsupported OS — please install git and re-run the bootstrap"
    exit 1
  fi
fi

print_status "$GREEN" "✅ git available — cloning ${FORGE_REPO} to ${FORGE_DATA_DIR}"

# Attempt to safely remove existing installation if present
if [ -d "$FORGE_DATA_DIR" ]; then
  # Safety: refuse to act on obviously dangerous paths such as "/" or empty
  # values to avoid catastrophic accidental removals.
  if [ -z "$FORGE_DATA_DIR" ] || [ "$FORGE_DATA_DIR" = "/" ]; then
    print_status "$RED" "Refusing to remove unsafe path: ${FORGE_DATA_DIR:-<empty>}"
    exit 1
  fi

  print_status "$YELLOW" "Target exists at $FORGE_DATA_DIR — removing and replacing"
  rm -rf "$FORGE_DATA_DIR"
fi

git clone "https://github.com/${FORGE_REPO}.git" "$FORGE_DATA_DIR"

print_status "$YELLOW" "Checking out branch ${FORGE_BRANCH}"
if ! git -C "$FORGE_DATA_DIR" checkout "$FORGE_BRANCH" 2>/dev/null; then
  print_status "$YELLOW" "Branch $FORGE_BRANCH not found — continuing with default checkout"
fi

# Delegate to the repo's installer for full install
if [ -f "$FORGE_DATA_DIR/install.sh" ]; then
  print_status "$GREEN" "Delegating to in-repo installer: $FORGE_DATA_DIR/install.sh"
  exec /bin/bash "$FORGE_DATA_DIR/install.sh"
else
  print_status "$RED" "❌ install.sh not found in cloned repository — something went wrong."
  exit 1
fi
