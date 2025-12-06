#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# CLI-friendly defaults (support non-interactive mode)
KEY_TYPE=""        # ed25519|rsa
KEY_PATH=""        # path to private key file
KEY_COMMENT=""     # comment for key
OVERWRITE=false     # whether to overwrite existing key without prompting
ADD_AGENT="auto"   # yes|no|auto - auto tries to detect
QUIET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)
      KEY_TYPE="${2:-}"; shift 2;;
    -p|--path)
      KEY_PATH="${2:-}"; shift 2;;
    -c|--comment)
      KEY_COMMENT="${2:-}"; shift 2;;
    -o|--overwrite)
      OVERWRITE=true; shift;;
    --add-agent)
      ADD_AGENT="yes"; shift;;
    --no-agent)
      ADD_AGENT="no"; shift;;
    -y|--yes)
      OVERWRITE=true; shift;;
    -q|--quiet)
      QUIET=true; shift;;
    --help|-h)
      cat <<'EOF'
Usage: sshkeygen.sh [OPTIONS]

Options:
  -t, --type <ed25519|rsa>   Type of key (default ed25519)
  -p, --path <file>          Path to private key file (e.g. ~/.ssh/id_ed25519)
  -c, --comment <text>       Key comment (e.g. email)
  -o, --overwrite            Overwrite existing file(s) without prompting
      --add-agent            Add new key to ssh-agent (same as interactive default)
      --no-agent             Do not add to ssh-agent
  -y, --yes                  Same as --overwrite
  -q, --quiet                Less output
  -h, --help                 Print this help
EOF
      exit 0;;
    *)
      echo "Unknown option: $1" >&2
      exit 1;;
  esac
done

# Prompt for the SSH key type, default to ed25519 (when not provided via flags)
if [[ -z "$KEY_TYPE" ]]; then
  read -p "Enter SSH key type (ed25519 or rsa) [default: ed25519]: " key_type
  key_type=${key_type,,}  # convert to lowercase
  key_type=${key_type:-ed25519}
else
  key_type=${KEY_TYPE,,}
fi

# Validate the key type
if [[ "$key_type" != "ed25519" && "$key_type" != "rsa" ]]; then
  echo "❌ Unsupported key type: $key_type"
  echo "Only 'ed25519' and 'rsa' are supported."
  exit 1
fi

# Prompt for the key file path (respect CLI choice)
if [[ -z "$KEY_PATH" ]]; then
  read -p "Enter SSH key path (default: ~/.ssh/id_${key_type}): " key_path
  key_path=${key_path:-~/.ssh/id_${key_type}}
else
  key_path="$KEY_PATH"
fi
key_path=$(eval echo "$key_path")  # Expand ~ to full path

# Prompt for a comment (respect CLI choice)
if [[ -z "$KEY_COMMENT" ]]; then
  read -p "Enter SSH key comment (e.g., your email or purpose): " key_comment
else
  key_comment="$KEY_COMMENT"
fi

# Check if the key file already exists
if [ -f "$key_path" ]; then
  if [[ "$OVERWRITE" == true ]]; then
    [[ "$QUIET" != true ]] && echo "⚠️ Overwriting existing key at $key_path"
  else
    echo "❗ A key already exists at $key_path"
    read -p "Do you want to overwrite it? [y/N]: " overwrite_choice
    if [[ ! "$overwrite_choice" =~ ^[Yy]$ ]]; then
      echo "Aborting."
      exit 1
    fi
  fi
fi

# Ensure the directory for the key exists
mkdir -p "$(dirname "$key_path")"

# Generate the SSH key
if [ "$key_type" == "rsa" ]; then
  ssh-keygen -t rsa -b 4096 -f "$key_path" -C "$key_comment"
else
  ssh-keygen -t ed25519 -f "$key_path" -C "$key_comment"
fi

# Success message
echo "✅ SSH key generated:"
echo "  Private Key: $key_path"
echo "  Public Key:  ${key_path}.pub"

if [[ "$ADD_AGENT" == "yes" ]]; then
  add_agent="y"
elif [[ "$ADD_AGENT" == "no" ]]; then
  add_agent="n"
else
  # auto: prompt interactively (interactive mode) or default no for quiet
  if [[ "$QUIET" == true ]]; then
    add_agent="n"
  else
    read -p "Add this key to the ssh-agent? [Y/n]: " add_agent
    add_agent=${add_agent,,}
    add_agent=${add_agent:-y}
  fi
fi

if [[ "$add_agent" == "y" || "$add_agent" == "yes" ]]; then
  echo "🚀 Adding key to ssh-agent..."

  # Start the ssh-agent if it's not already running
  eval "$(ssh-agent -s)"

  # macOS-specific: use Keychain integration if available
  if [[ "$OSTYPE" == "darwin"* ]]; then
    ssh-add --apple-use-keychain "$key_path"
    echo "✅ Key added to ssh-agent with macOS Keychain support"
  else
    ssh-add "$key_path"
    echo "✅ Key added to ssh-agent"
  fi
fi

# Try to copy public key to clipboard (skip when running quiet / non-interactive)
if [[ "$QUIET" == true ]]; then
  echo "📋 Generated public key: ${key_path}.pub"
else
  echo "📋 Attempting to copy public key to clipboard..."
  if command -v cb &>/dev/null; then
    cat "${key_path}.pub" | cb
    echo "✅ Public key copied to clipboard"
  elif command -v pbcopy &>/dev/null; then
    cat "${key_path}.pub" | pbcopy
    echo "✅ Public key copied to clipboard (macOS)"
  elif command -v xclip &>/dev/null; then
    cat "${key_path}.pub" | xclip -selection clipboard
    echo "✅ Public key copied to clipboard (xclip - Linux)"
  elif command -v xsel &>/dev/null; then
    cat "${key_path}.pub" | xsel --clipboard
    echo "✅ Public key copied to clipboard (xsel - Linux)"
  elif command -v wl-copy &>/dev/null; then
    cat "${key_path}.pub" | wl-copy
    echo "✅ Public key copied to clipboard (Wayland)"
  elif command -v clip.exe &>/dev/null; then
    cat "${key_path}.pub" | clip.exe
    echo "✅ Public key copied to clipboard (Windows/WSL)"
  else
    echo "⚠️ Could not detect a clipboard utility."
    echo "🔓 Here's your public key:"
    echo "----------------------------------------"
    cat "${key_path}.pub"
    echo "----------------------------------------"
    echo "You can manually copy it from above."
  fi
fi