#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Source Dependencies
source "${HOME}/.local/share/forge/scripts/utils/_utils.sh"

# ======================
# --- Main Execution ---
# ======================

# -------------------
# Command-line flags
# -------------------
print_help() {
    clear
    print_logo
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

cmd=${1:-}

# If no subcommand or help flag show help
if [ -z "$cmd" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "--help" ]; then
	print_help
	exit 0
fi

case "$cmd" in
	uninstall)
		# Forward everything except the subcommand token to the uninstall helper.
		shift || true
		uninstall_args=("$@")

		# Known install layout — call uninstall helper at the canonical installed path
		uninstall_helper="${HOME}/.local/share/forge/scripts/utils/uninstall.sh"
		if [ -x "$uninstall_helper" ]; then
			bash "$uninstall_helper" "${uninstall_args[@]}"
		else
			print_status "$YELLOW" "❌ uninstall helper not found at $uninstall_helper"
			exit 2
		fi

		exit $?
		;;

	install)
		# forward to install.sh (repo or installed)
		shift || true
		install_args=("$@")
		# Known install layout — call install helper at the canonical installed path
		install_helper="${HOME}/.local/share/forge/install.sh"
		if [ -x "$install_helper" ]; then
			bash "$install_helper" "${install_args[@]}"
		else
			print_status "$YELLOW" "❌ install helper not found at $install_helper"
			exit 2
		fi
		exit $?
		;;

	*)
		print_status "$YELLOW" "⚠️ Unknown command: $cmd"
		print_help
		exit 1
		;;
esac

# no recognized top-level action -> launch interactive UI / main flow