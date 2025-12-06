#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# ----------------------
# Resolve Forge root dir
# ----------------------
# When running from the repo, forge.sh lives in the repo root (Forge root).
# When installed, the forge binary is copied to ~/.local/bin, while the
# cloned repo lives in ~/.local/share/forge. Prefer a nearby config.sh,
# otherwise fall back to the data directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$SCRIPT_DIR"

if [[ ! -f "$FORGE_ROOT/config.sh" ]]; then
    # Likely running from the installed binary in ~/.local/bin
    if [[ -f "$HOME/.local/share/forge/config.sh" ]]; then
        FORGE_ROOT="$HOME/.local/share/forge"
    fi
fi

# Source Dependencies (always from the resolved Forge root)
source "$FORGE_ROOT/config.sh"
source "$FORGE_ROOT/scripts/utils/_utils.sh"
source "$FORGE_ROOT/scripts/common/dotfiles.sh"
source "$FORGE_ROOT/scripts/common/homebrew/homebrew_lib.sh"

# --------------------------------------------------------------------------------------
# Subcommand handlers
# Register commands (name, description, handler-function)
# Optionally register per-command options for help output (command, option, description)
# --------------------------------------------------------------------------------------

# forge install
#
# Behavior:
#   forge install                -> full system install (Homebrew + Brewfile + dotfiles)
#   forge install --all          -> explicit full system install
#   forge install --brew         -> install Homebrew and Brewfile packages only
#   forge install --dotfiles     -> dotfiles only install
forge_cmd_install() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    ""|--all)
        print_status "$BLUE" "Installing dotfiles..."
        install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        print_status "$BLUE" "Installing Homebrew (if needed) and Brewfile packages..."
        forge_brew_install ""
        ;;
    --brew)
        print_status "$BLUE" "Installing Homebrew (if needed) and Brewfile packages..."
        forge_brew_install ""
        ;;
    --dotfiles)
        print_status "$BLUE" "Installing dotfiles only..."
        install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        ;;
    *)
        print_status "$RED" "Unknown option for 'install': $sub_arg"
        echo
        forge_print_help
        return 1
        ;;
  esac
}
forge_register_cmd "install" "Setup new system" forge_cmd_install
forge_register_cmd_opt "install" "--all" "Install full system (Homebrew, Brewfile, dotfiles)"
forge_register_cmd_opt "install" "--brew" "Install Homebrew and Brewfile packages only"
forge_register_cmd_opt "install" "--dotfiles" "Install dotfiles only"

# forge update
#
# Behavior:
#   forge update                -> run topgrade (system + tools update)
#   forge update --all          -> full update (system + Homebrew + Forge + dotfiles)
#   forge update --brew         -> update Homebrew and Brewfile packages only
#   forge update --self         -> update forge itself (repo + binary)
#   forge update --dotfiles     -> update managed dotfiles only
forge_cmd_update() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    "")
        # Default: delegate to topgrade if available (system/tools only)
        if command -v topgrade >/dev/null 2>&1; then
            print_status "$BLUE" "Running topgrade to update system and tools..."
            topgrade
        else
            print_status "$RED" "❌ 'topgrade' command not found. Please install topgrade first."
            return 1
        fi
        ;;
    --all)
        # Full update: system + Homebrew + Forge + dotfiles
        if command -v topgrade >/dev/null 2>&1; then
            print_status "$BLUE" "Running topgrade to update system and tools..."
            topgrade
        else
            print_status "$YELLOW" "⚠️ 'topgrade' not found; skipping system/tools update."
        fi
        print_status "$BLUE" "Updating Homebrew and Brewfile packages..."
        forge_brew_update "" || return 1
        print_status "$BLUE" "Updating Forge CLI and repository..."
        update "$FORGE_DATA_DIR" "$FORGE_BRANCH" "$FORGE_BIN_DIR" "$FORGE_BIN_PATH" || return 1
        print_status "$BLUE" "Updating dotfiles..."
        update_dotfiles "$DOTFILES_DIR" "$DOTFILES_BRANCH" || return 1
        ;;
    --brew)
        print_status "$BLUE" "Updating Homebrew and Brewfile packages..."
        forge_brew_update ""
        ;;
    --self)
        print_status "$BLUE" "Updating Forge CLI and repository..."
        update "$FORGE_DATA_DIR" "$FORGE_BRANCH" "$FORGE_BIN_DIR" "$FORGE_BIN_PATH"
        ;;
    --dotfiles)
        print_status "$BLUE" "Updating dotfiles..."
        update_dotfiles "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        ;;
    *)
        print_status "$RED" "Unknown option for 'update': $sub_arg"
        echo
        forge_print_help
        return 1
        ;;
  esac
}
forge_register_cmd "update" "Update system, forge, and related resources" forge_cmd_update
forge_register_cmd_opt "update" "--all" "Run full update (system, Homebrew, forge, and dotfiles)"
forge_register_cmd_opt "update" "--brew" "Update Homebrew and Brewfile packages only"
forge_register_cmd_opt "update" "--self" "Update the forge CLI and repository"
forge_register_cmd_opt "update" "--dotfiles" "Update managed dotfiles only"
forge_register_cmd_alias "up" "update"
forge_register_cmd_alias "u" "update"

