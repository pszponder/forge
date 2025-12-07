#!/usr/bin/env bash

set -e

# ============================================
# Homebrew Universal Installer (macOS & Linux)
# ============================================
# Usage:
#   bash initialize_brew.sh [--brewfile PATH] [--help]
#
# Options:
#   --brewfile PATH   Specify a custom Brewfile path
#   --help            Display this help message and exit
#
# Environment Variables:
#   BREWFILE_PATH_OVERRIDE   Alternative way to set Brewfile path
#
# =============================================

# -----------------------------
# Help / Usage
# -----------------------------
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    grep '^#' "$0" | sed 's/^# //'
    exit 0
fi

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}==> Homebrew Universal Installer (macOS & Linux)${NC}"

# -----------------------------
# Brewfile Resolution Logic
# -----------------------------

# Directory this script is located in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of potential Brewfile locations in priority order
SEARCH_PATHS=(
    "$SCRIPT_DIR/Brewfile"  # 1. Next to script
)

# 2. XDG / config folders
[[ -n "$XDG_CONFIG_HOME" ]] && SEARCH_PATHS+=("$XDG_CONFIG_HOME/brew/Brewfile")
SEARCH_PATHS+=("$HOME/.config/brew/Brewfile")

# 3. Parent directory search (repo-style search)
PARENT_DIR="$PWD"
while [[ "$PARENT_DIR" != "/" ]]; do
    SEARCH_PATHS+=("$PARENT_DIR/Brewfile")
    PARENT_DIR="$(dirname "$PARENT_DIR")"
done

# Default unset
BREWFILE_PATH=""

# -----------------------------
# Parse command-line arguments
# -----------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --brewfile)
            shift
            [[ -z "$1" ]] && { echo -e "${RED}Error: --brewfile requires a path.${NC}"; exit 1; }
            BREWFILE_PATH="$1"
            shift
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            exit 1
            ;;
    esac
done

# Environment override (unless CLI already set)
if [[ -z "$BREWFILE_PATH" && -n "$BREWFILE_PATH_OVERRIDE" ]]; then
    BREWFILE_PATH="$BREWFILE_PATH_OVERRIDE"
fi

# Auto-detect if still not set
if [[ -z "$BREWFILE_PATH" ]]; then
    for path in "${SEARCH_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            BREWFILE_PATH="$path"
            break
        fi
    done
fi

# Final fallback
BREWFILE_PATH="${BREWFILE_PATH:-$SCRIPT_DIR/Brewfile}"

echo -e "${GREEN}Using Brewfile: $BREWFILE_PATH${NC}"

# -----------------------------
# Functions
# -----------------------------
install_linux_deps() {
    echo -e "${GREEN}Installing necessary Linux dependencies...${NC}"

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y build-essential procps curl file git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf group install development-tools
        sudo dnf install -y procps-ng curl file git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed base-devel procps-ng curl file git
    else
        echo -e "${RED}Unsupported Linux distribution.${NC}"
        exit 1
    fi
}

install_brewfile() {
    if [[ -f "$BREWFILE_PATH" ]]; then
        echo -e "${GREEN}Installing packages from Brewfile at $BREWFILE_PATH...${NC}"
        "$BREW_PATH" bundle --file="$BREWFILE_PATH"
        echo -e "${GREEN}✓ Brewfile packages installed.${NC}"
    else
        echo -e "${YELLOW}No Brewfile found at $BREWFILE_PATH. Skipping Brewfile installation.${NC}"
    fi
}

# add_homebrew_to_profiles() {
#     echo -e "${YELLOW}Would you like to add Homebrew to your shell profiles?${NC}"
#     PROMPT="Add to bash + zsh"
#     $HAS_FISH && PROMPT="$PROMPT + fish"
#     read -rp "$PROMPT? [Y/n]: " RESP
#     RESP="${RESP:-Y}"

#     if [[ "$RESP" =~ ^[Yy]$ ]]; then
#         echo 'eval "$('"$BREW_PATH"' shellenv)"' >> "$HOME/.bashrc"
#         echo 'eval "$('"$BREW_PATH"' shellenv)"' >> "$HOME/.zshrc"

