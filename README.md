# 五子棋

[English README](./README_EN.md)

一个纯本地、可离线运行的五子棋应用，支持人人对战与人机对战，并提供 Windows 与 macOS 两套分发方案。

## 当前状态

- 本地单机运行，无需联网
- 15 x 15 标准棋盘
- 人人对战
- 人机对战
- 胜负判定、和棋判定
- 悔棋、重置、退出
- Windows 原生 `exe` 启动器
- macOS 单窗口 `.app` 桌面版
- Windows / macOS 发布包
- 中英文说明文档

## 主要功能

### 人人对战

两位玩家在同一台设备上轮流落子，黑方先手，系统自动判断胜负与和棋。

### 人机对战

玩家执黑先手，AI 执白后手。AI 不是随机落子，具备基础攻防逻辑。

当前 AI 支持：

- 优先寻找成五点
- 优先拦截对手必胜点
- 识别活二、活三、冲四等常见棋型
- 在进攻与防守之间做基础权重判断

## 启动方式

### Windows

双击以下任意文件即可启动：

- `dist/WuZiLauncher/WuZiLauncher.exe`
- `dist/WuZiLauncher/Start-WuZi.bat`
- 根目录 `启动五子棋.bat`

特点：

- 不依赖 `Node.js`
- 不依赖 `Python`
- 自动启动本地服务
- 自动打开浏览器进入游戏

关闭方式：

- `dist/WuZiLauncher/Stop-WuZi.bat`
- 根目录 `关闭五子棋.bat`

### macOS

推荐使用发布包：

```text
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

解压后直接双击：

```text
WuZiLauncher.app
```

特点：

- 现在是单窗口桌面应用，不再依赖浏览器窗口
- 使用系统 `WebKit` 承载游戏界面
- 运行时会在本机启动 `127.0.0.1` 本地服务
- 需要 `Node.js` 或 `Python 3`
- 日志写入 `~/Library/Application Support/WuZiGomoku`

如果首次运行被系统拦截，请到“系统设置 -> 隐私与安全性”中允许执行。

## 发布包

当前发布产物：

```text
release/WuZiLauncher-win-x64-v1.1.0.zip
release/WuZiLauncher-macos-v1.1.0.zip
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

推荐：

- Windows 用户使用 `WuZiLauncher-win-x64-v1.1.0.zip`
- macOS 用户优先使用 `WuZiLauncher-macos-v1.1.0.tar.gz`

`tar.gz` 更适合保留 `.app` 结构与执行权限。

## 开发运行

### 运行 Web 开发版

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd start
```

访问：

```text
http://127.0.0.1:8765/index.html
```

### 运行测试

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd test
```

## 打包

### 生成图标

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run generate:icons
```

输出目录：

```text
assets/icons/
```

### 重新生成 Windows 启动器

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run publish:launcher
```

输出目录：

```text
dist/WuZiLauncher/
```

### 重新生成发布包

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run package:release
npm.cmd run package:macos
```

输出目录：

```text
release/
```

### 在 macOS 上生成 DMG

在真实 macOS 环境执行：

```bash
bash scripts/build-macos-dmg.sh
```

输出文件：

```text
release/WuZiLauncher-macos-v1.1.0.dmg
```

## 签名与公证

macOS 签名与公证说明见：

- [docs/macos-signing-notarization.md](./docs/macos-signing-notarization.md)
- [docs/macos-signing-notarization.en.md](./docs/macos-signing-notarization.en.md)

## 技术结构

### 前端

- `index.html`
- `src/web/app.js`
- `src/web/styles.css`

### 核心逻辑

- `assets/scripts/core/gomoku-rules.js`
- `assets/scripts/core/gomoku-engine.js`
- `assets/scripts/core/gomoku-ai.js`

### Windows 启动器

- `launcher/netfx/WuZiLauncher.cs`
- `launcher/netfx/AssemblyInfo.cs`
- `scripts/publish-launcher.ps1`

### macOS 启动器

- `launcher/macos/WuZiLauncher`
- `launcher/macos/WuZiLauncher.jxa`
- `launcher/macos/Info.plist`
- `scripts/publish-macos-release.ps1`
- `scripts/build-macos-dmg.sh`

### 图标资源

- `scripts/generate-icons.ps1`
- `assets/icons/wuzilauncher.ico`
- `assets/icons/wuzilauncher.icns`

## 说明

1. Windows 版仍然是浏览器承载界面，但已具备正式图标和版本信息。
2. macOS 版已经升级为单窗口桌面应用。
3. DMG 需要在真实 macOS 环境打包。
4. macOS 签名和公证必须在真实 macOS 环境完成。
