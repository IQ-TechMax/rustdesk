# XConnect Fork - Merge Conflict Resolution Guide

> **Purpose:** Step-by-step guide for resolving merge conflicts when syncing XConnect fork with upstream RustDesk using `git merge`.
>
> **See also:** [fork_sync_procedure.md](./fork_sync_procedure.md) for the complete 4-phase sync workflow.

---

## Strategy Overview

### Why Merge Instead of Rebase?

| Approach | Pros | Cons |
|----------|------|------|
| **Rebase** | Linear history | Conflict per commit (180+ commits!), force-push required |
| **Merge** | Single conflict resolution, no force-push, easier abort | Creates merge commit |

**Decision:** Use **merge** for large syncs (50+ upstream commits).

---

## Conflict Categories

Before resolving any conflict, identify its category:

| Category | Description | Resolution Strategy |
|----------|-------------|---------------------|
| **Generated** | Lock files, auto-generated code | Accept upstream, regenerate |
| **Branding** | Package names, app names | Keep ours, apply naming |
| **Feature + Upstream** | Files with custom code + upstream improvements | Merge carefully |
| **100% Custom** | Files that don't exist in upstream | Keep ours entirely |
| **Upstream Structural** | File moved/renamed by upstream | Adapt to new location |

---

## Step-by-Step Conflict Resolution

> [!IMPORTANT]
> **Sync ONE branch at a time.** Complete all steps including user verification before moving to the next branch.
> **DO NOT PUSH until user approves the changes.**

### 1. Start the Merge

```bash
git checkout <branch>  # e.g., windows_android_build
git merge master
```

Git will list conflicting files. Work through them one by one.

### 2. For Each Conflict File

```bash
# View conflict markers
git diff --check  # Shows files with unresolved conflicts

# Open file and look for markers:
# <<<<<<< HEAD          (our version - XConnect)
# ... our code ...
# =======
# ... their code ...
# >>>>>>> master        (upstream version)
```

### 3. Apply Category-Specific Resolution

