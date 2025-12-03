#!/usr/bin/env bash
# Small helpers for parsing simple command-line flags/values in shell.
# Keep it minimal and POSIX-friendly for use from other scripts.

# has_flag <flag> -- returns 0 if flag is present in the arguments
has_flag() {
  local flag="$1"; shift
  for a in "$@"; do
    if [ "$a" = "$flag" ]; then
      return 0
    fi
  done
  return 1
}

# get_flag_value <flag> <default> <args...> -- returns the next token after flag or the default
get_flag_value() {
  local flag="$1"; shift
  local default_val="$1"; shift
  local prev=""
  for a in "$@"; do
    if [ "$prev" = "$flag" ]; then
      printf "%s" "$a"
      return 0
    fi
    prev="$a"
  done
  # if we reach here, return default
  printf "%s" "$default_val"
  return 1
}

# normalize_args <args...> -- transforms POSIX-style combined options not implemented here
# Provided for future extension; currently it simply echoes args
normalize_args() {
  for a in "$@"; do
    printf '%s\n' "$a"
  done
}

export -f has_flag get_flag_value normalize_args
