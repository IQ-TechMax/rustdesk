# XConnect App Logo Change Checklist

A comprehensive checklist for updating app logos/icons across all platforms.

---

## 🤖 Android

### Launcher Icons (`flutter/android/app/src/main/res/`)

| Density | Path | Size | Status |
|---------|------|------|--------|
| mdpi | `mipmap-mdpi/ic_launcher.png` | 48×48 | [ ] |
| hdpi | `mipmap-hdpi/ic_launcher.png` | 72×72 | [ ] |
| xhdpi | `mipmap-xhdpi/ic_launcher.png` | 96×96 | [ ] |
| xxhdpi | `mipmap-xxhdpi/ic_launcher.png` | 144×144 | [ ] |
| xxxhdpi | `mipmap-xxxhdpi/ic_launcher.png` | 192×192 | [ ] |

### Round Launcher Icons (for devices with circular icons)

| Density | Path | Size | Status |
|---------|------|------|--------|
| mdpi | `mipmap-mdpi/ic_launcher_round.png` | 48×48 | [ ] |
| hdpi | `mipmap-hdpi/ic_launcher_round.png` | 72×72 | [ ] |
| xhdpi | `mipmap-xhdpi/ic_launcher_round.png` | 96×96 | [ ] |
| xxhdpi | `mipmap-xxhdpi/ic_launcher_round.png` | 144×144 | [ ] |
| xxxhdpi | `mipmap-xxxhdpi/ic_launcher_round.png` | 192×192 | [ ] |

### Adaptive Icons (Android 8.0+) - Foreground Layer

| Density | Path | Size | Status |
|---------|------|------|--------|
| mdpi | `mipmap-mdpi/ic_launcher_foreground.png` | 108×108 | [ ] |
| hdpi | `mipmap-hdpi/ic_launcher_foreground.png` | 162×162 | [ ] |
| xhdpi | `mipmap-xhdpi/ic_launcher_foreground.png` | 216×216 | [ ] |
| xxhdpi | `mipmap-xxhdpi/ic_launcher_foreground.png` | 324×324 | [ ] |
| xxxhdpi | `mipmap-xxxhdpi/ic_launcher_foreground.png` | 432×432 | [ ] |

### Adaptive Icon Configuration

| File | Purpose | Status |
|------|---------|--------|
| `mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon definition | [ ] Review |
| `mipmap-anydpi-v26/ic_launcher_round.xml` | Round adaptive icon definition | [ ] Review |
| `values/ic_launcher_background.xml` | Background color (`#ffffff`) | [ ] Update if needed |

### Notification Icon (monochrome, used in status bar)

| Density | Path | Size | Status |
|---------|------|------|--------|
| mdpi | `mipmap-mdpi/ic_stat_logo.png` | 24×24 | [ ] |
| hdpi | `mipmap-hdpi/ic_stat_logo.png` | 36×36 | [ ] |
| xhdpi | `mipmap-xhdpi/ic_stat_logo.png` | 48×48 | [ ] |
| xxhdpi | `mipmap-xxhdpi/ic_stat_logo.png` | 72×72 | [ ] |
| xxxhdpi | `mipmap-xxxhdpi/ic_stat_logo.png` | 96×96 | [ ] |

### Splash Screen / Launch Background

| File | Purpose | Status |
|------|---------|--------|
| `drawable/launch_background.xml` | Splash screen background | [ ] |
| `drawable-v21/launch_background.xml` | Splash screen (API 21+) | [ ] |
| `drawable/floating_window.xml` | Floating window icon | [ ] |

### Fastlane Store Icon

| File | Size | Status |
|------|------|--------|
| `fastlane/metadata/android/en-US/images/icon.png` | 512×512 | [ ] |

---

## 🪟 Windows

### Application Icons

| File | Purpose | Sizes Included | Status |
|------|---------|----------------|--------|
| `res/icon.ico` | Main app icon | 16,32,48,64,128,256 | [ ] |
| `res/tray-icon.ico` | System tray icon | 16,32 | [ ] |
| `flutter/windows/runner/resources/app_icon.ico` | Flutter Windows icon | 16,32,48,64,128,256 | [ ] |

### MSI Installer

| Directory | Purpose | Status |
|-----------|---------|--------|
| `res/msi/` | MSI installer resources | [ ] Check for icons |

### Portable Packer (Extraction Screen)

| File | Purpose | Size | Status |
|------|---------|------|--------|
| `libs/portable/src/res/label.png` | Branding label shown during extraction | 96×32 | [ ] |
| `libs/portable/src/res/spin.gif` | Loading spinner (optional to customize) | - | [ ] |

> **Note:** ICO files should contain multiple resolutions: 16×16, 32×32, 48×48, 64×64, 128×128, 256×256

---

## 🍎 macOS

### Application Icon

| File | Purpose | Status |
|------|---------|--------|
| `flutter/macos/Runner/AppIcon.icns` | macOS app icon (all sizes bundled) | [ ] |
| `res/mac-icon.png` | Source icon for macOS | [ ] |

