# windows_android_build Branch - Complete File Changes

> [!CAUTION]
> **UNCOMMITTED SUBMODULE CHANGES**
> `libs/hbb_common/src/config.rs` changes are NOT committed!
> This is a Git submodule pointing to rustdesk/hbb_common.
> See: [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md)

**Branch:** windows_android_build  
**Base Version:** 1.4.2 (upstream master at 1.4.4)  
**Total Changed Files:** 116

---

## Summary by Category

| Category | Count | Risk |
|----------|-------|------|
| Flutter Dart | 25 | HIGH |
| Android Native | 20 | MEDIUM |
| Assets | 8 | LOW |
| Rust Libs | 5 | HIGH |
| Packaging/Res | 18 | LOW |
| Build/Config | 10 | MEDIUM |
| iOS/macOS | 8 | LOW |
| Windows | 5 | LOW |
| Other | 17 | LOW |

---

## 🔴 HIGH RISK - Core Custom Features

### libs/hbb_common/src/config.rs
**XConnect Configuration Overrides:**
- Line 46: `ORG = "com.xconnect"` (macOS)
- Line 61: `APP_NAME = "XConnect"`
- Lines 66-71: `OVERWRITE_SETTINGS`:
  ```rust
  OPTION_DIRECT_SERVER = "Y"     // Enable direct IP access
  OPTION_DIRECT_ACCESS_PORT = "12345"  // Default port
  ```

### flutter/lib/mobile/pages/home_page.dart
- Complete replacement of body with custom DeviceSelectionScreen
- UDP discovery integration
- xConnectOptions integration

### flutter/lib/desktop/pages/desktop_home_page.dart
- Same as mobile: DeviceSelectionScreen, DeviceCard
- Custom connection flow functions

### flutter/lib/common.dart
- `connect()` function: Added `isViewOnly`, `isBlankScreen` params
- Forwards to RemotePage

### flutter/lib/mobile/pages/remote_page.dart
- Added isViewOnly, isBlankScreen handling for xCtrl modes

### Additional Dependencies (pubspec.yaml)
```yaml
connectivity_plus: ^5.0.2  # Network change detection (for network_monitor.dart)
```

### Deep Link Scheme
- Android: `xconnect://` in AndroidManifest.xml (line 84)
- iOS: `xconnect://` in Info.plist

---

## 🟡 MEDIUM RISK - Feature Integration

### Flutter Dart Files (25)
| File | Change |
|------|--------|
| `flutter/lib/main.dart` | Splash screen, init |
| `flutter/lib/consts.dart` | Discovery port constants |
| `flutter/lib/common/widgets/dialog.dart` | UI modifications |
| `flutter/lib/desktop/pages/desktop_setting_page.dart` | Settings |
| `flutter/lib/desktop/pages/desktop_tab_page.dart` | Tab integration |
| `flutter/lib/desktop/pages/remote_tab_page.dart` | Remote page |
| `flutter/lib/desktop/widgets/material_mod_popup_menu.dart` | UI |
| `flutter/lib/mobile/pages/server_page.dart` | Server |
| `flutter/lib/mobile/pages/settings_page.dart` | Settings |
| `flutter/lib/utils/platform_channel.dart` | Platform calls |
| `flutter/lib/web/bridge.dart` | XConnectImpl |

### Model Files (RustdeskImpl → XConnectImpl rename)
| File | Change |
|------|--------|
| `flutter/lib/models/native_model.dart` | RustdeskImpl → XConnectImpl |
| `flutter/lib/models/platform_model.dart` | RustdeskImpl → XConnectImpl |
| `flutter/lib/models/web_model.dart` | RustdeskImpl → XConnectImpl |
| `flutter/lib/models/server_model.dart` | Whitespace fixes |
| `flutter/lib/models/file_model.dart` | Syntax fix (set homePath) |

### 100% New Custom Files (4)
| File | Purpose |
|------|---------|
| `flutter/lib/utils/xconnect_tcp_manager.dart` | TCP request/response |
| `flutter/lib/mobile/widgets/xConnectOptions.dart` | 4 modes dialog |
| `flutter/lib/desktop/widgets/xConnectOptions.dart` | 2 modes dialog |
| `flutter/lib/models/device_discovery_model.dart` | UDP broadcaster |

### Android Native (20)
| File | Change |
|------|--------|
| `MainActivity.kt` | Multicast lock |
| `AndroidManifest.xml` | Permissions, labels |
| `FloatingWindowService.kt` | "Show XConnect", **crash fix (2026-01-09)** |
| `common.kt` | Package rename |
| Other `.kt` files | Package rename to com.xconnect.app |

