# Argument / command utilities for Forge
# Provides a small command registry used by forge.sh

# Guard so we only define things once, even if sourced multiple times
if [[ -z "${FORGE_ARG_UTILS_LOADED:-}" ]]; then
  FORGE_ARG_UTILS_LOADED=1

  # Requires bash 4+ for associative arrays
  declare -A FORGE_CMDS_DESC
  declare -A FORGE_CMDS_FUNC
  FORGE_CMDS_LIST=()

  # forge_register_cmd <name> <description> <handler-func-name>
  forge_register_cmd() {
    local name="$1"
    local desc="$2"
    local func="$3"

    FORGE_CMDS_DESC["$name"]="$desc"
    FORGE_CMDS_FUNC["$name"]="$func"
    FORGE_CMDS_LIST+=("$name")
  }

  # forge_run_cmd <name> [args...]
  forge_run_cmd() {
    local name="$1"; shift || true
    local func="${FORGE_CMDS_FUNC["$name"]}"

    if [[ -z "$func" ]]; then
      echo "Unknown command: $name" >&2
      echo >&2
      forge_print_help
      return 1
    fi

    "$func" "$@"
  }

  forge_print_help() {
    echo "Usage: forge <command> [options]"
    echo
    echo "Commands:"
    for name in "${FORGE_CMDS_LIST[@]}"; do
      printf "  %-15s %s\n" "$name" "${FORGE_CMDS_DESC["$name"]}"
    done
  }
fi