### Tray Icons (Light & Dark Mode)

| File | Purpose | Size | Status |
|------|---------|------|--------|
| `res/mac-tray-light-x2.png` | Tray icon for dark menu bar | 44×44 (22pt @2x) | [ ] |
| `res/mac-tray-dark-x2.png` | Tray icon for light menu bar | 44×44 (22pt @2x) | [ ] |

> **Note:** Generate `AppIcon.icns` using `iconutil` or tools like [Image2icon](https://img2icnsapp.com/)

---

## 📱 iOS

### App Icon Set (`flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/`)

| File | Size | Status |
|------|------|--------|
| `Icon-App-20x20@1x.png` | 20×20 | [ ] |
| `Icon-App-20x20@2x.png` | 40×40 | [ ] |
| `Icon-App-20x20@3x.png` | 60×60 | [ ] |
| `Icon-App-29x29@1x.png` | 29×29 | [ ] |
| `Icon-App-29x29@2x.png` | 58×58 | [ ] |
| `Icon-App-29x29@3x.png` | 87×87 | [ ] |
| `Icon-App-40x40@1x.png` | 40×40 | [ ] |
| `Icon-App-40x40@2x.png` | 80×80 | [ ] |
| `Icon-App-40x40@3x.png` | 120×120 | [ ] |
| `Icon-App-60x60@2x.png` | 120×120 | [ ] |
| `Icon-App-60x60@3x.png` | 180×180 | [ ] |
| `Icon-App-76x76@1x.png` | 76×76 | [ ] |
| `Icon-App-76x76@2x.png` | 152×152 | [ ] |
| `Icon-App-83.5x83.5@2x.png` | 167×167 | [ ] |
| `Icon-App-1024x1024@1x.png` | 1024×1024 (App Store) | [ ] |
| `Contents.json` | Icon set manifest | [ ] Verify |

---

## 🐧 Linux

### Application Icons

| File | Size | Status |
|------|------|--------|
| `res/32x32.png` | 32×32 | [ ] |
| `res/64x64.png` | 64×64 | [ ] |
| `res/128x128.png` | 128×128 | [ ] |
| `res/128x128@2x.png` | 256×256 (HiDPI) | [ ] |
| `res/scalable.svg` | Scalable SVG | [ ] |
| `res/icon.png` | 512×512 source | [ ] |

### Desktop Entry Icons

| File | Purpose | Status |
|------|---------|--------|
| `res/xconnect.desktop` | Desktop entry (verify icon ref) | [ ] |
| `res/xconnect-link.desktop` | Link desktop entry | [ ] |

### Flatpak

| Directory | Purpose | Status |
|-----------|---------|--------|
| `flatpak/` | Flatpak icons/metadata | [ ] Check for icons |

---

## 📦 Flutter Assets (In-App Usage)

### Main Logo/Icon Files (`flutter/assets/`)

| File | Purpose | Status |
|------|---------|--------|
| `xConnect-Icon.png` | In-app icon | [ ] |
| `xConnect-Logo.png` | In-app logo | [ ] |
| `XconnectBackground.png` | Background/splash | [ ] |
| `icon.svg` | SVG icon | [ ] |
| `devices-icon.png` | Devices section icon | [ ] |

### Feature Images

| File | Purpose | Status |
|------|---------|--------|
| `xBoard.png` | Board feature image | [ ] |
| `xCast.png` | Cast feature image | [ ] |
| `xCtrl.png` | Control feature image | [ ] |
| `xCtrlView.png` | Control view image | [ ] |

---

## 🎨 Source/Design Files

| File | Purpose | Status |
|------|---------|--------|
| `res/logo.svg` | Source logo (SVG) | [ ] |
| `res/logo-header.svg` | Header logo | [ ] |
| `res/design.svg` | Design reference | [ ] |
| `res/rustdesk-banner.svg` | Banner (rename/update) | [ ] |

---

## 🔧 Icon Generation Scripts

| File | Purpose | Status |
|------|---------|--------|
| `res/gen_icon.sh` | Icon generation script | [ ] Update paths |

---

## 📋 Summary by Platform

| Platform | Total Files | Priority |
|----------|-------------|----------|
| Android | ~25 files | High |
| Windows | 3 files | High |
| macOS | 3 files | Medium |
| iOS | 16 files | Medium |
| Linux | ~8 files | High |
| Flutter Assets | ~10 files | High |

---

## 💡 Tips

1. **Start with highest resolution** (1024×1024 or SVG) and scale down
2. **Android Adaptive Icons**: Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html)
3. **iOS Icons**: Use [App Icon Generator](https://appicon.co/)
4. **Windows ICO**: Use GIMP or [ICO Convert](https://icoconvert.com/)
5. **macOS ICNS**: Use `iconutil` command or [Image2icon](https://img2icnsapp.com/)
6. **Notification icons** must be monochrome (white with transparency)
7. **Tray icons**: Provide light and dark variants for visibility on different backgrounds
