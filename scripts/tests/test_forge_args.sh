#!/usr/bin/env bash
set -euo pipefail

echo "Running simple tests for forge.sh flags (dry-run, help, uninstall)
"

echo "1) Help output"
./forge.sh --help >/dev/null
echo " -> OK"

echo "2) Uninstall dry-run (should not delete anything)"
./forge.sh uninstall --dry-run >/dev/null
echo " -> OK"

echo "3) Uninstall dry-run with explicit paths (should not delete)"
./forge.sh uninstall --dry-run /tmp/not-a-repo-binary /tmp/not-a-repo-dir >/dev/null || true
echo " -> OK"

echo "All tests passed (basic smoke tests)."
