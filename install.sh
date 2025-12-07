#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# Use 'set -e -o pipefail' to keep compatibility with older bash (e.g. 3.2)
# The -E flag (ERR trap inheritance) may not be available in older bash
set -eo pipefail

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Print colored status messages
print_status() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

print_logo() {
    cat << "EOF"
    ______
   / ____/___  _________ ____
  / /_  / __ \/ ___/ __ `/ _ \
 / __/ / /_/ / /  / /_/ /  __/
/_/    \____/_/   \__, /\___/  a System Crafting Tool
                 /____/
EOF
}

install_git() {
  if ! command -v git &>/dev/null; then
    print_status "$YELLOW" "🔧 Git not found. Installing Git..."

    OS="$(uname -s)"

    if [[ "$OS" == "Darwin" ]]; then
      # -----------------------------------------------------
      # macOS: use XCode Command Line Tools instead of Homebrew
      # -----------------------------------------------------
      if xcode-select -p &>/dev/null; then
        print_status "$GREEN" "🛠️ XCode Command Line Tools already installed."
      else
        print_status "$YELLOW" "📦 Installing XCode Command Line Tools..."
        xcode-select --install

        # Wait for installation to finish
        print_status "$YELLOW" "⏳ Waiting for CLI tools to finish installing..."
        until xcode-select -p &>/dev/null; do sleep 5; done

        print_status "$GREEN" "✅ XCode Command Line Tools installed!"
      fi

    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get update
      sudo apt-get install -y git

    elif [[ -f /etc/redhat-release ]]; then
      # -----------------------------------------------------
      # Fedora / RHEL / CentOS
      # -----------------------------------------------------
      if command -v dnf &>/dev/null; then
        sudo dnf install -y git
      else
        sudo yum install -y git
      fi

    elif [[ -f /etc/arch-release ]]; then
      # -----------------------------------------------------
      # Arch Linux
      # -----------------------------------------------------
      sudo pacman -Sy --noconfirm git

    else
      print_status "$RED" "❌ Unsupported OS. Please install Git manually."
      return 1
    fi

    # -----------------------------
    # Verify installation
    # -----------------------------
    if command -v git &>/dev/null; then
      print_status "$GREEN" "✅ Git installed successfully!"
    else
      print_status "$RED" "❌ Git installation failed."
      return 1
    fi
  else
    print_status "$GREEN" "✅ Git is already installed."
  fi
}

clone_repo() {
  local repo=$1
  local target_dir=$2

  print_status "$YELLOW" "Cloning repository from https://github.com/${repo}.git to $target_dir..."
  rm -rf "$target_dir"
  git clone "https://github.com/${repo}.git" "${target_dir}" >/dev/null || { print_status "$RED" "❌ Failed to Clone."; exit 1; }
}

checkout_git_branch() {
  local repo_dir=$1
  local branch=$2

  print_status "$YELLOW" "Checking out branch/tag/version '$branch' in $repo_dir..."

  # Verify repo_dir exists
  if [ ! -d "$repo_dir" ]; then
    print_status "$RED" "❌ Provided path does not exist: $repo_dir"
    exit 1
  fi

  # Verify it's a Git repository
  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_status "$RED" "❌ Not a git repository: $repo_dir"
    exit 1
  fi

  # Use git -C so we don't change the caller's current working directory.
  # If 'origin' exists try fetch first, otherwise just attempt checkout.
  if git -C "$repo_dir" remote get-url origin >/dev/null 2>&1; then
    # Has remote origin — fetch and then checkout
    if git -C "$repo_dir" fetch origin "$branch" >/dev/null 2>&1 && \
       git -C "$repo_dir" checkout "$branch" >/dev/null 2>&1; then
      print_status "$GREEN" "✅ Checked out '$branch' in $repo_dir."
    else
      print_status "$RED" "❌ Failed to fetch/checkout branch: $branch in $repo_dir."
      exit 1
    fi
  else
    # No origin — just try a local checkout
    if git -C "$repo_dir" checkout "$branch" >/dev/null 2>&1; then
      print_status "$GREEN" "✅ Checked out local branch '$branch' in $repo_dir."
    else
      print_status "$RED" "❌ Failed to checkout local branch: $branch in $repo_dir."
      exit 1
    fi
  fi
}

configure_path() {
  local bin_dir="$1"

  print_status "$YELLOW" "Configuring PATH to include $bin_dir..."

  # Detect shell and appropriate config file
  local shell_config=""
  local current_shell="$(basename "$SHELL")"

  case "$current_shell" in
    zsh)
      shell_config="$HOME/.zshrc"
      ;;
    bash)
      # macOS uses .bash_profile, Linux typically uses .bashrc
      if [[ "$(uname -s)" == "Darwin" ]]; then
        shell_config="$HOME/.bash_profile"
      else
        shell_config="$HOME/.bashrc"
      fi
      ;;
    fish)
      shell_config="$HOME/.config/fish/config.fish"
      ;;
    *)
      print_status "$YELLOW" "⚠️  Unknown shell: $current_shell"
      print_status "$YELLOW" "Please manually add the following to your shell configuration:"
      print_status "$BLUE" "    export PATH=\"$bin_dir:\$PATH\""
      return 0
      ;;
  esac

  # Check if PATH is already configured
  if [[ -f "$shell_config" ]] && grep -q "$bin_dir" "$shell_config" 2>/dev/null; then
    print_status "$GREEN" "✅ PATH already configured in $shell_config"
    return 0
  fi

  # Add PATH configuration
  local path_export
  if [[ "$current_shell" == "fish" ]]; then
    path_export="fish_add_path $bin_dir"
  else
    path_export="export PATH=\"$bin_dir:\$PATH\""
  fi

  # Create config file if it doesn't exist
  if [[ ! -f "$shell_config" ]]; then
    # For fish, create parent directory if needed
    if [[ "$current_shell" == "fish" ]]; then
      mkdir -p "$(dirname "$shell_config")"
    fi
    touch "$shell_config"
  fi

  # Add the export with a comment
  {
    echo ""
    echo "# Added by Forge installer"
    echo "$path_export"
  } >> "$shell_config"

  print_status "$GREEN" "✅ Added $bin_dir to PATH in $shell_config"
  print_status "$YELLOW" "💡 Run 'source $shell_config' or restart your shell to use 'forge' command"
}

# Variables required for bootstrap mode
# Centralized configuration for Forge runtime and installer.
# Use env vars when provided by the caller, otherwise fall back to defaults.
export FORGE_BIN_DIR="${FORGE_BIN_DIR:-${HOME}/.local/bin}"
export FORGE_BIN_PATH="${FORGE_BIN_PATH:-${FORGE_BIN_DIR}/forge}"
export FORGE_DATA_DIR="${FORGE_DATA_DIR:-${HOME}/.local/share/forge}"
# Repository information
export FORGE_REPO="${FORGE_REPO:-pszponder/forge}"
export FORGE_BRANCH="${FORGE_BRANCH:-main}"

# Resolve location where this script lives (works for file and piped runs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# In-repo mode
# If this file is running from within the repository root, prefer to
# source the repo-local config and utils so in-repo helpers are used.
if [[ -f "$SCRIPT_DIR/config.sh" && -f "$SCRIPT_DIR/scripts/utils/_utils.sh" ]]; then
  FORGE_ROOT="$SCRIPT_DIR"
  # shellcheck disable=SC1090
  source "$FORGE_ROOT/config.sh"
  # shellcheck disable=SC1090
  source "$FORGE_ROOT/scripts/utils/_utils.sh"
fi

clear
print_logo

install_git
clone_repo "$FORGE_REPO" "$FORGE_DATA_DIR"
checkout_git_branch "$FORGE_DATA_DIR" "$FORGE_BRANCH"

# Bootstrap mode (running outside the repo)
# If we're being run as a bootstrapper (not already inside the checked-out
# repository), hand off to the repository's own installer so it can source
# the repo-local helper scripts and configuration.
if [ "$SCRIPT_DIR" != "$FORGE_DATA_DIR" ] && [ -f "$FORGE_DATA_DIR/install.sh" ]; then
  print_status "$YELLOW" "Handing off to repository installer at $FORGE_DATA_DIR/install.sh..."
  /bin/bash "$FORGE_DATA_DIR/install.sh"
  exit $?
fi

# Otherwise (we're already inside the repo or delegation failed) perform the
# final step directly here: copy the `forge.sh` entrypoint to the bin path.
print_status "$YELLOW" "Installing forge script to $FORGE_BIN_PATH..."
mkdir -p "$FORGE_BIN_DIR"
cp "$FORGE_DATA_DIR/forge.sh" "$FORGE_BIN_PATH"
chmod +x "$FORGE_BIN_PATH"

# Configure PATH
configure_path "$FORGE_BIN_DIR"

print_status "$GREEN" "✅ Forge installed successfully!"
print_status "$BLUE" "To use forge immediately in this session, run:"
print_status "$BLUE" "    export PATH=\"$FORGE_BIN_DIR:\$PATH\""