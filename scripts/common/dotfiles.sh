install_dotfiles() {
    print_status "$BLUE" "⬇️ Installing dotfiles to $dest..."

    if ! command -v stow &> /dev/null; then
        print_status "$RED" "❌ 'stow' command not found. Please install GNU Stow first."
        return 1
    fi

    # Reference passed-in config values instead of global vars
    local repo="${DOTFILES_REPO:-}"
    local dest="${DOTFILES_DIR:-}"
    local branch="${DOTFILES_BRANCH:-main}"

    if [[ -d "$dest" ]]; then
        print_status "$BLUE" "📂 Dotfiles already exist. Pulling latest changes..."
        git -C "$dest" pull origin "$branch"
        if [[ $? -ne 0 ]]; then
            print_status "$RED" "❌ Failed to update existing dotfiles repository."
            return 1
        fi
        print_status "$GREEN" "✅ Successfully updated existing dotfiles repository."

        # Re-stow to ensure symlinks are current
        print_status "$BLUE" "🔗 Re-creating symlinks for dotfiles using stow."
        local stow_path="$(which stow)"
        (cd "$dest" && "$stow_path" -R dots)
        if [[ $? -ne 0 ]]; then
            print_status "$RED" "❌ Failed to re-create symlinks for dotfiles."
            return 1
        fi
        print_status "$GREEN" "✅ Successfully re-created symlinks for dotfiles."
    else
        print_status "$BLUE" "⬇️ Downloading dotfiles from $repo to $dest..."
        git clone "$repo" "$dest"

        # Change dotfiles remote URL to use SSH instead of HTTPS
        git -C "$dest" remote set-url origin "git@github.com:${repo#https://github.com/}"

        if [[ $? -ne 0 ]]; then
            print_status "$RED" "❌ Failed to clone dotfiles repository."
            return 1
        fi
        print_status "$GREEN" "✅ Successfully cloned dotfiles repository."

        # Use stow to symlink dotfiles
        print_status "$BLUE" "🔗 Creating symlinks for dotfiles using stow."
        local stow_path="$(which stow)"
        (cd "$dest" && "$stow_path" dots)
        if [[ $? -ne 0 ]]; then
            print_status "$RED" "❌ Failed to create symlinks for dotfiles."
            return 1
        fi
        print_status "$GREEN" "✅ Successfully created symlinks for dotfiles."
    fi
}

update_dotfiles() {
    print_status "$BLUE" "🔄 Updating dotfiles in $dest..."

    local dest="${DOTFILES_DIR:-}"
    local branch="${DOTFILES_BRANCH:-main}"

    if [[ ! -d "$dest" ]]; then
        print_status "$RED" "❌ Dotfiles directory $dest does not exist."
        return 1
    fi

    git -C "$dest" fetch origin
    git -C "$dest" checkout "$branch"
    git -C "$dest" pull origin "$branch"

    if [[ $? -ne 0 ]]; then
        print_status "$RED" "❌ Failed to update dotfiles."
        return 1
    fi
    print_status "$GREEN" "✅ Successfully updated dotfiles."

    # Use stow to re-create symlinks after update
    local stow_path="$(which stow)"
    print_status "$BLUE" "🔗 Re-creating symlinks for dotfiles using stow."
    (cd "$dest" && "$stow_path" -R dots)
    if [[ $? -ne 0 ]]; then
        print_status "$RED" "❌ Failed to re-create symlinks for dotfiles after update."
        return 1
    fi
    print_status "$GREEN" "✅ Successfully re-created symlinks for dotfiles after update."
}

uninstall_dotfiles() {
    print_status "$BLUE" "🗑️ Uninstalling dotfiles from $dest..."

    local dest="${DOTFILES_DIR:-}"

    if [[ ! -d "$dest" ]]; then
        print_status "$YELLOW" "⚠️ Dotfiles directory $dest does not exist. Nothing to uninstall."
        return 0
    fi

    # Use stow to remove symlinks
    local stow_path="$(which stow)"
    (cd "$dest" && "$stow_path" -D dots)
    if [[ $? -ne 0 ]]; then
        print_status "$RED" "❌ Failed to remove symlinks for dotfiles."
        return 1
    fi

    # Optionally, remove the dotfiles directory
    rm -rf "$dest"
    if [[ $? -ne 0 ]]; then
        print_status "$RED" "❌ Failed to remove dotfiles directory."
        return 1
    fi

    print_status "$GREEN" "✅ Successfully uninstalled dotfiles."
}