See [Per-File Resolution Matrix](#per-file-resolution-matrix-windows_android_build) below.

### 4. Mark as Resolved

```bash
git add <resolved_file>
```

### 5. LLM Verification (Before User Review)

```bash
# Build tests
cargo build --release
cd flutter && flutter pub get
flutter build android  # or linux, windows as appropriate

# Branding check - ensure no unwanted "rustdesk" references
grep -rn "rustdesk" --include="*.dart" --include="*.rs" --include="*.kt" \
  | grep -v "github.com/rustdesk" | grep -v ".git" | grep -v "Cargo.lock"
```

### 6. User Verification (REQUIRED)

**Notify user and ask them to verify:**
- [ ] App launches successfully
- [ ] UDP discovery works (port 64546)
- [ ] All 4 connection modes work (xBoard, xCast, xCtrl, xCtrlView)
- [ ] Splash screen shows XConnect branding
- [ ] No unexpected "RustDesk" text visible in UI

**Wait for user feedback before proceeding.**

### 7. Fix Reported Issues (If Any)

If user reports problems:
1. Identify the problematic file
2. Review the merge resolution
3. Use LLM with `llm_sync_guide.md` context to fix
4. Re-build and re-test
5. Return to Step 6 for user re-verification
6. **Repeat until user approves**

### 8. Complete Merge (After User Approval)

```bash
git commit -m "Merge master into <branch> - sync with upstream RustDesk vX.X.X"
```

### 9. Push to Remote (After User Approval)

```bash
git push origin <branch>
```

> [!CAUTION]
> **Only push after explicit user approval.** If issues are found after push, it's harder to fix.

---

## Per-File Resolution Matrix (windows_android_build)

| File | Category | Resolution | Details |
|------|----------|------------|---------|
| `Cargo.lock` | Generated | **Accept upstream** | Delete file, run `cargo build` to regenerate |
| `Cargo.toml` | Branding + Deps | **Merge** | Keep `xconnect` names, add new dependencies from upstream |
| `flutter/android/app/build.gradle` | Branding | **Keep ours** | Our package names, SDK versions; check for security patches |
| `MainApplication.kt` | Upstream Structural | **Move + Rename** | Copy upstream file to `com/xconnect/app/`, apply XConnect naming |
| `flutter/lib/mobile/pages/remote_page.dart` | Feature + Upstream | **Merge carefully** | Keep floating mouse/joystick widgets, integrate upstream improvements |
| `flutter/lib/utils/platform_channel.dart` | Feature + Upstream | **Merge** | Keep multicast lock methods, add new upstream channels |
| `flutter/lib/web/bridge.dart` | Branding | **Keep upstream** | Apply `XconnectImpl` naming to new code |
| `libs/portable/Cargo.toml` | Branding | **Keep ours** | Our `xconnect` naming, add new deps |
| `res/PKGBUILD` | Branding | **Keep ours** | All XConnect naming |
| `res/rpm-flutter-suse.spec` | Branding | **Keep ours** | All XConnect naming |
| `res/rpm-flutter.spec` | Branding | **Keep ours** | All XConnect naming |
| `res/rpm.spec` | Branding | **Keep ours** | All XConnect naming |
| `src/platform/privileges_scripts/agent.plist` | Branding | **Keep ours** | XConnect naming; check for security changes |

---

## Detailed Resolution Guides

### Category: Generated Files (`Cargo.lock`, `pubspec.lock`)

```bash
# Option 1: Take upstream and regenerate
git checkout --theirs Cargo.lock
cargo build --release  # Regenerates with correct dependencies

# Option 2: If build fails, delete and regenerate
rm Cargo.lock
cargo build --release
```

### Category: Branding Files (Package Specs)

For files like `PKGBUILD`, `rpm-*.spec`:

```bash
# Almost always keep ours - they have XConnect naming
git checkout --ours res/PKGBUILD
git checkout --ours res/rpm-flutter.spec
git checkout --ours res/rpm-flutter-suse.spec
git checkout --ours res/rpm.spec
```

### Category: Feature + Upstream (Complex Merge)

For files like `remote_page.dart`:

1. **Identify custom code blocks** (marked with `// XCONNECT:` comments or from `llm_sync_guide.md`)
2. **Use LLM** with the template below
3. **Test** after resolution

---

## LLM Prompt Templates

### For Feature + Upstream Merges

```text
I'm maintaining XConnect, a fork of RustDesk for smart classrooms.

FILE: [filename]
CONFLICT TYPE: Feature + Upstream - both sides have changes

OUR CODE (XConnect - keep custom features):
```dart
[paste our version]
```

UPSTREAM CODE (RustDesk - get improvements):
```dart
[paste their version]
```

CUSTOM CODE TO PRESERVE:
- [list custom classes/functions from llm_sync_guide.md]

Please merge these:
1. Keep ALL our custom code (classes, functions, widgets)
2. Integrate upstream improvements (bug fixes, new features)
3. Resolve any import changes
4. Keep our import aliases where used

Return the fully merged file.
```

### For Branding Resolution

```text
I'm applying XConnect branding to an upstream RustDesk file.

UPSTREAM CODE:
```
[paste upstream version]
```

Apply these renames:
- RustDesk → XConnect
- rustdesk → xconnect
- librustdesk → libxconnect
- com.carriez.flutter_hbb → com.xconnect.app
- com.carriez.RustDesk → com.xconnect
- RustdeskImpl → XconnectImpl
- RUSTDESK_APPNAME → XCONNECT_APPNAME
- dyn.com.rustdesk → dyn.com.xconnect

Return the file with all renames applied.
```

---

## Post-Merge Verification

### Build Tests

```bash
# Rust
cargo build --release

# Flutter (choose platform)
cd flutter
flutter pub get
flutter build android  # or linux, windows
```

### Branding Check

```bash
# Find any missed RustDesk references (excluding expected locations)
grep -rn "rustdesk" --include="*.dart" --include="*.rs" --include="*.kt" \
  | grep -v "github.com/rustdesk" \
  | grep -v ".git" \
  | grep -v "Cargo.lock" \
  | grep -v "pubspec.lock"
```

### Feature Verification

- [ ] App launches without crash
- [ ] UDP discovery (port 64546) finds devices
- [ ] All 4 connection modes work:
  - [ ] xBoard (whiteboard)
  - [ ] xCast (screen cast)
  - [ ] xCtrl (full control)
  - [ ] xCtrlView (view only)
- [ ] Splash screen displays XConnect branding

---

## Handling Special Cases

### Upstream Added New File in Renamed Directory

Example: `MainApplication.kt` was added by upstream in `com/carriez/flutter_hbb/` but we renamed that to `com/xconnect/app/`.

```bash
# 1. Accept upstream file location first
git checkout --theirs flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/MainApplication.kt

# 2. Move to our package path
mkdir -p flutter/android/app/src/main/kotlin/com/xconnect/app/
mv flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/MainApplication.kt \
   flutter/android/app/src/main/kotlin/com/xconnect/app/

# 3. Update package name in file
sed -i 's/package com.carriez.flutter_hbb/package com.xconnect.app/g' \
    flutter/android/app/src/main/kotlin/com/xconnect/app/MainApplication.kt

# 4. Remove empty directory
rm -rf flutter/android/app/src/main/kotlin/com/carriez/

# 5. Stage changes
git add flutter/android/app/src/main/kotlin/
```

### Upstream Refactored a File We Heavily Modified

If the diff is too large to manually merge:

1. Take upstream version: `git checkout --theirs <file>`
2. Re-apply our customizations using `llm_sync_guide.md` as reference
3. Use LLM to help re-add custom code blocks

---

## Abort and Retry

If merge goes wrong:

```bash
# Abort merge (clears all conflict state)
git merge --abort

# Clean working directory
git clean -fd
git checkout -- .

# Try again
git merge master
```

---

## Related Documents

- [llm_sync_guide.md](./llm_sync_guide.md) - Custom code patterns to preserve
- [fork_maintenance_workflow.md](./fork_maintenance_workflow.md) - Overall workflow
- [windows_android_build_features.md](./windows_android_build_features.md) - Full file list
- [linux_build_features.md](./linux_build_features.md) - Full file list
