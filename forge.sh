#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Source Dependencies
source "${HOME}/.local/share/forge/scripts/utils/_utils.sh"

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

		# search a set of candidate locations for the uninstall helper
		uninstall_candidates=(
			"${HOME}/.local/share/forge/scripts/utils/uninstall.sh"
			"${_script_dir}/scripts/utils/uninstall.sh"
			"${_script_dir}/../scripts/utils/uninstall.sh"
			"./scripts/utils/uninstall.sh"
		)

		found_uninstall=""
		for c in "${uninstall_candidates[@]}"; do
			if [ -x "$c" ]; then
				found_uninstall="$c"
				break
			fi
		done

		if [ -n "$found_uninstall" ]; then
			bash "$found_uninstall" "${uninstall_args[@]}"
		else
			print_status "$YELLOW" "❌ uninstall helper not found. Tried: ${uninstall_candidates[*]}"
			exit 2
		fi

		exit $?
		;;

	install)
		# forward to install.sh (repo or installed)
		shift || true
		install_args=("$@")
		# search candidate locations for install helper
		install_candidates=(
			"${HOME}/.local/share/forge/install.sh"
			"${_script_dir}/install.sh"
			"./install.sh"
		)
		found_install=""
		for c in "${install_candidates[@]}"; do
			if [ -x "$c" ]; then
				found_install="$c"
				break
			fi
		done
		if [ -n "$found_install" ]; then
			bash "$found_install" "${install_args[@]}"
		else
			print_status "$YELLOW" "❌ install helper not found. Tried: ${install_candidates[*]}"
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