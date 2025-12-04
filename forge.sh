#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# ----------------------
# Resolve Forge root dir
# ----------------------
# When running from the repo, forge.sh lives in the repo root.
# When installed, the forge binary is copied to ~/.local/bin, while the
# cloned repo lives in ~/.local/share/forge. Prefer a nearby scripts/
# directory, otherwise fall back to the data directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$SCRIPT_DIR"

if [[ ! -f "$FORGE_ROOT/scripts/config.sh" ]]; then
  # Likely running from the installed binary in ~/.local/bin
  if [[ -f "$HOME/.local/share/forge/scripts/config.sh" ]]; then
    FORGE_ROOT="$HOME/.local/share/forge"
  fi
fi

# Source Dependencies (always from the resolved Forge root)
# shellcheck disable=SC1090
source "$FORGE_ROOT/scripts/config.sh"
# shellcheck disable=SC1090
source "$FORGE_ROOT/scripts/utils/_utils.sh"

# ---------------
# Subcommand handlers
# ---------------

# forge install [--dotfiles]
forge_cmd_install() {
  local sub_arg="${1:-}"

  case "$sub_arg" in
    --dotfiles)
      print_status "$BLUE" "Installing dotfiles only (hook up your dotfiles installer here)."
      # TODO: call your dotfiles install function/script
      ;;
    "")
      print_status "$BLUE" "Installing full system (hook up your full installer here)."
      # TODO: call your full system install function/script
      ;;
    *)
      print_status "$RED" "Unknown option for 'install': $sub_arg"
      echo
      forge_print_help
      return 1
      ;;
  esac
}

# forge uninstall
forge_cmd_uninstall() {
  uninstall
}

# forge help
forge_cmd_help() {
  forge_print_help
}

# Register commands (name, description, handler-function)
forge_register_cmd "install"   "Install forge (use --dotfiles for dotfiles only)" forge_cmd_install
forge_register_cmd "uninstall" "Uninstall forge and its data"                     forge_cmd_uninstall
forge_register_cmd "help"      "Show help"                                       forge_cmd_help

# Register per-command options for help output
forge_register_cmd_opt "install" "--dotfiles" "Install dotfiles only"

main() {
  local cmd="$1"; shift || true

  if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
    print_logo
    forge_print_help
    exit 0
  fi

  forge_run_cmd "$cmd" "$@"
}

# ======================
# --- Main Execution ---
# ======================
# clear
main "$@"
