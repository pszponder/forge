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
source "$FORGE_ROOT/scripts/common/setup_dirs.sh"
source "$FORGE_ROOT/scripts/common/setup_nerdfonts.sh"
source "$FORGE_ROOT/scripts/common/ssh/setup_ssh_config.sh"
source "$FORGE_ROOT/scripts/common/ssh/setup_ssh_keys.sh"

# --------------------------------------------------------------------------------------
# Subcommand handlers
# Register commands (name, description, handler-function)
# Optionally register per-command options for help output (command, option, description)
# --------------------------------------------------------------------------------------


# forge setup
#
forge_cmd_setup() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    "")
        print_status "$YELLOW" "⚠️ Please provide a valid flag for the 'setup' command."
        echo
        forge_print_help
        return 1
        ;;
    --interactive)
        # Interactive setup: prompt for each option
        prompt_and_execute "Setup developer directories?" setup_dirs
        prompt_and_execute "Setup SSH configuration and keys?" 'FORGE_SSH_NONINTERACTIVE=1 forge_setup_ssh_config; forge_setup_ssh_keys'
        prompt_and_execute "Setup dotfiles?" 'install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"'
        prompt_and_execute "Setup Homebrew and Brewfile packages?" 'forge_brew_install ""'
        prompt_and_execute "Setup Nerd Fonts?" setup_nerdfonts
        ;;
    # --common)
    #     print_status "$BLUE" "Setting up common configuration..."

    #     print_status "$BLUE" "Setting up developer directories..."
    #     setup_dirs

    #     print_status "$BLUE" "Setting up Homebrew (if needed) and Brewfile packages..."
    #     forge_brew_install ""

    #     print_status "$BLUE" "Setting up dotfiles..."
    #     install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"

    #     print_status "$BLUE" "Setting up Nerd Fonts..."
    #     setup_nerdfonts
    #     ;;
    --arch)
        print_status "$BLUE" "Setting up Arch Linux specific configuration..."
        print_status "$YELLOW" "⚠️ Arch Linux specific setup is not yet implemented."
        ;;
    --fedora)
        print_status "$BLUE" "Setting up Fedora specific configuration..."
        print_status "$YELLOW" "⚠️ Fedora specific setup is not yet implemented."
        ;;
    --fedora-atomic)
        print_status "$BLUE" "Setting up Fedora Atomic specific configuration..."
        print_status "$YELLOW" "⚠️ Fedora Atomic specific setup is not yet implemented."
        ;;
    --mac)
        print_status "$BLUE" "Setting up macOS specific configuration..."
        setup_dirs
        print_status "$BLUE" "Setting up Homebrew (if needed) and Brewfile packages..."
        forge_brew_install ""
        print_status "$BLUE" "Setting up dotfiles..."
        install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        ;;
    --ubuntu)
        print_status "$BLUE" "Setting up Ubuntu specific configuration..."
        print_status "$YELLOW" "⚠️ Ubuntu specific setup is not yet implemented."
        ;;
    --brew)
        print_status "$BLUE" "Setting up Homebrew (if needed) and Brewfile packages..."
        forge_brew_install ""
        ;;
    --dirs)
        print_status "$BLUE" "Setting up developer directories..."
        setup_dirs
        ;;
    --dotfiles)
        print_status "$BLUE" "Setting up dotfiles only..."
        install_dotfiles "$DOTFILES_REPO" "$DOTFILES_DIR" "$DOTFILES_BRANCH"
        ;;
    --fonts)
        print_status "$BLUE" "Setting up Nerd Fonts..."
        setup_nerdfonts
        ;;
    --ssh)
        print_status "$BLUE" "Initializing SSH configuration..."
        FORGE_SSH_NONINTERACTIVE=1 forge_setup_ssh_config
        print_status "$BLUE" "Creating default SSH keys..."
        forge_setup_ssh_keys
        ;;
    *)
        print_status "$RED" "Unknown option for 'setup': $sub_arg"
        echo
        forge_print_help
        return 1
        ;;
  esac
}
forge_register_cmd "setup" "Setup new system" forge_cmd_setup
forge_register_cmd_opt "setup" "--interactive" "Interactive full system setup (prompts for each option)"
# forge_register_cmd_opt "setup" "--common" "Full common setup (developer dirs, Homebrew & Brewfile, dotfiles, fonts)"
forge_register_cmd_opt "setup" "--arch" "Arch Linux specific setup"
forge_register_cmd_opt "setup" "--fedora" "Fedora specific setup"
forge_register_cmd_opt "setup" "--fedora-atomic" "Fedora Atomic specific setup"
forge_register_cmd_opt "setup" "--mac" "macOS specific setup"
forge_register_cmd_opt "setup" "--ubuntu" "Ubuntu specific setup"
forge_register_cmd_opt "setup" "--brew" "Setup Homebrew and Brewfile packages only"
forge_register_cmd_opt "setup" "--dotfiles" "Setup dotfiles only"
forge_register_cmd_opt "setup" "--ssh" "Initialize SSH config and generate default SSH keys"
forge_register_cmd_opt "setup" "--dirs" "Setup developer directories"
forge_register_cmd_opt "setup" "--fonts" "Setup Nerd Fonts (Linux/macOS)"
forge_register_cmd_alias "s" "setup"

# forge update
#
# Behavior:
#   forge update                -> run topgrade (system + tools update)
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

# forge new
#
# Behavior:
#   forge new --ssh     -> create a new SSH key
forge_cmd_new() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    --ssh)
        print_status "$BLUE" "Creating a new SSH key..."
        bash "$FORGE_ROOT/scripts/common/ssh/sshkeygen.sh"
        ;;
    *)
        print_status "$RED" "Unknown option for 'new': $sub_arg"
        echo
        forge_print_help
        return 1
        ;;
  esac
}
forge_register_cmd "new" "Create new resources" forge_cmd_new
forge_register_cmd_opt "new" "--ssh" "Create a new SSH key"
forge_register_cmd_alias "n" "new"

# forge uninstall
#
# Behavior:
#   forge uninstall             -> full uninstall of Forge and dotfiles (Homebrew untouched)
#   forge uninstall --all       -> interactive full uninstall (prompts for each option)
#   forge uninstall --self      -> uninstall forge CLI and data only
#   forge uninstall --dotfiles  -> uninstall managed dotfiles only
#   forge uninstall --brew      -> uninstall Homebrew and all Homebrew-managed packages
forge_cmd_uninstall() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    ""|--all)
        # Interactive uninstall: prompt for each option
        prompt_and_execute "Uninstall homebrew and all Homebrew-managed packages?" 'forge_brew_uninstall ""'
        prompt_and_execute "Uninstall managed dotfiles?" 'uninstall_dotfiles "$DOTFILES_DIR"'
        prompt_and_execute "Uninstall forge CLI and data?" 'uninstall "$FORGE_BIN_PATH" "$FORGE_DATA_DIR"'
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
forge_register_cmd_opt "uninstall" "--all" "Interactive full uninstall (prompts for each option)"
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
