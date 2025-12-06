#!/usr/bin/env bash
set -e

setup_nerdfonts() {
  # Default version (Linux only)
  local NERD_FONTS_VERSION="${1:-v3.4.0}"

  # -----------------------------
  # Predefined Nerd Fonts
  # -----------------------------
  local FONTS_TO_INSTALL=(
    "CascadiaCode"
    "CascadiaMono"
    "FiraCode"
    "Hack"
    "JetBrainsMono"
    "Meslo"
  )

  # Predefined Nerd Fonts for macOS (Homebrew cask names)
  local FONTS_TO_INSTALL_MAC=(
    # "font-blex-mono-nerd-font"
    "font-caskaydia-cove-nerd-font"
    "font-caskaydia-mono-nerd-font"
    "font-fira-code-nerd-font"
    "font-fira-mono-nerd-font"
    "font-hack-nerd-font"
    "font-jetbrains-mono-nerd-font"
    "font-meslo-lg-nerd-font"
    # "font-terminess-ttf-nerd-font"
  )

  # -----------------------------
  # Detect OS
  # -----------------------------
  local OS="$(uname -s)"
  if [[ "$OS" == "Darwin" ]]; then
    # macOS: use Homebrew
    if ! command -v brew >/dev/null 2>&1; then
      print_status "$RED" "❌ Homebrew is required for Nerd Fonts installation on macOS. Please install Homebrew first."
      return 1
    fi

    print_status "$BLUE" "🔤 Installing select Nerd Fonts on macOS via Homebrew..."

    # Ensure homebrew/cask-fonts is tapped (required to install font casks)
    if ! brew tap | grep -q '^homebrew/cask-fonts$'; then
      print_status "$YELLOW" "Tapping homebrew/cask-fonts..."
      brew tap homebrew/cask-fonts
    fi

    for cask in "${FONTS_TO_INSTALL_MAC[@]}"; do
      print_status "$BLUE" "Installing $cask..."
      brew install --cask "$cask"
    done

    print_status "$GREEN" "✅ Nerd Fonts installation complete on macOS!"
    echo "Installed fonts: ${FONTS_TO_INSTALL_MAC[*]}"

  elif [[ "$OS" == "Linux" ]]; then
    # Linux: download from GitHub releases
    print_status "$BLUE" "🔤 Installing select Nerd Fonts $NERD_FONTS_VERSION on Linux..."

    # -----------------------------
    # Dependencies check
    # -----------------------------
    for cmd in curl unzip fc-cache; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        print_status "$RED" "❌ Error: $cmd is required. Please install it first."
        return 1
      fi
    done

    # -----------------------------
    # Font install directory
    # -----------------------------
    local FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    # -----------------------------
    # Nerd Fonts GitHub base URL
    # -----------------------------
    local NERD_FONTS_RELEASE_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

    # -----------------------------
    # Install fonts
    # -----------------------------
    for font in "${FONTS_TO_INSTALL[@]}"; do
      local ZIP_NAME="${font}.zip"
      local URL="${NERD_FONTS_RELEASE_BASE}/${ZIP_NAME}"

      echo -e "\nDownloading $font from $URL ..."
      local TMPZIP=$(mktemp)
      curl -sSL -o "$TMPZIP" "$URL"

      echo "Extracting $font..."
      unzip -o -q "$TMPZIP" -d "$FONT_DIR"
      rm -f "$TMPZIP"

      echo "✓ Installed $font"
    done

    # -----------------------------
    # Refresh font cache
    # -----------------------------
    echo -e "\nRefreshing font cache..."
    fc-cache -f -v

    print_status "$GREEN" "✅ Nerd Fonts installation complete on Linux!"
    echo "Installed fonts: ${FONTS_TO_INSTALL[*]}"
    echo "Installed from Nerd Fonts version: ${NERD_FONTS_VERSION}"

  else
    print_status "$YELLOW" "⚠️ Nerd Fonts installation not supported on $OS. Skipping."
    return 0
  fi
}

# If this script is run directly, call the function
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # Parse arguments for standalone usage
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "Usage: $0 [--version VERSION] [--help]"
        echo
        echo "Installs a predefined set of Nerd Fonts on Linux and macOS."
        echo "On Linux: Downloads from GitHub releases to ~/.local/share/fonts."
        echo "On macOS: Installs via Homebrew (requires Homebrew to be installed)."
        echo
        echo "Options:"
        echo "  -h | --help         Show this help message"
        echo "  -v | --version      Specify Nerd Fonts version (Linux only, default: v3.4.0)"
        exit 0
        ;;
      -v|--version)
        shift
        if [[ -z "$1" ]]; then
          echo "Error: --version requires a value"
          exit 1
        fi
        VERSION="$1"
        shift
        ;;
      *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
  done
  setup_nerdfonts "${VERSION:-}"
fi
