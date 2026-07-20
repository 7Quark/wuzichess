#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_JSON="$PROJECT_ROOT/package.json"
OUTPUT_DIR="$PROJECT_ROOT/dist/WuZiLauncher-macos"
APP_BUNDLE="$OUTPUT_DIR/WuZiLauncher.app"
RELEASE_DIR="$PROJECT_ROOT/release"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[WuZi] DMG packaging must be run on macOS."
  exit 1
fi

if [[ ! -f "$PACKAGE_JSON" ]]; then
  echo "[WuZi] package.json not found."
  exit 1
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "[WuZi] Missing app bundle: $APP_BUNDLE"
  echo "[WuZi] Build the macOS app package first."
  exit 1
fi

VERSION="$(PACKAGE_JSON_PATH="$PACKAGE_JSON" /usr/bin/python3 - <<'PY'
import json
import os
from pathlib import Path
print(json.loads(Path(os.environ["PACKAGE_JSON_PATH"]).read_text(encoding="utf-8"))["version"])
PY
)"

STAGE_DIR="$OUTPUT_DIR/dmg-stage"
DMG_NAME="WuZiLauncher-macos-v${VERSION}.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
mkdir -p "$RELEASE_DIR"
cp -R "$APP_BUNDLE" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

if [[ -f "$DMG_PATH" ]]; then
  rm -f "$DMG_PATH"
fi

hdiutil create \
  -volname "WuZi Gomoku" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE_DIR"
echo "[WuZi] DMG created: $DMG_PATH"