# forge uninstall
#
# Behavior:
#   forge uninstall             -> full uninstall of Forge and dotfiles (Homebrew untouched)
#   forge uninstall --all       -> explicit full uninstall (Forge + dotfiles, Homebrew untouched)
#   forge uninstall --self      -> uninstall forge CLI and data only
#   forge uninstall --dotfiles  -> uninstall managed dotfiles only
#   forge uninstall --brew      -> uninstall Homebrew and all Homebrew-managed packages
forge_cmd_uninstall() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    ""|--all)
        print_status "$BLUE" "Uninstalling forge CLI, data, and managed dotfiles (Homebrew will be left installed)..."
        read -rp "Are you sure you want to uninstall Forge and its dotfiles? This action cannot be undone. (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            print_status "$YELLOW" "Uninstall cancelled."
            return 0
        fi
        uninstall_dotfiles "$DOTFILES_DIR"
        uninstall "$FORGE_BIN_PATH" "$FORGE_DATA_DIR"
        ;;
    --self)
        print_status "$BLUE" "Uninstalling forge CLI and repository..."
        uninstall "$FORGE_BIN_PATH" "$FORGE_DATA_DIR"
        ;;
    --dotfiles)
        print_status "$BLUE" "Uninstalling managed dotfiles..."
        uninstall_dotfiles "$DOTFILES_DIR"
        ;;
    --brew)
        print_status "$BLUE" "Uninstalling Homebrew and all Homebrew-managed packages..."
        forge_brew_uninstall ""
        ;;
    *)
        print_status "$RED" "Unknown option for 'uninstall': $sub_arg"
        echo
        forge_print_help
        return 1
        ;;
  esac
}
forge_register_cmd "uninstall" "Uninstall forge and related resources" forge_cmd_uninstall
forge_register_cmd_opt "uninstall" "--all" "Uninstall forge CLI, data, and dotfiles (Homebrew left installed)"
forge_register_cmd_opt "uninstall" "--self" "Uninstall only the forge CLI and data"
forge_register_cmd_opt "uninstall" "--dotfiles" "Uninstall managed dotfiles only"
forge_register_cmd_opt "uninstall" "--brew" "Uninstall Homebrew and all Homebrew-managed packages"

# forge help
forge_cmd_help() {
    forge_print_help
}
forge_register_cmd "help" "Show help" forge_cmd_help

# ======================
# --- Main Execution ---
# ======================
main() {
    local cmd="$1"; shift || true

    if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
        print_logo
        forge_print_help
        exit 0
    fi

    forge_run_cmd "$cmd" "$@"
}

# clear
main "$@"
