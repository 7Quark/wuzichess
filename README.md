# 五子棋

[English README](./README_EN.md)

一个纯本地、可离线运行的五子棋应用，支持人人对战与人机对战，并提供 Windows / macOS 两套启动方案。

## 项目简介

本项目基于五子棋开发需求实现，当前已经完成：

- 本地单机运行，无需联网
- 15 x 15 标准棋盘
- 人人对战
- 人机对战
- 胜负判定
- 和棋判定
- 悔棋、重置、退出
- Windows `exe` 启动器
- macOS 脚本启动包
- 可直接分发的 ZIP 发布包

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

### 本地一键启动

项目提供两类启动方式：

- 开发版：脚本启动
- 发布版：`WuZiLauncher.exe` 启动

发布版不依赖 `Node.js` 或 `Python`，适合直接发给用户使用。

## 面向用户的使用方式

### 直接运行 exe

双击下面任意一个文件即可：

- `dist/WuZiLauncher/WuZiLauncher.exe`
- `dist/WuZiLauncher/Start-WuZi.bat`
- 根目录 `启动五子棋.bat`

程序启动后会：

- 自动选择可用本地端口
- 在后台启动本地服务
- 自动打开浏览器进入游戏界面

关闭方式：

- 双击 `dist/WuZiLauncher/Stop-WuZi.bat`
- 或双击根目录 `关闭五子棋.bat`

### 使用发布压缩包

发布包位置：

```text
release/WuZiLauncher-win-x64-v1.0.0.zip
release/WuZiLauncher-macos-v1.0.0.zip
release/WuZiLauncher-macos-v1.0.0.tar.gz
```

解压后直接运行：

```text
WuZiLauncher.exe
```

macOS 推荐优先使用：

```text
WuZiLauncher-macos-v1.0.0.tar.gz
```

原因：

- 更适合保留 `.app` 与脚本执行权限
- 解压后可直接双击 `WuZiLauncher.app`
- 运行日志会写入 `~/Library/Application Support/WuZiGomoku`

## 面向开发者的运行方式

### 运行 Web 开发版

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd start
```

启动后访问：

```text
http://127.0.0.1:8765/index.html
```

### 运行脚本版启动器

```powershell
cd D:\CodeSpaces\WuZi
powershell -ExecutionPolicy Bypass -File .\scripts\launch-wuzi.ps1
```

### 运行自动化测试

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd test
```

## 打包说明

### 重新生成 exe 启动器

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run publish:launcher
```

输出目录：

```text
dist/WuZiLauncher/
```

包含文件：

- `WuZiLauncher.exe`
- `Start-WuZi.bat`
- `Stop-WuZi.bat`
- `QuickStart.txt`
- `QuickStart_EN.txt`

### 重新生成发布压缩包

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run package:release
npm.cmd run package:macos
```

输出目录：

```text
release/
```

## 技术结构

### 前端界面

- `index.html`：页面入口
- `src/web/app.js`：界面交互、模式切换、棋盘渲染
- `src/web/styles.css`：样式定义

### 核心逻辑

- `assets/scripts/core/gomoku-rules.js`：棋盘规则、合法落子、胜负判定
- `assets/scripts/core/gomoku-engine.js`：对局状态机、模式控制、悔棋逻辑
- `assets/scripts/core/gomoku-ai.js`：AI 选点与攻防评分

### Windows 启动器

- `launcher/netfx/WuZiLauncher.cs`：Windows `exe` 启动器源码
- `scripts/publish-launcher.ps1`：构建启动器
- `scripts/package-release.ps1`：生成 ZIP 发布包

### Cocos 预留入口

- `assets/scripts/GomokuGame.ts`
- `assets/scripts/FairyGuiShell.ts`

这部分用于后续接入 `Cocos Creator 3.7.3` 和 `FairyGUI`。当前项目主体已经可独立运行，不依赖 Cocos 编辑器。

## 目录结构

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
    QuickStart_EN.txt
launcher/
  netfx/
    WuZiLauncher.cs
release/
  WuZiLauncher-macos-v1.0.0.zip
  WuZiLauncher-macos-v1.0.0.tar.gz
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

## 运行要求

### 发布版

- Windows 系统
- macOS
- 浏览器可用

不需要安装：

- Windows 版：不需要 `Node.js` / `Python`
- macOS 版：需要 `Node.js` 或 `Python 3`

### 开发版

- Windows
- Node.js

## 说明

1. 当前最适合 Windows 用户的版本是 `dist/WuZiLauncher/WuZiLauncher.exe`
2. 当前最适合 macOS 用户的版本是 `release/WuZiLauncher-macos-v1.0.0.tar.gz`
3. 当前最适合开发调试的版本是 `npm.cmd start`
4. 项目中保留了 Cocos 侧入口代码，但当前交付核心是本地 Web + 启动器方案

## 后续可扩展方向

- 增强 AI 搜索深度和难度分级
- 增加单窗口桌面版，而不是浏览器打开
- 增加自定义应用图标和安装包
- 接入完整 Cocos Creator 场景和 FairyGUI 资源
