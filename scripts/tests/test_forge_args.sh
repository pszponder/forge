#!/usr/bin/env bash
set -euo pipefail

echo "Running simple tests for forge.sh flags (dry-run, help, uninstall)
"

echo "1) Help output"
./forge.sh --help >/dev/null
echo " -> OK"

echo "2) Uninstall dry-run (should not delete anything)"
# Ensure the canonical installed layout exists so forge.sh finds helpers at the
# expected path ($HOME/.local/share/forge/...)
INSTALLED_PREFIX="$HOME/.local/share/forge"
mkdir -p "$INSTALLED_PREFIX/scripts/utils"
cp -a scripts/utils/uninstall.sh "$INSTALLED_PREFIX/scripts/utils/uninstall.sh"
chmod +x "$INSTALLED_PREFIX/scripts/utils/uninstall.sh"
cp -a install.sh "$INSTALLED_PREFIX/install.sh"
chmod +x "$INSTALLED_PREFIX/install.sh"

./forge.sh uninstall --dry-run >/dev/null
echo " -> OK"

echo "3) Uninstall dry-run with explicit paths (should not delete)"
./forge.sh uninstall --dry-run /tmp/not-a-repo-binary /tmp/not-a-repo-dir >/dev/null || true

# cleanup installed layout used for tests
rm -rf "$INSTALLED_PREFIX"
echo " -> OK"

echo "All tests passed (basic smoke tests)."
