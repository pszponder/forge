# Homebrew helper library for Forge (bash 3.2 compatible)
# This file is meant to be sourced, not executed directly.

if [[ -z "${FORGE_HOMEBREW_LIB_LOADED:-}" ]]; then
  FORGE_HOMEBREW_LIB_LOADED=1

  # -----------------------------
  # Internal helpers
  # -----------------------------

  _brew_print() {
    local level="$1"; shift || true
    local msg="$*"

    # Prefer Forge's print_status if available
    if command -v print_status >/dev/null 2>&1 && \
       [[ -n "${BLUE:-}" && -n "${YELLOW:-}" && -n "${RED:-}" && -n "${GREEN:-}" ]]; then
      case "$level" in
        info)  print_status "$BLUE"   "$msg" ;;
        warn)  print_status "$YELLOW" "$msg" ;;
        error) print_status "$RED"   "$msg" ;;
        ok)    print_status "$GREEN" "$msg" ;;
        *)     echo "$msg" ;;
      esac
    else
      echo "$msg"
    fi
  }

  _brew_install_linux_deps() {
    _brew_print info "Installing necessary Linux dependencies for Homebrew..."

    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y build-essential procps curl file git
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf group install -y "Development Tools" || sudo dnf group install -y development-tools || true
      sudo dnf install -y procps-ng curl file git
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --needed --noconfirm base-devel procps-ng curl file git
    else
      _brew_print error "Unsupported Linux distribution for Homebrew dependencies."
      return 1
    fi
  }

  # Resolve Brewfile path using search order similar to the original script.
  # Usage: brew_resolve_brewfile_path [explicit_path] [start_dir]
  brew_resolve_brewfile_path() {
    local explicit_path="$1"
    local start_dir="${2:-$PWD}"

    # 1. Explicit argument wins
    if [[ -n "$explicit_path" ]]; then
      echo "$explicit_path"
      return 0
    fi

    # 2. Env override
    if [[ -n "${BREWFILE_PATH_OVERRIDE:-}" ]]; then
      echo "$BREWFILE_PATH_OVERRIDE"
      return 0
    fi

    # 3. Script-local Brewfile (next to this library)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local search_paths=()
    search_paths+=("$script_dir/Brewfile")

    # 4. XDG / config locations
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
      search_paths+=("$XDG_CONFIG_HOME/brew/Brewfile")
    fi
    search_paths+=("$HOME/.config/brew/Brewfile")

    # 5. Parent directory walk starting from start_dir
    local parent="$start_dir"
    while [[ "$parent" != "/" ]]; do
      search_paths+=("$parent/Brewfile")
      parent="$(dirname "$parent")"
    done

    local path
    for path in "${search_paths[@]}"; do
      if [[ -f "$path" ]]; then
        echo "$path"
        return 0
      fi
    done

    # 6. Fallback: Brewfile next to this library
    echo "$script_dir/Brewfile"
    return 0
  }

  # Detect existing Homebrew or install it if missing.
  # On success, sets BREW_PATH to the resolved brew binary and returns 0.
  brew_detect_or_install() {
    BREW_PATH=""
    local os
    os="$(uname -s)"

    if command -v brew >/dev/null 2>&1; then
      BREW_PATH="$(command -v brew)"
      _brew_print info "Homebrew already installed at $BREW_PATH; running brew update..."
      "$BREW_PATH" update || return 1
      return 0
    fi

    _brew_print info "Homebrew not found; installing Homebrew..."

    if [[ "$os" == "Darwin" ]]; then
      # Ensure Xcode Command Line Tools are installed
      if ! xcode-select -p &>/dev/null; then
        _brew_print info "Installing Xcode Command Line Tools..."
        xcode-select --install || true
        _brew_print warn "If prompted, please complete the Command Line Tools installation. Press Enter to continue once done."
        read -r _
      fi
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    elif [[ "$os" == "Linux" ]]; then
      _brew_install_linux_deps || return 1
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    else
      _brew_print error "Unsupported OS for Homebrew: $os"
      return 1
    fi

    local possible_paths=(
      "/opt/homebrew/bin/brew"
      "/usr/local/bin/brew"
      "$HOME/.linuxbrew/bin/brew"
      "/home/linuxbrew/.linuxbrew/bin/brew"
    )

    local p
    for p in "${possible_paths[@]}"; do
      if [[ -x "$p" ]]; then
        BREW_PATH="$p"
        break
      fi
    done

    if [[ -z "$BREW_PATH" ]]; then
      _brew_print error "Homebrew installation appears to have failed (brew not found)."
      return 1
    fi

    _brew_print ok "Homebrew installed at: $BREW_PATH"
    "$BREW_PATH" update || true
    return 0
  }

  brew_ensure_shellenv() {
    local brew_path="$1"
    if [[ -z "$brew_path" ]]; then
      _brew_print error "brew_ensure_shellenv: brew_path is empty"
      return 1
    fi

    eval "$("$brew_path" shellenv)"
    return 0
  }

  brew_install_brewfile() {
    local brew_path="$1"
    local brewfile_path="$2"

    if [[ -z "$brew_path" ]]; then
      _brew_print error "brew_install_brewfile: brew_path is empty"
      return 1
    fi

    if [[ -z "$brewfile_path" ]]; then
      _brew_print warn "No Brewfile path provided; skipping Brewfile installation."
      return 0
    fi

    if [[ ! -f "$brewfile_path" ]]; then
      _brew_print warn "No Brewfile found at $brewfile_path; skipping Brewfile installation."
      return 0
    fi

    _brew_print info "Installing packages from Brewfile at $brewfile_path..."
    "$brew_path" bundle --file="$brewfile_path" || return 1
    _brew_print ok "Brewfile packages installed."
    return 0
  }

  # -----------------------------
  # Forge-level operations
  # -----------------------------

  # forge_brew_install [brewfile_path]
  forge_brew_install() {
    local explicit_brewfile="$1"
    local start_dir="${FORGE_ROOT:-$PWD}"

    local brewfile
    brewfile="$(brew_resolve_brewfile_path "$explicit_brewfile" "$start_dir")" || return 1

    brew_detect_or_install || return 1
    brew_ensure_shellenv "$BREW_PATH" || return 1
    brew_install_brewfile "$BREW_PATH" "$brewfile" || return 1

    return 0
  }

  # forge_brew_update [brewfile_path]
  # Auto-installs Homebrew if missing, then updates brew and reapplies Brewfile.
  forge_brew_update() {
    local explicit_brewfile="$1"
    local start_dir="${FORGE_ROOT:-$PWD}"

    local brewfile
    brewfile="$(brew_resolve_brewfile_path "$explicit_brewfile" "$start_dir")" || return 1

    brew_detect_or_install || return 1
    brew_ensure_shellenv "$BREW_PATH" || return 1

    # After ensuring brew is up to date, reconcile with Brewfile.
    brew_install_brewfile "$BREW_PATH" "$brewfile" || return 1

    return 0
  }

  # forge_brew_uninstall [brewfile_path]
  # Uninstalls Homebrew and all brew-managed content using the official
  # uninstall script. Requires explicit confirmation from the user.
  forge_brew_uninstall() {
    # If brew is not installed, nothing to do.
    if ! command -v brew >/dev/null 2>&1; then
      _brew_print warn "Homebrew is not installed; nothing to uninstall."
      return 0
    fi

    _brew_print warn "This will uninstall Homebrew and all Homebrew-managed packages."
    printf "Are you sure you want to proceed? (y/N): "
    local confirm
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      _brew_print warn "Homebrew uninstall cancelled."
      return 0
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || {
      _brew_print error "Homebrew uninstall script failed. You may need to complete cleanup manually."
      return 1
    }

    _brew_print ok "Homebrew uninstall script completed."
    return 0
  }
fi
