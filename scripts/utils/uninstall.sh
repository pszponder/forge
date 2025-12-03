#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

uninstall() {
  # Allow optional parameters.
  # Usage:
  #   uninstall [BINARY_PATH] [FORGE_DIR]
  #   uninstall --binary BINARY_PATH --dir FORGE_DIR

  local binary_default="$HOME/.local/bin/forge"
  local dir_default="$HOME/.local/share/forge"
  local binary_path=""
  local forge_dir=""

  # Parse args (function may be called with its own args or forwarded from script: uninstall "$@")
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: uninstall [BINARY_PATH] [FORGE_DIR]
       uninstall --binary BINARY_PATH --dir FORGE_DIR

If not provided, defaults are:
  BINARY_PATH: $HOME/.local/bin/forge
  FORGE_DIR:   $HOME/.local/share/forge
EOF
        return 0
        ;;
      -b|--binary)
        binary_path="$2"
        shift 2
        ;;
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      -d|--dir|--directory)
        forge_dir="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -* )
        print_status "$YELLOW" "⚠️ Unknown option: $1"
        shift
        ;;
      *)
        # positional args: first -> binary, second -> dir
        if [ -z "$binary_path" ]; then
          binary_path="$1"
        else
          forge_dir="$1"
        fi
        shift
        ;;
    esac
  done

  # Set defaults if not provided
  binary_path=${binary_path:-$binary_default}
  forge_dir=${forge_dir:-$dir_default}

  print_status "$YELLOW" "🧹 Uninstalling Forge..."

  if [ "${dry_run:-false}" = true ]; then
    print_status "$YELLOW" "🔎 Dry-run enabled — no files will be deleted."
  fi

  # Remove Forge binary
  if [[ -f "$binary_path" ]]; then
    if [ "${dry_run:-false}" = true ]; then
      print_status "$YELLOW" "ℹ️ Would remove Forge binary: $binary_path"
    else
      rm "$binary_path"
      print_status "$GREEN" "✅ Removed Forge binary from $binary_path."
    fi
  else
    print_status "$YELLOW" "⚠️ Forge binary not found at $binary_path."
  fi

  # Remove Forge directory
  if [[ -d "$forge_dir" ]]; then
    if [ "${dry_run:-false}" = true ]; then
      print_status "$YELLOW" "ℹ️ Would remove Forge directory: $forge_dir"
    else
      rm -rf "$forge_dir"
      print_status "$GREEN" "✅ Removed Forge directory from $forge_dir."
    fi
  else
    print_status "$YELLOW" "⚠️ Forge directory not found at $forge_dir."
  fi

  print_status "$GREEN" "✅ Uninstallation complete."
}

uninstall "$@"