#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNTIME_DIR="$PROJECT_ROOT/.runtime-macos"
STATE_FILE="$RUNTIME_DIR/launcher-state.txt"
PORT_RANGE_START=8765
PORT_RANGE_END=8775

mkdir -p "$RUNTIME_DIR"

find_free_port() {
  for port in $(seq "$PORT_RANGE_START" "$PORT_RANGE_END"); do
    if ! lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

open_browser() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  fi
}

if [[ -f "$STATE_FILE" ]]; then
  existing_pid="$(sed -n '1p' "$STATE_FILE" 2>/dev/null || true)"
  existing_url="$(sed -n '3p' "$STATE_FILE" 2>/dev/null || true)"
  if [[ -n "${existing_pid:-}" ]] && kill -0 "$existing_pid" >/dev/null 2>&1; then
    if [[ -n "${existing_url:-}" ]]; then
      echo "[WuZi] Existing instance detected: $existing_url"
      open_browser "$existing_url"
      exit 0
    fi
  fi
fi

PORT="$(find_free_port)"
if [[ -z "${PORT:-}" ]]; then
  echo "[WuZi] No free port found in range $PORT_RANGE_START-$PORT_RANGE_END."
  exit 1
fi

URL="http://127.0.0.1:$PORT/index.html"

if command -v node >/dev/null 2>&1; then
  nohup env PORT="$PORT" node "$PROJECT_ROOT/scripts/dev-server.mjs" >"$RUNTIME_DIR/server.out.log" 2>"$RUNTIME_DIR/server.err.log" &
  PID=$!
elif command -v python3 >/dev/null 2>&1; then
  nohup python3 -m http.server "$PORT" --bind 127.0.0.1 >"$RUNTIME_DIR/server.out.log" 2>"$RUNTIME_DIR/server.err.log" &
  PID=$!
else
  echo "[WuZi] Node.js or Python 3 is required on macOS."
  exit 1
fi

for _ in $(seq 1 20); do
  if curl -fsS "$URL" >/dev/null 2>&1; then
    {
      echo "$PID"
      echo "$PORT"
      echo "$URL"
    } >"$STATE_FILE"
    echo "[WuZi] Server ready: $URL"
    open_browser "$URL"
    exit 0
  fi
  sleep 0.4
done

kill "$PID" >/dev/null 2>&1 || true
echo "[WuZi] Server failed to start."
exit 1
