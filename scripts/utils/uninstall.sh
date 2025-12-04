# Uninstall helper for Forge
# This file is meant to be sourced (via _utils.sh), not executed directly.

# Resolve paths relative to this file so it works from any CWD.
this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${this_dir}/../config.sh"
# shellcheck disable=SC1090
source "${this_dir}/print_utils.sh"

uninstall() {
    # Remove forge binary
    if [[ -f "$FORGE_BIN_PATH" ]]; then
        rm "$FORGE_BIN_PATH"
        print_status "$GREEN" "✅ Removed forge binary from $FORGE_BIN_PATH."
    else
        print_status "$YELLOW" "⚠️ Forge binary not found at $FORGE_BIN_PATH."
    fi

    # Remove forge directory
    if [[ -d "$FORGE_DATA_DIR" ]]; then
        rm -rf "$FORGE_DATA_DIR"
        print_status "$GREEN" "✅ Removed forge directory from $FORGE_DATA_DIR."
    else
        print_status "$YELLOW" "⚠️ Forge directory not found at $FORGE_DATA_DIR."
    fi
    print_status "$GREEN" "✅ Uninstallation complete."
}
