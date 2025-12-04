# Argument / command utilities for Forge
# Provides a small command registry used by forge.sh

# Guard so we only define things once, even if sourced multiple times
if [[ -z "${FORGE_ARG_UTILS_LOADED:-}" ]]; then
  FORGE_ARG_UTILS_LOADED=1

  # NOTE: This implementation is compatible with bash 3.2.
  # It intentionally avoids associative arrays and uses simple
  # indexed arrays plus linear lookups instead.

  # Registered commands (kept in parallel arrays)
  #   FORGE_CMD_NAMES[i] = name
  #   FORGE_CMD_DESCS[i] = description
  #   FORGE_CMD_FUNCS[i] = handler function name
  FORGE_CMD_NAMES=()
  FORGE_CMD_DESCS=()
  FORGE_CMD_FUNCS=()

  # Per-command options (parallel arrays)
  #   FORGE_OPT_CMDS[i]  = command name
  #   FORGE_OPT_FLAGS[i] = flag (e.g. --help)
  #   FORGE_OPT_DESCS[i] = description
  FORGE_OPT_CMDS=()
  FORGE_OPT_FLAGS=()
  FORGE_OPT_DESCS=()

  # Command aliases (parallel arrays)
  #   FORGE_ALIAS_ALIASES[i] = alias name
  #   FORGE_ALIAS_TARGETS[i] = canonical command name
  FORGE_ALIAS_ALIASES=()
  FORGE_ALIAS_TARGETS=()

  # Internal helpers ---------------------------------------------------------

  forge__find_cmd_index() {
    # forge__find_cmd_index <name>
    # echo index on stdout, or -1 if not found
    local search="$1"
    local i
    for i in "${!FORGE_CMD_NAMES[@]}"; do
      if [[ "${FORGE_CMD_NAMES[$i]}" == "$search" ]]; then
        echo "$i"
        return 0
      fi
    done
    echo "-1"
    return 1
  }

  forge__is_alias() {
    # forge__is_alias <name>
    local name="$1"
    local i
    for i in "${!FORGE_ALIAS_ALIASES[@]}"; do
      if [[ "${FORGE_ALIAS_ALIASES[$i]}" == "$name" ]]; then
        return 0
      fi
    done
    return 1
  }

  forge__aliases_for_cmd() {
    # forge__aliases_for_cmd <cmd>
    # echo space-separated aliases for the canonical command
    local cmd="$1"
    local i
    local result=""
    for i in "${!FORGE_ALIAS_ALIASES[@]}"; do
      if [[ "${FORGE_ALIAS_TARGETS[$i]}" == "$cmd" ]]; then
        if [[ -z "$result" ]]; then
          result="${FORGE_ALIAS_ALIASES[$i]}"
        else
          result+=" ${FORGE_ALIAS_ALIASES[$i]}"
        fi
      fi
    done
    echo "$result"
  }

  forge__opts_for_cmd() {
    # forge__opts_for_cmd <cmd>
    # echo indices (space-separated) into FORGE_OPT_* arrays
    local cmd="$1"
    local i
    local indices=""
    for i in "${!FORGE_OPT_CMDS[@]}"; do
      if [[ "${FORGE_OPT_CMDS[$i]}" == "$cmd" ]]; then
        if [[ -z "$indices" ]]; then
          indices="$i"
        else
          indices+=" $i"
        fi
      fi
    done
    echo "$indices"
  }

  # Public API ---------------------------------------------------------------

  # forge_register_cmd <name> <description> <handler-func-name>
  forge_register_cmd() {
    local name="$1"
    local desc="$2"
    local func="$3"

    FORGE_CMD_NAMES+=("$name")
    FORGE_CMD_DESCS+=("$desc")
    FORGE_CMD_FUNCS+=("$func")
  }

  # forge_register_cmd_opt <cmd> <flag> <description>
  forge_register_cmd_opt() {
    local cmd="$1"
    local flag="$2"
    local desc="$3"

    # Avoid duplicates for the same <cmd, flag>
    local i
    for i in "${!FORGE_OPT_CMDS[@]}"; do
      if [[ "${FORGE_OPT_CMDS[$i]}" == "$cmd" && "${FORGE_OPT_FLAGS[$i]}" == "$flag" ]]; then
        return 0
      fi
    done

    FORGE_OPT_CMDS+=("$cmd")
    FORGE_OPT_FLAGS+=("$flag")
    FORGE_OPT_DESCS+=("$desc")
  }

  # forge_register_cmd_alias <alias> <target_cmd>
  forge_register_cmd_alias() {
    local alias="$1"
    local target="$2"

    # Look up the target command
    local idx
    idx="$(forge__find_cmd_index "$target")" || true
    if [[ "$idx" == "-1" ]]; then
      echo "forge_register_cmd_alias: unknown target command '$target'" >&2
      return 1
    fi

    local func="${FORGE_CMD_FUNCS[$idx]}"
    local desc="${FORGE_CMD_DESCS[$idx]}"

    # Register alias as its own entry so forge_run_cmd can find it
    FORGE_CMD_NAMES+=("$alias")
    FORGE_CMD_DESCS+=("$desc")
    FORGE_CMD_FUNCS+=("$func")

    # Track alias mapping for help output
    FORGE_ALIAS_ALIASES+=("$alias")
    FORGE_ALIAS_TARGETS+=("$target")
  }

  # forge_run_cmd <name> [args...]
  forge_run_cmd() {
    local name="$1"; shift || true

    local idx
    idx="$(forge__find_cmd_index "$name")" || true
    if [[ "$idx" == "-1" ]]; then
      echo "Unknown command: $name" >&2
      echo >&2
      forge_print_help
      return 1
    fi

    local func="${FORGE_CMD_FUNCS[$idx]}"
    "$func" "$@"
  }

  forge_print_help() {
    echo "Usage: forge <command> [options]"
    echo
    echo "Commands:"

    local i
    for i in "${!FORGE_CMD_NAMES[@]}"; do
      local name="${FORGE_CMD_NAMES[$i]}"

      # Skip aliases here; they are listed under their canonical command
      if forge__is_alias "$name"; then
        continue
      fi

      local desc="${FORGE_CMD_DESCS[$i]}"
      printf "  %-15s %s\n" "$name" "$desc"

      # Print any registered options for this command
      local opt_indices
      opt_indices="$(forge__opts_for_cmd "$name")"
      if [[ -n "$opt_indices" ]]; then
        local idx_opt
        for idx_opt in $opt_indices; do
          local flag="${FORGE_OPT_FLAGS[$idx_opt]}"
          local odesc="${FORGE_OPT_DESCS[$idx_opt]}"
          printf "    %-17s %s\n" "$flag" "$odesc"
        done
      fi

      # Print any registered aliases for this command
      local aliases
      aliases="$(forge__aliases_for_cmd "$name")"
      if [[ -n "$aliases" ]]; then
        # Present as comma-separated list for readability
        local pretty_aliases=""
        local alias_name
        for alias_name in $aliases; do
          if [[ -z "$pretty_aliases" ]]; then
            pretty_aliases="$alias_name"
          else
            pretty_aliases+=", $alias_name"
          fi
        done
        printf "    %-17s %s\n" "aliases:" "$pretty_aliases"
      fi
    done
  }
fi
