# Post-Merge Fixes Reference

This document tracks all fixes required after merging upstream RustDesk master into XConnect branches.

> [!IMPORTANT]
> **Apply these fixes AFTER resolving merge conflicts but BEFORE testing the build.**

---

## Summary: Sync from RustDesk v1.4.4 (2026-01-03/04)

| Branch | Conflicts | Post-Merge Fixes | Build Verified |
|--------|-----------|------------------|----------------|
| `windows_android_build` | 13 | 5 | Windows, Android ✅ |
| `linux_build` | 10 | 6 | Linux ✅ |

---

## Fix 1: hbb_common Submodule Update

**Applies to:** Both branches

**Problem:** After merge, compilation fails with missing functions:
```
error[E0432]: unresolved imports hbb_common::platform::linux::{get_wayland_displays, WaylandDisplayInfo}
error[E0425]: cannot find function is_kde_session in module hbb_common::platform::linux
```

**Cause:** The merge pulled new code requiring newer `hbb_common` functions, but submodule was at old commit.

**Solution:**
```bash
# Get the commit master expects
COMMIT=$(git ls-tree master libs/hbb_common | awk '{print $3}')
echo "Expected hbb_common commit: $COMMIT"

# Update submodule
cd libs/hbb_common
git fetch origin
git checkout $COMMIT
cd ../..
```

> [!WARNING]
> This will reset any local config.rs changes. Re-apply XConnect branding (Fix 2) after this step.

---

## Fix 2: config.rs XConnect Branding (Submodule)

**Applies to:** Both branches (with linux_build needing additional changes)

**File:** `libs/hbb_common/src/config.rs`

### Changes for BOTH branches:

```rust
// Line 46 (macOS ORG)
pub static ref ORG: RwLock<String> = RwLock::new("com.xconnect".to_owned());

// Line 61 (APP_NAME)
pub static ref APP_NAME: RwLock<String> = RwLock::new("XConnect".to_owned());

// Lines 66-71 (OVERWRITE_SETTINGS - enable direct server)
pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = {
    let mut map = HashMap::new();
    map.insert(keys::OPTION_DIRECT_SERVER.to_owned(), "Y".to_owned());
    map.insert(keys::OPTION_DIRECT_ACCESS_PORT.to_owned(), "12345".to_owned());
    RwLock::new(map)
};
```

### Additional changes for linux_build ONLY:

```rust
// 1. In Config struct (around line 200) - add field:
// XConnect: Custom device name for linux_build branch
#[serde(default, deserialize_with = "deserialize_string")]
pub x_connect_device_name: String,

// 2. Make Config::load() public (around line 572):
// XConnect: Made public for x_connect_device_name getter/setter in flutter_ffi.rs
pub fn load() -> Config {

// 3. Make Config::store() public (around line 615):
// XConnect: Made public for x_connect_device_name getter/setter in flutter_ffi.rs
pub fn store(&self) {
```

**Why linux_build needs extra changes:** The `src/flutter_ffi.rs` file has custom getter/setter functions that need public access to Config:
- `get_x_connect_device_name()` - uses `Config::load()`
- `set_x_connect_device_name(value)` - uses `Config::load()` and `Config::store()`

> [!NOTE]
> These changes are LOCAL to the submodule and NOT committed upstream.

---

## Fix 3: Portable Packer - Windows Crate Dependency

**Applies to:** Both branches

**Problem:** Windows build fails:
```
error[E0433]: failed to resolve: use of undeclared crate or module `windows`
   --> libs\portable\src\main.rs:116:9
```

**Cause:** Upstream added `is_windows_7()` function using `windows` crate, but dependency wasn't declared.

**Solution:** Add to `libs/portable/Cargo.toml`:
```toml
[target.'cfg(target_os = "windows")'.dependencies]
native-windows-gui = {version = "1.0", default-features = false, features = ["animation-timer", "image-decoder"]}
windows = { version = "0.61", features = ["Wdk_System_SystemServices", "Win32_System_SystemInformation"] }
```

---

## Fix 4: Portable Packer - Magic Identifier Mismatch

**Applies to:** Both branches (but already fixed in master after windows_android_build sync)

