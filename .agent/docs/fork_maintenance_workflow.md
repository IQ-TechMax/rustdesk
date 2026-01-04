# XConnect Fork Maintenance Workflow

> [!NOTE]
> **For the complete 4-phase sync workflow, see [fork_sync_procedure.md](./fork_sync_procedure.md).**
> This document provides quick reference for the merge steps.

## Current Status

```
upstream (rustdesk/rustdesk) → origin/master → feature branches
```

| Branch | Status | Action |
|--------|--------|--------|
| `master` | Sync with upstream | First |
| `windows_android_build` | Merge from master | Second |
| `linux_build` | Merge from master | Third |

> [!IMPORTANT]
> **Use `git merge` NOT `git rebase`** for syncing feature branches.
> 
> **Sync ONE branch at a time.** Complete verification and user approval before moving to the next branch.

---

## Complete Sync Procedure

### Step 0: Sync Master with Upstream (ALWAYS DO FIRST)

```bash
# 1. Add upstream if not already added
git remote add upstream https://github.com/rustdesk/rustdesk.git

# 2. Fetch latest from upstream
git fetch upstream

# 3. Checkout and update master
git checkout master
git merge upstream/master

# 4. Sync submodules to latest upstream commit
git submodule update --init --recursive

# 5. Push updated master to origin
git push origin master
```

> [!WARNING]
> After syncing submodules, config.rs changes are lost.
> Re-apply using [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md)

---

### Step 1: Sync windows_android_build

> [!NOTE]
> **Complete this ENTIRE step before moving to Step 2.**
> User verification required before pushing.

#### 1.1 Start Merge

```bash
git checkout windows_android_build
git merge master
```

#### 1.2 Resolve Conflicts

Follow [merge_conflict_resolution.md](./merge_conflict_resolution.md) for each conflict file.

Priority order:
1. Generated files (Cargo.lock) - Accept upstream, regenerate
2. Branding files (specs) - Keep ours with XConnect naming
3. Feature files - Merge carefully, preserve custom code

#### 1.3 LLM Verification

```bash
# Build tests
cargo build --release
cd flutter && flutter pub get && flutter build android
flutter build windows

# Branding check
grep -rn "rustdesk" --include="*.dart" --include="*.rs" --include="*.kt" \
  | grep -v "github.com/rustdesk" | grep -v ".git" | grep -v "Cargo.lock"
```

#### 1.4 User Verification (REQUIRED)

**Ask user to test:**
- [ ] App launches successfully
- [ ] UDP discovery works (port 64546)
- [ ] All 4 connection modes work (xBoard, xCast, xCtrl, xCtrlView)
- [ ] Splash screen shows XConnect branding
- [ ] No unexpected "RustDesk" text visible

#### 1.5 Fix Issues

If user reports issues:
1. Identify the problem file
2. Use LLM with `llm_sync_guide.md` context to fix
3. Re-run verification
4. Repeat until user approves

#### 1.6 Push (After User Approval)

```bash
git commit -m "Merge master into windows_android_build - sync with upstream RustDesk"
git push origin windows_android_build
```

---

### Step 2: Sync linux_build

> [!NOTE]
> **Only start this after windows_android_build is verified and pushed.**
> User verification required before pushing.

#### 2.1 Start Merge

```bash
git checkout linux_build
git merge master
```

#### 2.2 Resolve Conflicts

Same process as Step 1. See [merge_conflict_resolution.md](./merge_conflict_resolution.md).

#### 2.3 Apply config.rs Changes

```bash
# Re-apply XConnect settings to submodule
cd libs/hbb_common
# Apply patch or manually edit src/config.rs
# See hbb_common_submodule_guide.md for exact changes
```

#### 2.4 LLM Verification

```bash
cargo build --release
cd flutter && flutter pub get && flutter build linux

# Branding check
grep -rn "rustdesk" --include="*.dart" --include="*.rs" \
  | grep -v "github.com/rustdesk" | grep -v ".git" | grep -v "Cargo.lock"
```

#### 2.5 User Verification (REQUIRED)

**Ask user to test:**
- [ ] App launches on Linux
- [ ] TCP listener starts (port 64546)
- [ ] TC_REQUEST/GC_REQUEST message flows work
- [ ] Network monitor functions correctly
- [ ] xwall.io registration works (if applicable)

#### 2.6 Fix Issues

Same as Step 1.5 - iterate until user approves.

#### 2.7 Push (After User Approval)

```bash
git commit -m "Merge master into linux_build - sync with upstream RustDesk"
git push origin linux_build
```

---

## Post-Sync Cleanup

- [ ] Update `doc_sync_tracker.md` with new sync dates
- [ ] Verify all docs still accurate after merge
- [ ] Delete any temporary patch files

---

## Conflict Resolution Quick Reference

| Type | Resolution |
|------|------------|
| Generated (`Cargo.lock`, `pubspec.lock`) | Accept upstream, regenerate |
| 100% custom file | Keep ours |
| Branding (specs, package names) | Keep ours |
| Feature + Upstream | Merge carefully |
| Upstream structural change | Adapt to new location |

Full details: [merge_conflict_resolution.md](./merge_conflict_resolution.md)

---

## LLM Prompt to Start Sync

```text
I need to sync my XConnect fork with upstream RustDesk.

Workflow:
1. Sync master with upstream (already done / do first)
2. Merge windows_android_build with master
3. Resolve conflicts, verify builds, get my approval
4. Push windows_android_build
5. THEN move to linux_build (same process)

Use `.agent/docs/` for context:
- `merge_conflict_resolution.md` - per-file strategies
- `llm_sync_guide.md` - custom code to preserve
- `hbb_common_submodule_guide.md` - config.rs changes

DO NOT push to remote until I verify the changes work correctly.
```

---

## Related Docs

- [merge_conflict_resolution.md](./merge_conflict_resolution.md) - Per-file resolution guide
- [llm_sync_guide.md](./llm_sync_guide.md) - LLM context for conflicts
- [windows_android_build_features.md](./windows_android_build_features.md) - 116 files
- [linux_build_features.md](./linux_build_features.md) - 101 files
- [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md) - Uncommitted config.rs
