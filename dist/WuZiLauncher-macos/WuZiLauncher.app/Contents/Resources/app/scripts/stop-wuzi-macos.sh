#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${HOME}/Library/Application Support/WuZiGomoku"
STATE_FILE="$RUNTIME_DIR/launcher-state.txt"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "[WuZi] No running record found."
  exit 0
fi

PID="$(sed -n '1p' "$STATE_FILE" 2>/dev/null || true)"
APP_PID="$(sed -n '4p' "$STATE_FILE" 2>/dev/null || true)"

if [[ -n "${APP_PID:-}" ]] && kill -0 "$APP_PID" >/dev/null 2>&1; then
  kill "$APP_PID" >/dev/null 2>&1 || true
  sleep 0.5
  if kill -0 "$APP_PID" >/dev/null 2>&1; then
    kill -9 "$APP_PID" >/dev/null 2>&1 || true
  fi
fi

if [[ -n "${PID:-}" ]] && kill -0 "$PID" >/dev/null 2>&1; then
  kill "$PID" >/dev/null 2>&1 || true
  sleep 0.5
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill -9 "$PID" >/dev/null 2>&1 || true
  fi
fi

rm -f "$STATE_FILE"
echo "[WuZi] Stopped."
