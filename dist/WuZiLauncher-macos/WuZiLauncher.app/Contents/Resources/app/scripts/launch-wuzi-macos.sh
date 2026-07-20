#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNTIME_DIR="${HOME}/Library/Application Support/WuZiGomoku"
STATE_FILE="$RUNTIME_DIR/launcher-state.txt"
LOG_OUT_FILE="$RUNTIME_DIR/server.out.log"
LOG_ERR_FILE="$RUNTIME_DIR/server.err.log"
PORT_RANGE_START=8765
PORT_RANGE_END=8775
OPEN_BROWSER=1
PRINT_STATE=0

for arg in "$@"; do
  case "$arg" in
    --no-open)
      OPEN_BROWSER=0
      ;;
    --print-state)
      PRINT_STATE=1
      ;;
  esac
done

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

print_state() {
  local pid="$1"
  local port="$2"
  local url="$3"

  echo "PID=$pid"
  echo "PORT=$port"
  echo "URL=$url"
  echo "STATE_FILE=$STATE_FILE"
  if [[ -n "${WUZI_APP_PID:-}" ]]; then
    echo "APP_PID=${WUZI_APP_PID:-}"
  fi
}

if [[ -f "$STATE_FILE" ]]; then
  existing_pid="$(sed -n '1p' "$STATE_FILE" 2>/dev/null || true)"
  existing_port="$(sed -n '2p' "$STATE_FILE" 2>/dev/null || true)"
  existing_url="$(sed -n '3p' "$STATE_FILE" 2>/dev/null || true)"
  existing_app_pid="$(sed -n '4p' "$STATE_FILE" 2>/dev/null || true)"

  if [[ -n "${existing_pid:-}" ]] && kill -0 "$existing_pid" >/dev/null 2>&1; then
    if [[ -n "${existing_url:-}" ]]; then
      echo "[WuZi] Existing instance detected: $existing_url"
      if [[ "$OPEN_BROWSER" -eq 1 ]]; then
        open_browser "$existing_url"
      fi
      if [[ "$PRINT_STATE" -eq 1 ]]; then
        print_state "$existing_pid" "$existing_port" "$existing_url"
        if [[ -n "${existing_app_pid:-}" ]]; then
          echo "APP_PID=$existing_app_pid"
        fi
      fi
      exit 0
    fi
  fi

  if [[ -n "${existing_app_pid:-}" ]] && kill -0 "$existing_app_pid" >/dev/null 2>&1; then
    kill "$existing_app_pid" >/dev/null 2>&1 || true
  fi

  rm -f "$STATE_FILE"
fi

PORT="$(find_free_port)"
if [[ -z "${PORT:-}" ]]; then
  echo "[WuZi] No free port found in range $PORT_RANGE_START-$PORT_RANGE_END."
  exit 1
fi

URL="http://127.0.0.1:$PORT/index.html"

if command -v node >/dev/null 2>&1; then
  nohup env PORT="$PORT" node "$PROJECT_ROOT/scripts/dev-server.mjs" >"$LOG_OUT_FILE" 2>"$LOG_ERR_FILE" &
  PID=$!
elif command -v python3 >/dev/null 2>&1; then
  nohup python3 -m http.server "$PORT" --bind 127.0.0.1 >"$LOG_OUT_FILE" 2>"$LOG_ERR_FILE" &
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
      echo "${WUZI_APP_PID:-}"
    } >"$STATE_FILE"
    echo "[WuZi] Server ready: $URL"
    if [[ "$OPEN_BROWSER" -eq 1 ]]; then
      open_browser "$URL"
    fi
    if [[ "$PRINT_STATE" -eq 1 ]]; then
      print_state "$PID" "$PORT" "$URL"
    fi
    exit 0
  fi
  sleep 0.4
done

kill "$PID" >/dev/null 2>&1 || true
echo "[WuZi] Server failed to start."
exit 1
