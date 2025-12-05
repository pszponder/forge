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

# --------------------------------------------------------------------------------------
# Subcommand handlers
# Register commands (name, description, handler-function)
# Optionally register per-command options for help output (command, option, description)
# --------------------------------------------------------------------------------------

# forge install
#
# Behavior:
#   forge install              -> full system install (currently dotfiles)
#   forge install --all        -> explicit full system install
#   forge install --dotfiles   -> dotfiles only install
forge_cmd_install() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    ""|--all)
        print_status "$BLUE" "Installing full system (dotfiles and other managed resources)..."
        # For now, "full" means dotfiles; expand here as more components are added.
        install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"
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
forge_register_cmd_opt "install" "--all" "Install full system (dotfiles, etc.)"
forge_register_cmd_opt "install" "--dotfiles" "Install dotfiles only"

# forge update
#
# Behavior:
#   forge update              -> run topgrade (system + tools update)
#   forge update --all        -> full update (system + forge + dotfiles)
#   forge update --self       -> update forge itself (repo + binary)
#   forge update --dotfiles   -> update managed dotfiles only
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
        # Full update: system + forge + dotfiles
        if command -v topgrade >/dev/null 2>&1; then
            print_status "$BLUE" "Running topgrade to update system and tools..."
            topgrade
        else
            print_status "$YELLOW" "⚠️ 'topgrade' not found; skipping system/tools update."
        fi
        print_status "$BLUE" "Updating forge CLI and repository..."
        update "$FORGE_DATA_DIR" "$FORGE_BRANCH" "$FORGE_BIN_DIR" "$FORGE_BIN_PATH"
        print_status "$BLUE" "Updating dotfiles..."
        update_dotfiles "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        ;;
    --self)
        print_status "$BLUE" "Updating forge CLI and repository..."
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
forge_register_cmd_opt "update" "--all" "Run full update (system, forge, and dotfiles)"
forge_register_cmd_opt "update" "--self" "Update the forge CLI and repository"
forge_register_cmd_opt "update" "--dotfiles" "Update managed dotfiles only"
forge_register_cmd_alias "up" "update"
forge_register_cmd_alias "u" "update"

# forge uninstall
#
# Behavior:
#   forge uninstall           -> full uninstall (forge + dotfiles)
#   forge uninstall --all     -> explicit full uninstall
#   forge uninstall --self    -> uninstall forge CLI and data only
#   forge uninstall --dotfiles-> uninstall managed dotfiles only
forge_cmd_uninstall() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    ""|--all)
        print_status "$BLUE" "Uninstalling forge CLI, data, and managed dotfiles..."
        uninstall "$FORGE_BIN_PATH" "$FORGE_DATA_DIR"
        uninstall_dotfiles "$DOTFILES_DIR"
        ;;
    --self)
        print_status "$BLUE" "Uninstalling forge CLI and repository..."
        uninstall "$FORGE_BIN_PATH" "$FORGE_DATA_DIR"
        ;;
    --dotfiles)
        print_status "$BLUE" "Uninstalling managed dotfiles..."
        uninstall_dotfiles "$DOTFILES_DIR"
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
forge_register_cmd_opt "uninstall" "--all" "Uninstall forge CLI, data, and dotfiles"
forge_register_cmd_opt "uninstall" "--self" "Uninstall only the forge CLI and data"
forge_register_cmd_opt "uninstall" "--dotfiles" "Uninstall managed dotfiles only"

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