### FloatingWindowService Crash Fix (2026-01-09)
**Issue:** App crashed on close/reopen with "View not attached to window manager".
**Fix:** Wrapped `windowManager.removeView()` in try-catch in `onDestroy()`.

---

## 🟢 LOW RISK - Rename/Branding Only

### Assets (8 new)
```
flutter/assets/xConnectBackground.png
flutter/assets/xConnect-Logo.png
flutter/assets/xConnect-Icon.png
flutter/assets/devices-icon.png
flutter/assets/xBoard.png
flutter/assets/xCast.png
flutter/assets/xCtrl.png
flutter/assets/xCtrlView.png
```

### Rust Libs (5)
- `libs/hbb_common` - config.rs overrides
- `libs/portable/Cargo.toml` - Name change
- `libs/portable/generate.py` - xconnect
- `libs/portable/src/main.rs` - Imports
- `libs/remote_printer/src/lib.rs` - References

### Rust Source (Rename Only)
| File | Change |
|------|--------|
| `src/main.rs` | librustdesk → libxconnect |
| `src/service.rs` | librustdesk → libxconnect |
| `src/common.rs` | RUSTDESK_APPNAME → XCONNECT_APPNAME |
| `src/auth_2fa.rs` | ISSUER "RustDesk" → "XConnect" |
| `src/clipboard.rs` | com.rustdesk → com.xconnect |
| `src/platform/macos.rs` | com.carriez.rustdesk → com.xconnect.app |
| `src/platform/privileges_scripts/*` | macOS service/agent names |

### Build/Config (10)
- `Cargo.toml` - Name, lib, binary
- `Cargo.lock` - Deps
- `build.py` - Build script
- `examples/ipc.rs` - Import
- `.github/workflows/flutter-build.yml` - CI
- `.gitignore` - Ignore patterns
- `flutter/android/gradle/wrapper/gradle-wrapper.properties` - Gradle version
- `flutter/android/settings.gradle` - Gradle build settings
- `flutter/fix_android_plugins_macos.sh` - Validated as safe (script)

### Packaging (18)
- `res/DEBIAN/*` - Service names
- `res/rpm*.spec` - Package configs
- `res/PKGBUILD` - Arch
- `res/pacman_install` - Arch
- `res/osx-dist.sh` - macOS
- `res/msi/*` - Windows installer
- `flatpak/*` - Flatpak

### iOS/macOS (8)
- `flutter/ios/*` - Info.plist, project.pbxproj
- `flutter/macos/*` - Same

### Windows/Linux Build (10)
- `flutter/windows/CMakeLists.txt`
- `flutter/windows/runner/*`
- `flutter/linux/CMakeLists.txt`
- `flutter/linux/main.cc`
- `flutter/linux/my_application.cc`

---

## Feature-Specific Changes

### UDP Discovery Feature
| File | Addition |
|------|----------|
| `device_discovery_model.dart` | Device class, controller |
| `home_page.dart` (mobile/desktop) | DeviceSelectionScreen, DeviceCard |
| `MainActivity.kt` | Multicast lock |
| `AndroidManifest.xml` | CHANGE_WIFI_MULTICAST_STATE |
| `consts.dart` | Port constants |

### Connection Modes (xBoard, xCast, xCtrl, xCtrlView)
| File | Addition |
|------|----------|
| `xConnectOptions.dart` (2 files) | Mode selection UI |
| `home_page.dart` (2 files) | _shareAndroidToLinux, _shareLinuxToAndroid |
| `xconnect_tcp_manager.dart` | TCP communication |
| `common.dart` | isViewOnly, isBlankScreen params |
| `remote_page.dart` | View mode handling |

### Default Settings Override
| File | Change |
|------|--------|
| `libs/hbb_common/src/config.rs` | OVERWRITE_SETTINGS |

---

## Sync Checklist

When syncing from upstream v1.4.4:

- [ ] Use LLM with llm_sync_guide.md for conflict resolution
- [ ] Merge config.rs - preserve OVERWRITE_SETTINGS
- [ ] Merge home_page.dart - keep DeviceSelectionScreen
- [ ] Merge desktop_home_page.dart - keep DeviceSelectionScreen
- [ ] Merge common.dart - keep isViewOnly/isBlankScreen
- [ ] Merge MainActivity.kt - keep multicast lock
- [ ] Merge AndroidManifest.xml - keep permissions
- [ ] Merge main.dart - keep splash screen
- [ ] Verify new 100% custom files are intact
- [ ] Test UDP discovery
- [ ] Test all connection modes
