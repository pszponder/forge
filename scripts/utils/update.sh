# Update helper for Forge
# This file is meant to be sourced (via _utils.sh), not executed directly.

# Resolve paths relative to this file so it works from any CWD.
this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${this_dir}/../config.sh"
# shellcheck disable=SC1090
source "${this_dir}/print_utils.sh"
# shellcheck disable=SC1090
source "${this_dir}/git_utils.sh"

update() {
    local repo_dir="$FORGE_DATA_DIR"

    # Check if forge is installed
    if [[ ! -d "$repo_dir" ]]; then
        print_status "$RED" "❌ Forge not found at $repo_dir. Please install forge first."
        return 1
    fi

    # Check if it's a git repository
    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_status "$RED" "❌ $repo_dir is not a git repository."
        return 1
    fi

    print_status "$BLUE" "Updating forge repository..."

    # Fetch the latest changes
    if ! git -C "$repo_dir" fetch origin >/dev/null 2>&1; then
        print_status "$RED" "❌ Failed to fetch updates from remote."
        return 1
    fi

    # Checkout the branch
    if ! git -C "$repo_dir" checkout "$FORGE_BRANCH" >/dev/null 2>&1; then
        print_status "$RED" "❌ Failed to checkout branch: $FORGE_BRANCH"
        return 1
    fi

    # Pull the latest changes
    if ! git -C "$repo_dir" pull origin "$FORGE_BRANCH" >/dev/null 2>&1; then
        print_status "$RED" "❌ Failed to pull latest changes."
        return 1
    fi

    # Copy the updated forge.sh to the binary location
    if [[ -f "$repo_dir/forge.sh" && -d "$FORGE_BIN_DIR" ]]; then
        cp "$repo_dir/forge.sh" "$FORGE_BIN_PATH"
        chmod +x "$FORGE_BIN_PATH"
        print_status "$GREEN" "✅ Updated forge binary at $FORGE_BIN_PATH."
    else
        print_status "$YELLOW" "⚠️ Could not update forge binary (forge.sh or bin directory not found)."
    fi

    print_status "$GREEN" "✅ Forge updated successfully to the latest version."
}
