# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Print colored status messages
print_status() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}


print_logo() {
    cat << "EOF"
    ______
   / ____/___  _________ ____
  / /_  / __ \/ ___/ __ `/ _ \
 / __/ / /_/ / /  / /_/ /  __/
/_/    \____/_/   \__, /\___/  a System Crafting Tool
                 /____/
EOF
}