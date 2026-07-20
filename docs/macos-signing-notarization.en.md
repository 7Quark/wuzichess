# macOS Signing and Notarization Guide

This document describes the production distribution flow for `WuZiLauncher.app` on macOS 11 and later.

## Current Status

- The repository already produces a standard `.app` bundle
- The app bundle now includes `Info.plist`, a bundle identifier, and an `.icns` icon
- Final signing and notarization still must be completed on a real macOS machine

That limitation is expected because Apple signing and notarization require Apple's tooling and ecosystem.

## Prerequisites

Prepare the following:

- A macOS machine
- An Apple Developer Program account
- `Xcode Command Line Tools`
- A `Developer ID Application` certificate
- `notarytool` credentials

Verify tooling:

```bash
xcode-select -p
xcrun notarytool --help
security find-identity -v -p codesigning
```

## Recommended Distribution Format

The preferred output is:

```text
release/WuZiLauncher-macos-v1.1.0.tar.gz
```

Reason:

- It preserves the `.app` structure more reliably
- It is less likely than a plain zip to lose executable permissions
- It works well as a final archive after signing

## Local Signing

Go to the directory that contains the exported `.app`, for example:

```bash
cd /path/to/WuZiLauncher-macos
```

Sign the bundle:

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  WuZiLauncher.app
```

Verify the signature:

```bash
codesign --verify --deep --strict --verbose=2 WuZiLauncher.app
spctl --assess --type execute --verbose=4 WuZiLauncher.app
```

## Submit for Notarization

First archive the signed app:

```bash
ditto -c -k --keepParent WuZiLauncher.app WuZiLauncher.app.zip
```

Submit it to Apple Notary:

```bash
xcrun notarytool submit WuZiLauncher.app.zip \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD" \
  --wait
```

If you already stored credentials, you can use a keychain profile instead:

```bash
xcrun notarytool submit WuZiLauncher.app.zip \
  --keychain-profile "YOUR_PROFILE" \
  --wait
```

## Staple the Ticket

After notarization succeeds:

```bash
xcrun stapler staple WuZiLauncher.app
```

Verify again:

```bash
spctl --assess --type execute --verbose=4 WuZiLauncher.app
codesign --verify --deep --strict --verbose=2 WuZiLauncher.app
```

## Recommended Release Sequence

1. Finalize frontend and assets on Windows.
2. Rebuild the `.app` on macOS with the latest sources.
3. Sign the `.app` with `codesign`.
4. Submit it with `notarytool`.
5. Staple the notarization ticket.
6. Upload the signed `.tar.gz`, `.zip`, or `.dmg` to GitHub Releases.

## Project-Specific Notes

- The macOS build is now a single-window desktop app backed by system `WebKit`
- It still starts a local `127.0.0.1` service at runtime by design
- Runtime logs are written to `~/Library/Application Support/WuZiGomoku`
- Any change inside the `.app` after signing requires signing again

## Suggested Next Improvements

- Add an automated signing helper script on macOS
- Add a GitHub Actions workflow for macOS packaging and notarization
- Offer a more polished DMG layout for release builds
