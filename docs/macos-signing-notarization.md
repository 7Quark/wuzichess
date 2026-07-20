# macOS 签名与公证说明

本文档适用于 `WuZiLauncher.app` 的正式分发流程，目标系统为 macOS 11 及以上。

## 当前交付状态

- 仓库内已经生成标准 `.app` 目录结构
- `.app` 已带 `Info.plist`、`CFBundleIdentifier` 与 `.icns` 图标
- 当前仓库中的 macOS 版本仍需在真实 macOS 环境上完成签名与公证

这是正常限制，因为签名、公证和最终校验必须在 Apple 生态环境中完成。

## 准备条件

你需要准备以下内容：

- 一台可用的 macOS 机器
- Apple Developer Program 账号
- `Xcode Command Line Tools`
- `Developer ID Application` 证书
- `notarytool` 可用凭据

检查工具：

```bash
xcode-select -p
xcrun notarytool --help
security find-identity -v -p codesigning
```

## 推荐分发格式

推荐先生成：

```text
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

原因：

- 能较稳定保留 `.app` 结构
- 比普通 zip 更不容易丢失可执行权限
- 更适合签名完成后的再次归档

## 本地签名步骤

先进入导出的 `.app` 所在目录，例如：

```bash
cd /path/to/WuZiLauncher-macos
```

执行签名：

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  WuZiLauncher.app
```

验证签名：

```bash
codesign --verify --deep --strict --verbose=2 WuZiLauncher.app
spctl --assess --type execute --verbose=4 WuZiLauncher.app
```

## 提交公证

建议先把签名后的 `.app` 打成 zip：

```bash
ditto -c -k --keepParent WuZiLauncher.app WuZiLauncher.app.zip
```

提交到 Apple Notary：

```bash
xcrun notarytool submit WuZiLauncher.app.zip \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD" \
  --wait
```

如果你已经保存了凭据配置，也可以改用：

```bash
xcrun notarytool submit WuZiLauncher.app.zip \
  --keychain-profile "YOUR_PROFILE" \
  --wait
```

## 回写公证票据

公证成功后执行：

```bash
xcrun stapler staple WuZiLauncher.app
```

再次校验：

```bash
spctl --assess --type execute --verbose=4 WuZiLauncher.app
codesign --verify --deep --strict --verbose=2 WuZiLauncher.app
```

## 建议的发布顺序

1. 在 Windows 环境完成前端与资源整理。
2. 在 macOS 环境重新执行打包，得到最新 `.app`。
3. 对 `.app` 做 `codesign`。
4. 提交 `notarytool` 公证。
5. `stapler staple` 回写票据。
6. 最终导出 `.tar.gz`、`.zip` 或 `.dmg` 上传到 GitHub Release。

## 当前项目的注意事项

- 该应用现在是单窗口桌面应用，界面由系统 `WebKit` 承载
- 运行时仍会在本机启动一个 `127.0.0.1` 本地服务，这是设计行为
- 运行日志默认写入 `~/Library/Application Support/WuZiGomoku`
- 如果签名后更改了 `.app` 内任意文件，需要重新签名

## 建议后续增强

- 在 macOS 机器上补一份自动化签名脚本
- 增加 GitHub Actions 的 macOS 打包与 notarization workflow
- 为发布版增加更精细的 DMG 视觉布局
