# XConnect Documentation Sync Tracker

> **Purpose:** Track when documentation was last synced with code changes.
> Use the dates below to find new commits and update docs accordingly.

---

## Last Documentation Sync

| Branch | Last Synced | Commit | Documented By |
|--------|-------------|--------|---------------|
| `windows_android_build` | 2026-01-03 | Synced to v1.4.4 | LLM |
| `linux_build` | 2026-01-04 | Synced to v1.4.4 | LLM |

---

## Recent Updates (2026-01-03/04) - Upstream v1.4.4 Sync

### Major Sync: RustDesk v1.4.4

**windows_android_build (2026-01-03):**
- Synced with upstream RustDesk v1.4.4
- Resolved 13 merge conflicts
- Applied 5 post-merge fixes (see `post_merge_fixes.md`)
- Verified: Windows + Android (debug & release) ✅

**linux_build (2026-01-04):**
- Synced with upstream RustDesk v1.4.4
- Resolved 10 merge conflicts
- Applied 6 post-merge fixes (including linux_build-specific changes)
- Verified: Linux (debug & release) ✅

### New Documentation Created
- **`post_merge_fixes.md`** - Comprehensive guide to fixes required after upstream sync
- Updated `fork_sync_procedure.md` with Step 2.2a for post-merge fixes

---

## Previous Updates (2026-01-02)

### Build Configuration Fix
- **`pubspec.yaml`**: Restored missing `flutter:` section header and `uses-material-design: true`.
- **Assets**: assets now correctly loaded via `assets/` directory inclusion.

### Asset Standardization
- **Logos**: Standardized to `xConnect-Icon.png` and `xConnect-Logo.png` across both branches.
- **Background**: Standardized to `xConnectBackground.png` (PNG) in both branches.
- **Docs Updated**: `windows_android_build_features.md`, `linux_build_features.md`, `pubspec.yaml` references.

---

## How to Find Changes Since Last Sync

### For windows_android_build:
```bash
git checkout windows_android_build
git log --oneline --since="2026-01-02" --name-only
```

### For linux_build:
```bash
git checkout linux_build
git log --oneline --since="2026-01-02" --name-only
```

### Find specific file changes:
```bash
# Check if custom files have changed
git diff HEAD~5 -- flutter/lib/utils/xconnect_tcp_manager.dart
git diff HEAD~5 -- flutter/lib/linux_tcp_listener/tcp_listener.dart
```

---

## Documentation Update Checklist

When syncing docs with new code changes:

### 1. Check for New Files
```bash
git diff master --name-only --diff-filter=A
```
- [ ] Add new custom files to feature docs
- [ ] Add new dependencies to pubspec section
- [ ] Add new constants to architecture doc

### 2. Check for Modified Files
```bash
git diff master --name-only --diff-filter=M | grep -E "\.dart$|\.rs$|\.kt$"
```
- [ ] Update line numbers in llm_sync_guide.md
- [ ] Update code patterns if signatures changed
- [ ] Update port constants if changed

### 3. Check for Deleted Files
```bash
git diff master --name-only --diff-filter=D
```
- [ ] Remove references from feature docs

---

## Documents to Update

| Document | Update When |
|----------|-------------|
| `windows_android_build_features.md` | New files, dependencies, features |
| `linux_build_features.md` | New files, dependencies, features |
| `llm_sync_guide.md` | Code patterns, line numbers change |
| `xconnect_architecture.md` | Ports, protocols, topology changes |
| `hbb_common_submodule_guide.md` | Config.rs changes |
| `xconnect_rename_tracker.md` | New rename patterns |

---

## LLM Prompt to Update Docs

> I need to update XConnect documentation after code changes.
>
> Last sync date: [DATE]
> Branch: [windows_android_build / linux_build]
>
> Please:
> 1. Run `git log --oneline --since="[DATE]" --name-only`
> 2. Identify what files changed
> 3. Update the relevant docs in `.agent/docs/`
> 4. Update this tracker with new sync date

---

## Sync History

| Date | Branch | Changes | Updated By |
|------|--------|---------|------------|
| 2026-01-04 | linux_build | Synced to v1.4.4, 10 conflicts, 6 fixes | LLM |
| 2026-01-03 | windows_android_build | Synced to v1.4.4, 13 conflicts, 5 fixes | LLM |
| 2026-01-02 | windows_android_build | Initial complete documentation | LLM |
| 2026-01-02 | linux_build | Initial complete documentation | LLM |

---

## Critical Files to Watch

### windows_android_build
- `flutter/lib/utils/xconnect_tcp_manager.dart`
- `flutter/lib/models/device_discovery_model.dart`
- `flutter/lib/mobile/widgets/xConnectOptions.dart`
- `flutter/lib/mobile/pages/home_page.dart`
- `flutter/lib/common.dart` (connect function)

### linux_build
- `flutter/lib/linux_tcp_listener/tcp_listener.dart`
- `flutter/lib/network_monitor.dart`
- `flutter/lib/main.dart` (275 lines of custom code)
- `src/flutter_ffi.rs` (x_connect_device_name functions)
- `libs/hbb_common/src/config.rs` (uncommitted)
