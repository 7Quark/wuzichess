# 五子棋

这是一个纯本地单机五子棋项目，当前包含：

- 人人对战
- 人机对战
- 标准 15 x 15 棋盘
- 胜负、和棋、悔棋、重置、退出
- AI 识别活二、活三、冲四，并优先处理成五与必防点

## 给用户的一键运行方式

最简单的方式：

- 双击 [启动五子棋.bat](/D:/CodeSpaces/WuZi/启动五子棋.bat)

如果已经生成了桌面启动器，它会优先启动：

- [WuZiLauncher.exe](/D:/CodeSpaces/WuZi/dist/WuZiLauncher/WuZiLauncher.exe)

关闭时双击：

- [关闭五子棋.bat](/D:/CodeSpaces/WuZi/关闭五子棋.bat)

`WuZiLauncher.exe` 的特点：

- 不依赖 `Node.js`
- 不依赖 `Python`
- 内置本地 HTTP 服务
- 自动选择 `8765-8775` 的空闲端口
- 自动打开浏览器
- 支持单实例复用
- 运行状态写入 `dist/WuZiLauncher/.runtime/`

## 开发者启动方式

直接运行 Web 开发版：

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd start
```

或者运行脚本版启动器：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\launch-wuzi.ps1
```

## 构建 exe 启动器

在项目根目录执行：

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run publish:launcher
```

构建输出目录：

```text
dist\WuZiLauncher\
```

生成可直接发送给用户的压缩包：

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd run package:release
```

输出目录：

```text
release\
```

当前实际使用的是：

- `scripts/publish-launcher.ps1`
- `launcher/netfx/WuZiLauncher.cs`

这套构建基于 Windows 自带的 `.NET Framework csc.exe`，不依赖 NuGet 下载。

## 自动化测试

```powershell
cd D:\CodeSpaces\WuZi
npm.cmd test
```

## Cocos Creator 3.7.3

项目中的 Cocos 入口位于 `assets/scripts/GomokuGame.ts`，FGUI 接入壳位于 `assets/scripts/FairyGuiShell.ts`。

使用 Cocos Creator 3.7.3 打开项目后：

1. 创建一个场景。
2. 创建空节点并挂载 `GomokuGame`。
3. 创建棋盘容器节点并拖给 `boardRoot`。
4. 如果已经接入 FairyGUI Cocos SDK，再把 `FairyGuiShell` 挂到场景根节点。

当前仓库已经具备完整对局逻辑与 AI 模块；如果要做成完整 Cocos 成品工程，下一步主要是补齐场景资源、FGUI 导出包和交互绑定。

## 目录

```text
assets/scripts/
  core/
    gomoku-ai.js
    gomoku-engine.js
    gomoku-rules.js
  FairyGuiShell.ts
  GomokuGame.ts
dist/
  WuZiLauncher/
    Start-WuZi.bat
    Stop-WuZi.bat
    QuickStart.txt
    WuZiLauncher.exe
launcher/
  netfx/
    WuZiLauncher.cs
scripts/
  dev-server.mjs
  launch-wuzi.ps1
  package-release.ps1
  publish-launcher.ps1
  spawn-server.cjs
  stop-wuzi.ps1
src/
  web/
    app.js
    styles.css
启动五子棋.bat
关闭五子棋.bat
index.html
tests/
  gomoku.test.js
```