#         if $HAS_FISH; then
#             FISH_CONFIG="$HOME/.config/fish/config.fish"
#             mkdir -p "$(dirname "$FISH_CONFIG")"
#             echo "eval ($BREW_PATH shellenv)" >> "$FISH_CONFIG"
#             echo -e "${GREEN}✓ Added Homebrew to fish config at $FISH_CONFIG${NC}"
#         fi

#         echo -e "${GREEN}✓ Added Homebrew initialization to shell profiles.${NC}"
#     else
#         echo -e "${YELLOW}Skipping profile modification.${NC}"
#     fi
# }

# -----------------------------
# Detect OS
# -----------------------------
OS="$(uname -s)"
echo -e "${GREEN}Detected OS: $OS${NC}"

# -----------------------------
# Install or update Homebrew
# -----------------------------
BREW_INSTALLED=false
NEWLY_INSTALLED=false

if command -v brew >/dev/null 2>&1; then
    BREW_INSTALLED=true
    BREW_PATH="$(command -v brew)"
    echo -e "${YELLOW}Homebrew is already installed at $BREW_PATH${NC}"
    "$BREW_PATH" update
else
    NEWLY_INSTALLED=true
    if [[ "$OS" == "Darwin" ]]; then
        # Ensure Xcode Command Line Tools are installed
        if ! xcode-select -p &>/dev/null; then
            echo "Installing Xcode Command Line Tools..."
            xcode-select --install
            # Wait for user to complete installation if needed
            echo "Please complete the installation of Command Line Tools and press Enter to continue."
            read -r
        fi

        # Prompt for sudo upfront so credentials are cached for Homebrew installer
        echo -e "${YELLOW}Homebrew installation requires sudo access to create directories.${NC}"
        sudo -v || { echo -e "${RED}Failed to obtain sudo credentials.${NC}"; exit 1; }

        # Keep sudo alive in the background during installation
        (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
        SUDO_KEEPALIVE_PID=$!

        echo -e "${YELLOW}Installing Homebrew...${NC}"
        if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            echo -e "${GREEN}Homebrew installation completed.${NC}"
        else
            echo -e "${RED}Homebrew installation failed.${NC}"
            kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
            exit 1
        fi

        # Kill the sudo keep-alive process
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    elif [[ "$OS" == "Linux" ]]; then
        install_linux_deps

        # Prompt for sudo upfront
        echo -e "${YELLOW}Homebrew installation requires sudo access.${NC}"
        sudo -v || { echo -e "${RED}Failed to obtain sudo credentials.${NC}"; exit 1; }

        echo -e "${YELLOW}Installing Homebrew...${NC}"
        if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            echo -e "${GREEN}Homebrew installation completed.${NC}"
        else
            echo -e "${RED}Homebrew installation failed.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
    fi

    POSSIBLE_BREW_PATHS=(
        "/opt/homebrew/bin/brew"
        "/usr/local/bin/brew"
        "$HOME/.linuxbrew/bin/brew"
        "/home/linuxbrew/.linuxbrew/bin/brew"
    )

    BREW_PATH=""
    for path in "${POSSIBLE_BREW_PATHS[@]}"; do
        [[ -x "$path" ]] && BREW_PATH="$path" && break
    done

    if [[ -z "$BREW_PATH" ]]; then
        echo -e "${RED}Homebrew installation failed (brew not found).${NC}"
        exit 1
    fi

    echo -e "${GREEN}Homebrew installed at: $BREW_PATH${NC}"
fi

eval "$($BREW_PATH shellenv)"

echo -e "${GREEN}Homebrew is ready!${NC}"
"$BREW_PATH" --version

# -----------------------------
# Install Brewfile packages
# -----------------------------
install_brewfile

# # -----------------------------
# # Prompt to add Homebrew to shell profiles only if newly installed
# # -----------------------------
# if [[ "$NEWLY_INSTALLED" == true ]]; then
#     add_homebrew_to_profiles
# fi
