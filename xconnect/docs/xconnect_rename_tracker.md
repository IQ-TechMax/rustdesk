# XConnect Rename Tracker

Complete list of all files changed for RustDesk → XConnect rename.

---

## Quick Reference

| Old Value | New Value |
|-----------|-----------|
| `rustdesk` (binary) | `xconnect` |
| `librustdesk` (lib) | `libxconnect` |
| `RustDesk` (display) | `XConnect` |
| `RustdeskImpl` (class) | `XconnectImpl` |
| `.config/rustdesk` | `.config/xconnect` |
| `com.carriez.flutter_hbb` | `com.xconnect.app` |

---

## All Changed Files (54 files)

### Core Build
| File | Changes |
|------|---------|
| `Cargo.toml` | `name`, `default-run`, `[lib] name`, `OriginalFilename` |
| `libs/portable/Cargo.toml` | `name`, `OriginalFilename` |
| `build.py` | Binary names, lib paths |

### Rust Source
| File | Changes |
|------|---------|
| `src/main.rs` | `use librustdesk::*` → `libxconnect` |
| `src/service.rs` | `use librustdesk::*` → `libxconnect` |
| `src/auth_2fa.rs` | XConnect references |
| `src/clipboard.rs` | XConnect references |
| `src/platform/macos.rs` | XConnect references |
| `libs/hbb_common/src/config.rs` | `APP_NAME = "XConnect"` |
| `libs/portable/src/main.rs` | xconnect references |
| `libs/remote_printer/src/lib.rs` | xconnect references |

### Flutter/Dart - Core FFI
| File | Changes |
|------|---------|
| `flutter/lib/models/native_model.dart` | `DynamicLibrary.open`, `XconnectImpl` |
| `flutter/lib/models/web_model.dart` | `XconnectImpl` |
| `flutter/lib/models/platform_model.dart` | `XconnectImpl` |
| `flutter/lib/web/bridge.dart` | `XconnectImpl` |
| `flutter/lib/generated_bridge.dart` | Auto-generated, uses `Xconnect` |

### Flutter/Dart - UI
| File | Changes |
|------|---------|
| `flutter/lib/main.dart` | App name references |
| `flutter/lib/desktop/pages/desktop_home_page.dart` | UI text |
| `flutter/lib/desktop/widgets/xConnectOptions.dart` | Renamed widget file |
| `flutter/lib/mobile/pages/home_page.dart` | UI text |
| `flutter/lib/mobile/widgets/xConnectOptions.dart` | Renamed widget file |
| `flutter/lib/utils/xconnect_tcp_manager.dart` | Renamed util file |

### Flutter C++ Launchers
| File | Changes |
|------|---------|
| `flutter/linux/main.cc` | `XCONNECT_LIB_PATH`, `libxconnect.so` |
| `flutter/linux/my_application.cc` | App identifier |
| `flutter/windows/runner/main.cpp` | `LoadLibraryA("libxconnect.dll")` |

### CMake
| File | Changes |
|------|---------|
| `flutter/linux/CMakeLists.txt` | Lib paths |
| `flutter/windows/CMakeLists.txt` | Project name, binary name, lib paths |

### Android
| File | Changes |
|------|---------|
| `flutter/android/app/src/main/kotlin/ffi.kt` | `System.loadLibrary("xconnect")` |
| `flutter/android/app/src/main/kotlin/com/xconnect/app/*.kt` | Package rename (11 files) |

### iOS/macOS
| File | Changes |
|------|---------|
| `flutter/ios/Runner.xcodeproj/project.pbxproj` | `liblibxconnect.a` |
| `flutter/macos/Runner.xcodeproj/project.pbxproj` | `liblibxconnect.dylib` |

### Build Scripts
| File | Changes |
|------|---------|
| `flutter/build_fdroid.sh` | Lib paths |
| `res/osx-dist.sh` | DMG filename |
| `libs/portable/generate.py` | Magic strings, defaults |

### Windows MSI
| File | Changes |
|------|---------|
| `res/msi/CustomActions/RemotePrinter.cpp` | XConnect references |
| `res/msi/preprocess.py` | XConnect references |

### Linux Packaging
| File | Changes |
|------|---------|
| `build.py` | PAM file destination: `tmpdeb/etc/pam.d/xconnect` (was `rustdesk`) |
| `res/DEBIAN/prerm` | Service names |
| `res/DEBIAN/preinst` | Service names |
| `res/DEBIAN/postrm` | Config directory |
| `res/DEBIAN/postinst` | Service paths |
| `res/pacman_install` | All references |
| `res/PKGBUILD` | Package name, paths |
| `res/rpm.spec` | All references |
| `res/rpm-flutter.spec` | All references |
| `res/rpm-suse.spec` | All references |
| `res/rpm-flutter-suse.spec` | All references |

---

## Using After Upstream Sync

Since master is now at v1.4.4, use `git rebase master` on feature branches.

For any new files from upstream that need renaming:
1. Check the rename patterns in [llm_sync_guide.md](./llm_sync_guide.md)
2. Use LLM to help apply renames to new files
3. Search for remaining "rustdesk":
   ```bash
   grep -rn 'rustdesk' --include='*.rs' --include='*.dart' --include='*.cc' | grep -v rustdesk-org
   ```

---

## LLM Prompt for Renaming New Files

> Apply XConnect rename to this new upstream file.
> Use these patterns:
> - RustDesk → XConnect (display)
> - rustdesk → xconnect (binary)
> - librustdesk → libxconnect
> - com.carriez → com.xconnect
> - RustdeskImpl → XConnectImpl

