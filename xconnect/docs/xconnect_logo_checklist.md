# XConnect App Logo Change Checklist

A comprehensive checklist for updating app logos/icons across all platforms.

---

## 🚀 Automated Icon Generation

### Prerequisites

| Requirement | Status |
|-------------|--------|
| ImageMagick installed (`sudo apt install imagemagick`) | [ ] |
| Source `res/icon.png` (1024×1024, square) | [ ] |
| Source `res/logo.svg` (XConnect logo) | [ ] |

### Quick Start

```bash
cd res/
./update_all_icons.sh
```

This script automatically:
1. Generates icons with appropriate padding for each platform
2. Copies icons to all required destinations  
3. Replaces SVG files with correct dimensions
4. Verifies all generated files

### Generation Scripts

| Script | Purpose |
|--------|---------|
| `res/gen_icon.sh` | Utility: generate single icon with configurable padding |
| `res/update_all_icons.sh` | Master: orchestrate all icon generation |

### Padding Values

| Icon Type | Padding | Visible Area | Reason |
|-----------|---------|--------------|--------|
| Android Foreground | 34% | 66% | Adaptive icon safe zone |
| Android Launcher/Round | 15% | 85% | Legacy launcher support |
| Android Notification | 15% | 85% | Monochrome (white) |
| Windows/Linux | 10% | 90% | Standard desktop icons |

---

## ✅ Auto-Generated Icons

These icons are automatically generated and replaced by `update_all_icons.sh`:

### 🤖 Android (`flutter/android/app/src/main/res/`)

| Type | Files | Status |
|------|-------|--------|
| Foreground | `mipmap-*/ic_launcher_foreground.png` (108-432px) | [x] Auto |
| Launcher | `mipmap-*/ic_launcher.png` (48-192px) | [x] Auto |
| Round | `mipmap-*/ic_launcher_round.png` (48-192px) | [x] Auto |
| Notification | `mipmap-*/ic_stat_logo.png` (24-96px, mono) | [x] Auto |

### 🪟 Windows

| File | Status |
|------|--------|
| `res/icon.ico` | [x] Auto |
| `res/tray-icon.ico` | [x] Auto |
| `flutter/windows/runner/resources/app_icon.ico` | [x] Auto |

### 🐧 Linux

| File | Status |
|------|--------|
| `res/32x32.png`, `res/64x64.png` | [x] Auto |
| `res/128x128.png`, `res/128x128@2x.png` | [x] Auto |
| `res/scalable.svg` (from logo.svg) | [x] Auto |

### 📦 Flutter Assets

| File | Status |
|------|--------|
| `flutter/assets/icon.svg` (150×150) | [x] Auto |

---

## ⚠️ Manual Updates Required

These files are NOT auto-generated and require manual update:

### 🤖 Android

| File | Purpose | Status |
|------|---------|--------|
| `drawable/floating_window.xml` | Floating window icon (vector) | [ ] Manual |
| `drawable/launch_background.xml` | Splash screen | [ ] Manual |
| `mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon config | [ ] Review |
| `values/ic_launcher_background.xml` | Background color | [ ] Review |

### 🍎 macOS (Not in script)

| File | Purpose | Status |
|------|---------|--------|
| `flutter/macos/Runner/AppIcon.icns` | macOS app icon | [ ] Manual |
| `res/mac-icon.png` | Source for macOS | [ ] Manual |
| `res/mac-tray-light-x2.png` | Light tray (44×44) | [ ] Manual |
| `res/mac-tray-dark-x2.png` | Dark tray (44×44) | [ ] Manual |

### 📱 iOS (Not in script)

| File | Purpose | Status |
|------|---------|--------|
| `flutter/ios/.../AppIcon.appiconset/` | All iOS icons | [ ] Manual |

### 📦 Flutter Assets

| File | Purpose | Status |
|------|---------|--------|
| `xConnect-Icon.png` | In-app icon | [ ] Manual |
| `xConnect-Logo.png` | In-app logo with text | [ ] Manual |
| `XconnectBackground.png` | Background/splash | [ ] Manual |

### 🎨 Source/Design Files

| File | Purpose | Status |
|------|---------|--------|
| `res/logo-header.svg` | Header logo with text | [ ] Manual |
| `res/design.svg` | Design reference | [ ] Manual |

---

## 💡 Tips

1. **Always update source files first**: `res/icon.png` and `res/logo.svg`
2. **Run the script after source update**: `./update_all_icons.sh`
3. **Android Adaptive Icons**: Logo must fit within 66% safe zone
4. **Notification icons**: Must be monochrome (white with transparency)
5. **macOS ICNS**: Use `iconutil` or [Image2icon](https://img2icnsapp.com/)
6. **iOS Icons**: Use [App Icon Generator](https://appicon.co/)
