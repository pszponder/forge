# Source utility functions from this script's directory so sourcing works
# whether this file is sourced from the repo root or run directly.
# Use BASH_SOURCE to find the path to the current file when sourced.
this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${this_dir}/arg_utils.sh"
source "${this_dir}/git_utils.sh"
source "${this_dir}/print_utils.sh"
source "${this_dir}/uninstall.sh"
source "${this_dir}/update.sh"
