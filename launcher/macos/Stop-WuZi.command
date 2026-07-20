#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/WuZiLauncher.app/Contents/Resources/app/scripts/stop-wuzi-macos.sh"
