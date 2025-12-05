# Uninstall helper for Forge
# This file is meant to be sourced (via _utils.sh), not executed directly.

# Resolve paths relative to this file so it works from any CWD.
this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${this_dir}/print_utils.sh"

# uninstall <bin_path> <data_dir>
# All configuration (paths, etc.) is passed in explicitly by the caller
# (e.g., forge.sh) instead of being read from global variables.
uninstall() {
    local bin_path="$1"
    local data_dir="$2"

    if [[ -z "$bin_path" || -z "$data_dir" ]]; then
        print_status "$RED" "❌ uninstall: missing arguments (bin_path, data_dir)."
        return 1
    fi

    # Remove forge binary
    if [[ -f "$bin_path" ]]; then
        rm "$bin_path"
        print_status "$GREEN" "✅ Removed forge binary from $bin_path."
    else
        print_status "$YELLOW" "⚠️ Forge binary not found at $bin_path."
    fi

    # Remove forge directory
    if [[ -d "$data_dir" ]]; then
        rm -rf "$data_dir"
        print_status "$GREEN" "✅ Removed forge directory from $data_dir."
    else
        print_status "$YELLOW" "⚠️ Forge directory not found at $data_dir."
    fi
    print_status "$GREEN" "✅ Uninstallation complete."
}
