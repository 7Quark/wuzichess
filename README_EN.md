# Gomoku

A fully local, offline-capable Gomoku application with both Human vs Human and Human vs AI modes, plus a one-click Windows launcher.

## Overview

This project implements the Gomoku development requirements and currently includes:

- Fully local single-player deployment, no network required
- Standard 15 x 15 board
- Human vs Human mode
- Human vs AI mode
- Win detection
- Draw detection
- Undo, reset, and exit
- Windows `exe` launcher
- Ready-to-distribute ZIP release package

## Main Features

### Human vs Human

Two players take turns on the same device. Black moves first. The system automatically determines wins and draws.

### Human vs AI

The player uses black and moves first. The AI uses white. The AI is not random and includes basic offensive and defensive logic.

Current AI behavior includes:

- Prioritizing immediate winning moves
- Blocking the opponent's immediate winning moves
- Recognizing common patterns such as open two, open three, and rush four
- Balancing attack and defense with a basic scoring model

### One-Click Local Launch

The project supports two launch modes:

- Development mode: script-based launcher
- Release mode: `WuZiLauncher.exe`

The release build does not require `Node.js` or `Python`, which makes it suitable for direct end-user distribution.

## End-User Usage

### Run the exe directly

Double-click any of the following:

- `dist/WuZiLauncher/WuZiLauncher.exe`
- `dist/WuZiLauncher/Start-WuZi.bat`
- Root-level `启动五子棋.bat`

After startup, the launcher will:

- Automatically choose an available local port
- Start the local service in the background
- Open the game in the browser automatically

To stop it:

- Double-click `dist/WuZiLauncher/Stop-WuZi.bat`
- Or double-click the root-level `关闭五子棋.bat`

### Use the release ZIP package

Release package:

```text
release/WuZiLauncher-win-x64-v1.0.0.zip
```

After extraction, run:

```text
WuZiLauncher.exe
```

## Developer Usage

### Run the Web development version

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd start
```

Then open:

```text
http://127.0.0.1:8765/index.html
```

### Run the script-based launcher

```powershell
cd D:\CodeSpaces\WuZi
powershell -ExecutionPolicy Bypass -File .\scripts\launch-wuzi.ps1
```

### Run automated tests

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd test
```

## Packaging

### Rebuild the exe launcher

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run publish:launcher
```

Output directory:

```text
dist/WuZiLauncher/
```

Generated files:

- `WuZiLauncher.exe`
- `Start-WuZi.bat`
- `Stop-WuZi.bat`
- `QuickStart.txt`

### Rebuild the ZIP release package

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run package:release
```

Output directory:

```text
release/
```

## Technical Structure

### Frontend

- `index.html`: page entry
- `src/web/app.js`: UI interaction, mode switching, board rendering
- `src/web/styles.css`: styling

### Core Logic

- `assets/scripts/core/gomoku-rules.js`: board rules, move validation, win detection
- `assets/scripts/core/gomoku-engine.js`: game state machine, mode control, undo logic
- `assets/scripts/core/gomoku-ai.js`: AI move selection and attack/defense scoring

### Windows Launcher

- `launcher/netfx/WuZiLauncher.cs`: Windows `exe` launcher source
- `scripts/publish-launcher.ps1`: build script for the launcher
- `scripts/package-release.ps1`: ZIP packaging script

### Reserved Cocos Entry Points

- `assets/scripts/GomokuGame.ts`
- `assets/scripts/FairyGuiShell.ts`

These are reserved for future `Cocos Creator 3.7.3` and `FairyGUI` integration. The current application already runs independently and does not depend on the Cocos editor.

## Directory Structure

```text
assets/
  scripts/
    core/
      gomoku-ai.js
      gomoku-engine.js
      gomoku-rules.js
    FairyGuiShell.ts
    GomokuGame.ts
dist/
  WuZiLauncher/
    WuZiLauncher.exe
    Start-WuZi.bat
    Stop-WuZi.bat
    QuickStart.txt
launcher/
  netfx/
    WuZiLauncher.cs
release/
  WuZiLauncher-win-x64-v1.0.0.zip
scripts/
  dev-server.mjs
  launch-wuzi.ps1
  stop-wuzi.ps1
  publish-launcher.ps1
  package-release.ps1
  spawn-server.cjs
src/
  web/
    app.js
    styles.css
tests/
  gomoku.test.js
index.html
package.json
README.md
README_EN.md
启动五子棋.bat
关闭五子棋.bat
```

## Runtime Requirements

### Release Version

- Windows
- A working browser

No need to install:

- `Node.js`
- `Python`

### Development Version

- Windows
- Node.js

## Notes

1. The recommended build for end users is `dist/WuZiLauncher/WuZiLauncher.exe`
2. The recommended build for development and debugging is `npm.cmd start`
3. The repository still contains Cocos entry-point code, but the current delivered product is based on local Web runtime plus the Windows launcher

## Possible Future Enhancements

- Deeper AI search and difficulty levels
- A single-window desktop build instead of browser-based launch
- Custom app icon and installer package
- Full Cocos Creator scene and FairyGUI resource integration
