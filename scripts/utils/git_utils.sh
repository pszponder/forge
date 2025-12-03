install_git() {
  if ! command -v git &>/dev/null; then
    print_status "$YELLOW" "🔧 Git not found. Installing Git..."

    OS="$(uname -s)"

    if [[ "$OS" == "Darwin" ]]; then
      # -----------------------------------------------------
      # macOS: use XCode Command Line Tools instead of Homebrew
      # -----------------------------------------------------
      if xcode-select -p &>/dev/null; then
        print_status "$GREEN" "🛠️ XCode Command Line Tools already installed."
      else
        print_status "$YELLOW" "📦 Installing XCode Command Line Tools..."
        xcode-select --install

        # Wait for installation to finish
        print_status "$YELLOW" "⏳ Waiting for CLI tools to finish installing..."
        until xcode-select -p &>/dev/null; do sleep 5; done

        print_status "$GREEN" "✅ XCode Command Line Tools installed!"
      fi

    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get update
      sudo apt-get install -y git

    elif [[ -f /etc/redhat-release ]]; then
      # -----------------------------------------------------
      # Fedora / RHEL / CentOS
      # -----------------------------------------------------
      if command -v dnf &>/dev/null; then
        sudo dnf install -y git
      else
        sudo yum install -y git
      fi

    elif [[ -f /etc/arch-release ]]; then
      # -----------------------------------------------------
      # Arch Linux
      # -----------------------------------------------------
      sudo pacman -Sy --noconfirm git

    else
      print_status "$RED" "❌ Unsupported OS. Please install Git manually."
      return 1
    fi

    # -----------------------------
    # Verify installation
    # -----------------------------
    if command -v git &>/dev/null; then
      print_status "$GREEN" "✅ Git installed successfully."
    else
      print_status "$RED" "❌ Git installation failed."
      return 1
    fi

  else
    print_status "$GREEN" "✅ Git is already installed."
  fi
}


clone_repo() {
  local repo=$1
  local target_dir=$2

  print_status "$YELLOW" "Cloning repository from https://github.com/${repo}.git to $target_dir..."
  rm -rf "$target_dir"
  git clone "https://github.com/${repo}.git" "${target_dir}" >/dev/null || { print_status "$RED" "❌ Failed to Clone."; exit 1; }
}


checkout_git_branch() {
  local repo_dir=$1
  local branch=$2

  print_status "$YELLOW" "Checking out branch/tag/version '$branch' in $repo_dir..."

  # Verify repo_dir exists
  if [ ! -d "$repo_dir" ]; then
    print_status "$RED" "❌ Provided path does not exist: $repo_dir"
    exit 1
  fi

  # Verify it's a Git repository
  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_status "$RED" "❌ Not a git repository: $repo_dir"
    exit 1
  fi

  # Use git -C so we don't change the caller's current working directory.
  # If 'origin' exists try fetch first, otherwise just attempt checkout.
  if git -C "$repo_dir" remote get-url origin >/dev/null 2>&1; then
    # Has remote origin — fetch and then checkout
    if git -C "$repo_dir" fetch origin "$branch" >/dev/null 2>&1 && \
       git -C "$repo_dir" checkout "$branch" >/dev/null 2>&1; then
      print_status "$GREEN" "✅ Checked out '$branch' in $repo_dir."
    else
      print_status "$RED" "❌ Failed to fetch/checkout branch: $branch in $repo_dir."
      exit 1
    fi
  else
    # No origin — just try a local checkout
    if git -C "$repo_dir" checkout "$branch" >/dev/null 2>&1; then
      print_status "$GREEN" "✅ Checked out local branch '$branch' in $repo_dir."
    else
      print_status "$RED" "❌ Failed to checkout local branch: $branch in $repo_dir."
      exit 1
    fi
  fi
}