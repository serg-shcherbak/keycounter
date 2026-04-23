# KeyCount

A lightweight, native macOS menu bar application that tracks keystrokes and provides statistics while respecting your privacy.

## Features
- **SwiftData:** Native storage with zero external dependencies.
- **Privacy:** Counts keystrokes only. No text is ever recorded or stored.
- **Smart Mode:** Ignores modifiers and shortcuts. Subtracts Backspace.
- **Performance:** Ultra-low resource usage (CPU < 0.5%, RAM < 20MB).

## How to Build (Cloud)
The easiest way to get the app without installing Xcode:
1. Go to your GitHub repository.
2. Click the **Actions** tab.
3. Download the latest successful **Artifact** (KeyCount-Build).
4. Unzip and move `KeyCount.app` to your `/Applications` folder.
5. **To Launch:** Right-click `KeyCount.app` -> **Open**.
6. If it says "damaged", run this in Terminal: `xattr -cr /Applications/KeyCount.app`

## Local Development Requirements
- macOS 15.0+ (Sequoia)
- Xcode 16.0+
- Swift 6.0
