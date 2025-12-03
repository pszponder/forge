#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

## Detect script location and source helper utils (installed or repo)
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"

# Prefer installed helpers in $HOME; fallback to repo-relative
if [ -f "${HOME}/.local/share/forge/scripts/utils/_utils.sh" ]; then
	# shellcheck source=/dev/null
	source "${HOME}/.local/share/forge/scripts/utils/_utils.sh"
elif [ -f "${_script_dir}/scripts/utils/_utils.sh" ]; then
	# development copy inside the repo
	# shellcheck source=/dev/null
	source "${_script_dir}/scripts/utils/_utils.sh"
else
	echo "Warning: unable to locate helper scripts (_utils.sh). Some features may be limited."
fi

# Arg parsing helpers
if [ -f "${HOME}/.local/share/forge/scripts/utils/arg_utils.sh" ]; then
	# shellcheck source=/dev/null
	source "${HOME}/.local/share/forge/scripts/utils/arg_utils.sh"
elif [ -f "${_script_dir}/scripts/utils/arg_utils.sh" ]; then
	# shellcheck source=/dev/null
	source "${_script_dir}/scripts/utils/arg_utils.sh"
fi

# ======================
# --- Main Execution ---
# ======================
clear
print_logo

# -----------------
# Command-line flags
# -----------------
print_help() {
	cat <<'EOF'
USAGE: forge [OPTIONS]

Options:
	-h, --help        Show this help and exit
	--uninstall       Uninstall Forge (forwards flags to uninstall helper)
	-n, --dry-run     When combined with --uninstall: preview removals only
	-f, --force, --yes When combined with --uninstall: skip confirmation

Examples:
	# show help
	forge --help

	# preview uninstall (safe)
	forge --uninstall --dry-run

	# uninstall without confirmation (non-interactive)
	forge --uninstall --force

EOF
}

# If a help flag was passed, show it
if has_flag -h "$@" || has_flag --help "$@"; then
	print_help
	exit 0
fi

# If uninstall flag present forward arguments to uninstall script
if has_flag --uninstall "$@"; then
	# forward everything after --uninstall (or pass all args) to uninstall helper
	# Prefer installed uninstall helper; fall back to repo copy.
	uninstall_args=()
	# strip the top-level --uninstall token from args when forwarding
	for a in "$@"; do
		if [ "$a" = "--uninstall" ]; then
			continue
		fi
		uninstall_args+=("$a")
	done

	if [ -x "${HOME}/.local/share/forge/scripts/utils/uninstall.sh" ]; then
		bash "${HOME}/.local/share/forge/scripts/utils/uninstall.sh" "${uninstall_args[@]}"
	elif [ -x "${_script_dir}/scripts/utils/uninstall.sh" ]; then
		bash "${_script_dir}/scripts/utils/uninstall.sh" "${uninstall_args[@]}"
	else
		print_status "$YELLOW" "❌ uninstall helper not found."
		exit 2
	fi

	exit $?
fi

# no recognized top-level action -> launch interactive UI / main flow