**Problem:** Windows installer crashes at runtime:
```
thread 'main' panicked at libs\portable\src\bin_reader.rs:77:13:
bin file is not valid!
```

**Cause:** `generate.py` writes `"xconnect"` as magic identifier, but `bin_reader.rs` was checking for `"rustdesk"`.

**Solution:** Update `libs/portable/src/bin_reader.rs`:
```rust
// Line 76: Change "rustdesk" → "xconnect"
if iden != "xconnect" {
    panic!("bin file is not valid!");
}

// Line 82: Change "rustdesk" → "xconnect"  
if iden == "xconnect" {
    base += IDENTIFIER_LENGTH;
    break;
}
```

**Verification:**
```bash
grep -n '"xconnect"\|"rustdesk"' libs/portable/src/bin_reader.rs
# Expected: Only "xconnect" references at lines 76 and 82
```

---

## Fix 5: Cargo.lock Restoration

**Applies to:** Both branches

**Problem:** Initial merge regenerates Cargo.lock, causing compilation failures:
```
error[E0433]: failed to resolve: could not find `types` in `pulse`
```

**Cause:** New Cargo.lock pulled `libpulse-binding` v2.30.1, but `rust-pulsectl` requires v2.28.1.

**Solution:** Restore Cargo.lock from master branch:
```bash
git show master:Cargo.lock > Cargo.lock
git add Cargo.lock
```

---

## Fix 6: Restored Files After Accidental Deletion

**Applies to:** linux_build (if files were accidentally emptied)

**Problem:** Some files may become empty (0 bytes) due to editor/git issues.

**Detection:**
```bash
wc -l Cargo.toml libs/portable/Cargo.toml flutter/android/app/build.gradle flutter/lib/web/bridge.dart
# All should have >0 lines
```

**Solution:** Restore from git staging area:
```bash
git show :Cargo.toml > Cargo.toml
git show :libs/portable/Cargo.toml > libs/portable/Cargo.toml
git show :flutter/android/app/build.gradle > flutter/android/app/build.gradle
git show :flutter/lib/web/bridge.dart > flutter/lib/web/bridge.dart
```

---

## Post-Fix Verification Checklist

After applying all fixes, verify:

### File Content Verification
```bash
# Core branding
head -5 Cargo.toml                                    # Should show: name = "xconnect", version = "1.4.4"
head -5 libs/portable/Cargo.toml                      # Should show: name = "xconnect-portable-packer"
grep 'applicationId\|minSdk' flutter/android/app/build.gradle  # Should show: com.xconnect.app, 23
grep "XConnect" flutter/lib/web/bridge.dart | head -1 # Should show: return 'XConnect';

# config.rs
grep -E "com.xconnect|XConnect" libs/hbb_common/src/config.rs  # Should show ORG and APP_NAME

# bin_reader.rs  
grep '"xconnect"' libs/portable/src/bin_reader.rs     # Should show 2 matches
```

### Build Verification
```bash
# Linux
cargo build --release
cd flutter && flutter build linux

# Windows (on Windows machine)
python3 build.py --flutter

# Android
cd flutter && flutter build apk --release
```

---

## Quick Command Reference

```bash
# 1. Update hbb_common submodule
COMMIT=$(git ls-tree master libs/hbb_common | awk '{print $3}')
cd libs/hbb_common && git fetch origin && git checkout $COMMIT && cd ../..

# 2. Apply config.rs changes (manual edit required)
# See Fix 2 above for exact changes

# 3. Restore Cargo.lock
git show master:Cargo.lock > Cargo.lock

# 4. Verify bin_reader.rs 
grep -n '"xconnect"\|"rustdesk"' libs/portable/src/bin_reader.rs

# 5. Stage all fixes
git add libs/hbb_common Cargo.lock libs/portable/Cargo.toml libs/portable/src/bin_reader.rs
```

---

## Related Documentation

- [fork_sync_procedure.md](./fork_sync_procedure.md) - Complete sync workflow
- [llm_sync_guide.md](./llm_sync_guide.md) - XConnect custom code patterns
- [merge_conflict_resolution.md](./merge_conflict_resolution.md) - Per-file conflict resolution
- [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md) - Submodule management
