#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNTIME_DIR="$PROJECT_ROOT/.runtime-macos"
STATE_FILE="$RUNTIME_DIR/launcher-state.txt"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "[WuZi] No running record found."
  exit 0
fi

PID="$(sed -n '1p' "$STATE_FILE" 2>/dev/null || true)"
if [[ -n "${PID:-}" ]] && kill -0 "$PID" >/dev/null 2>&1; then
  kill "$PID" >/dev/null 2>&1 || true
  sleep 0.5
fi

rm -f "$STATE_FILE"
echo "[WuZi] Stopped."
