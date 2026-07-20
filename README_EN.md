# Gomoku

[中文说明](./README.md)

A fully local, offline-capable Gomoku application with Human vs Human and Human vs AI modes, plus Windows and macOS distribution options.

## Current Status

- Fully local, offline runtime
- Standard 15 x 15 board
- Human vs Human mode
- Human vs AI mode
- Win and draw detection
- Undo, reset, and exit
- Native Windows `exe` launcher
- Single-window macOS `.app` desktop build
- Windows and macOS release packages
- Chinese and English documentation

## Main Features

### Human vs Human

Two players take turns on the same device. Black moves first. The game automatically determines wins and draws.

### Human vs AI

The player uses black and moves first. The AI uses white. The AI is not random and includes basic offensive and defensive behavior.

Current AI behavior includes:

- Prioritizing immediate winning moves
- Blocking the opponent's immediate winning moves
- Recognizing common patterns such as open two, open three, and rush four
- Balancing attack and defense with a basic scoring model

## Launch Modes

### Windows

Start the app by double-clicking any of the following:

- `dist/WuZiLauncher/WuZiLauncher.exe`
- `dist/WuZiLauncher/Start-WuZi.bat`
- Root-level `启动五子棋.bat`

Characteristics:

- No `Node.js` required
- No `Python` required
- Starts the local service automatically
- Opens the game in the browser automatically

To stop it:

- `dist/WuZiLauncher/Stop-WuZi.bat`
- Root-level `关闭五子棋.bat`

### macOS

Recommended package:

```text
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

After extraction, double-click:

```text
WuZiLauncher.app
```

Characteristics:

- Now runs as a single-window desktop app instead of a browser launcher
- Uses system `WebKit` to host the game UI
- Starts a local `127.0.0.1` service at runtime
- Requires `Node.js` or `Python 3`
- Writes runtime logs to `~/Library/Application Support/WuZiGomoku`

If the first launch is blocked, allow it in System Settings -> Privacy & Security.

## Release Packages

Current release outputs:

```text
release/WuZiLauncher-win-x64-v1.1.0.zip
release/WuZiLauncher-macos-v1.1.0.zip
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

Recommended:

- Windows users: `WuZiLauncher-win-x64-v1.1.0.zip`
- macOS users: `WuZiLauncher-macos-v1.1.0.tar.gz`

`tar.gz` preserves the `.app` structure and executable permissions more reliably.

## Development

### Run the web development build

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd start
```

Open:

```text
http://127.0.0.1:8765/index.html
```

### Run tests

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd test
```

## Packaging

### Generate icons

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run generate:icons
```

Output:

```text
assets/icons/
```

### Rebuild the Windows launcher

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run publish:launcher
```

Output:

```text
dist/WuZiLauncher/
```

### Rebuild release packages

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run package:release
npm.cmd run package:macos
```

Output:

```text
release/
```

### Build a DMG on macOS

Run this on a real macOS machine:

```bash
bash scripts/build-macos-dmg.sh
```

Output:

```text
release/WuZiLauncher-macos-v1.1.0.dmg
```

## Signing and Notarization

See:

- [docs/macos-signing-notarization.md](./docs/macos-signing-notarization.md)
- [docs/macos-signing-notarization.en.md](./docs/macos-signing-notarization.en.md)

## Technical Structure

### Frontend

- `index.html`
- `src/web/app.js`
- `src/web/styles.css`

### Core Logic

- `assets/scripts/core/gomoku-rules.js`
- `assets/scripts/core/gomoku-engine.js`
- `assets/scripts/core/gomoku-ai.js`

### Windows Launcher

- `launcher/netfx/WuZiLauncher.cs`
- `launcher/netfx/AssemblyInfo.cs`
- `scripts/publish-launcher.ps1`

### macOS Launcher

- `launcher/macos/WuZiLauncher`
- `launcher/macos/WuZiLauncher.jxa`
- `launcher/macos/Info.plist`
- `scripts/publish-macos-release.ps1`
- `scripts/build-macos-dmg.sh`

### Icon Assets

- `scripts/generate-icons.ps1`
- `assets/icons/wuzilauncher.ico`
- `assets/icons/wuzilauncher.icns`

## Notes

1. The Windows build still uses the browser as the UI container, but now includes a formal icon and version metadata.
2. The macOS build has been upgraded to a single-window desktop app.
3. DMG packaging must be done on a real macOS environment.
4. macOS signing and notarization must be completed on a real macOS environment.
