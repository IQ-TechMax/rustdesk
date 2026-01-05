# XConnect LLM Sync Guide

This document helps LLMs understand XConnect's custom code and apply correct merge resolutions during upstream syncs.

> [!IMPORTANT]
> **After resolving conflicts, apply all fixes from [post_merge_fixes.md](./post_merge_fixes.md)!**

---

## Quick Reference: XConnect vs RustDesk

| Original | XConnect |
|----------|----------|
| `rustdesk` (binary) | `xconnect` |
| `RustDesk` (display) | `XConnect` |
| `librustdesk` | `libxconnect` |
| `RustdeskImpl` | `XconnectImpl` |
| `com.carriez.flutter_hbb` | `com.xconnect.app` |
| `com.carriez` (ORG) | `com.xconnect` |

---

## Critical Files to Preserve

These files contain XConnect-specific customizations. During merge conflicts, **keep ours** unless the conflict is trivial:

### Both Branches
| File | Purpose |
|------|---------|
| `Cargo.toml` | Package name: `xconnect`, version, lib name |
| `libs/portable/Cargo.toml` | `xconnect-portable-packer` |
| `libs/portable/src/bin_reader.rs` | Magic identifier: `"xconnect"` |
| `libs/portable/generate.py` | Magic strings, exe names |
| `flutter/android/app/build.gradle` | `com.xconnect.app`, `minSdkVersion 23` |
| `flutter/lib/web/bridge.dart` | `XconnectImpl`, `return 'XConnect'` |
| `res/PKGBUILD`, `res/rpm*.spec` | Linux packaging with XConnect |

### linux_build Only
| File | Purpose |
|------|---------|
| `src/flutter_ffi.rs` | `get/set_x_connect_device_name()` |
| `flutter/lib/main.dart` | 275+ lines of custom startup code |
| `flutter/lib/linux_tcp_listener/` | TCP listener for projector mode |
| `flutter/lib/network_monitor.dart` | Network monitoring |

### windows_android_build Only
| File | Purpose |
|------|---------|
| `flutter/lib/utils/xconnect_tcp_manager.dart` | Device discovery |
| `flutter/lib/models/device_discovery_model.dart` | Device model |
| `flutter/lib/mobile/widgets/xConnectOptions.dart` | Custom options UI |

---

## hbb_common/config.rs Changes

This is a **submodule** that needs local changes after each sync:

### Both Branches Need:
```rust
// Line 46
pub static ref ORG: RwLock<String> = RwLock::new("com.xconnect".to_owned());

// Line 61
pub static ref APP_NAME: RwLock<String> = RwLock::new("XConnect".to_owned());

// Lines 66-71
pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = {
    let mut map = HashMap::new();
    map.insert(keys::OPTION_DIRECT_SERVER.to_owned(), "Y".to_owned());
    map.insert(keys::OPTION_DIRECT_ACCESS_PORT.to_owned(), "12345".to_owned());
    RwLock::new(map)
};
```

### linux_build ALSO Needs:
```rust
// In Config struct (around line 200)
pub x_connect_device_name: String,

// Make these public (around lines 572 and 615)
pub fn load() -> Config { ...
pub fn store(&self) { ...
```

---

## Conflict Resolution Patterns

### Pattern 1: Version Numbers
**Keep XConnect version, update to upstream's version number**
```toml
# Conflict:
<<<<<<< HEAD
version = "1.4.2"
=======
version = "1.4.4"
>>>>>>> master

# Resolution:
version = "1.4.4"
```

### Pattern 2: Package Names
**Always keep XConnect names**
```toml
# Conflict:
<<<<<<< HEAD
name = "xconnect"
=======
name = "rustdesk"
>>>>>>> master

# Resolution:
name = "xconnect"
```

### Pattern 3: Application IDs
**Always keep XConnect IDs**
```gradle
# Always use:
applicationId "com.xconnect.app"
minSdkVersion 23
```

### Pattern 4: App Display Name
**Always keep XConnect**
```dart
// Always use:
return 'XConnect';
```

---

## Post-Merge Fixes Checklist

After all conflicts are resolved:

1. **[ ] hbb_common submodule** - Update to master's expected commit
2. **[ ] config.rs** - Apply XConnect branding
3. **[ ] linux_build only** - Add `x_connect_device_name` field, make load/store public
4. **[ ] portable/Cargo.toml** - Ensure `windows` crate dependency exists
5. **[ ] bin_reader.rs** - Verify `"xconnect"` magic identifier
6. **[ ] Cargo.lock** - Restore from master if dependency issues

See [post_merge_fixes.md](./post_merge_fixes.md) for detailed fix instructions.

---

## Verification Commands

```bash
# Check branding
grep -E "name = .xconnect|XConnect" Cargo.toml libs/hbb_common/src/config.rs

# Check bin_reader
grep '"xconnect"' libs/portable/src/bin_reader.rs

# Build tests
cargo build --release
cd flutter && flutter build linux/android/windows

# Scan for "rustdesk" that should be "xconnect"
grep -rn '"rustdesk"' --include="*.rs" --include="*.dart" | grep -v rustdesk-org
```

---

## Related Documents

- [post_merge_fixes.md](./post_merge_fixes.md) - **⭐ POST-MERGE FIXES**
- [fork_sync_procedure.md](./fork_sync_procedure.md) - Complete sync workflow
- [merge_conflict_resolution.md](./merge_conflict_resolution.md) - Per-file resolution
- [xconnect_rename_tracker.md](./xconnect_rename_tracker.md) - All renamed files
