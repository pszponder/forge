#!/usr/bin/env bash

set -eEo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSHKEYGEN="${SCRIPT_DIR}/sshkeygen.sh"

if [[ ! -x "$SSHKEYGEN" && -f "$SSHKEYGEN" ]]; then
  # ensure script is executable
  chmod +x "$SSHKEYGEN" || true
fi

create_key() {
  local path="$1"; shift
  local type="${1:-ed25519}"; shift
  local comment="${1:-}"; shift

  path=$(eval echo "$path")
  mkdir -p "$(dirname "$path")"

  local agent_flag="--no-agent"
  case "${FORGE_SSH_ADD_AGENT:-no}" in
    yes|YES|Yes|true|TRUE|1|y|Y)
      agent_flag="--add-agent"
      ;;
    *)
      agent_flag="--no-agent"
      ;;
  esac

  "$SSHKEYGEN" --type "$type" --path "$path" --comment "$comment" --overwrite "$agent_flag" -q
  echo "Created key: $path -> ${path}.pub"
}

forge_setup_ssh_keys() {
  echo "Creating multiple SSH keys (non-interactive)..."

  # Key specification list
  # Format for each entry: "<path>|<type>|<comment>"
  # - path: location for the private key (tilde expands)
  # - type: ed25519 | rsa (optional, defaults to ed25519)
  # - comment: key comment (optional)
  #
  # Primary configuration source is FORGE_SSH_KEYS_SPECS from config.sh.
  # If it is not set or empty, fall back to a built-in default list.
  local KEYS=()
  if [[ ${#FORGE_SSH_KEYS_SPECS[@]} -gt 0 ]]; then
    KEYS=("${FORGE_SSH_KEYS_SPECS[@]}")
  else
    KEYS=(
      "~/.ssh/key_default|ed25519|piotr@default"
      "~/.ssh/github/pszponder/key_github|ed25519|14116413+pszponder@users.noreply.github.com"
    )
  fi

  for spec in "${KEYS[@]}"; do
    # Split spec by '|' into path, type, comment (type/comment optional)
    IFS='|' read -r key_path key_type key_comment <<< "$spec"
    key_type=${key_type:-ed25519}
    key_comment=${key_comment:-}
    create_key "$key_path" "$key_type" "$key_comment"
  done
}

# Only run automatically when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  forge_setup_ssh_keys
fi
