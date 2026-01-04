# XConnect Fork Documentation

**Fork of RustDesk for Smart Classroom Projector Control**

---

## Current Status

| Branch | Base | Status |
|--------|------|--------|
| `master` | RustDesk upstream | Sync with upstream FIRST |
| `windows_android_build` | master | Merge from master |
| `linux_build` | master | Merge from master |

---

## Fork Sync Workflow

> [!IMPORTANT]
> **Follow [fork_sync_procedure.md](./fork_sync_procedure.md) for complete sync workflow.**

### Summary of Phases

```
Phase 0: DOCS SYNC    → Sync docs with current code state FIRST
Phase 1: MASTER SYNC  → Sync master from upstream
Phase 2: BRANCH SYNC  → Merge master into feature branches (one at a time)
Phase 3: POST-SYNC    → Update doc_sync_tracker.md
```

### Key Rules

1. **Docs first** - Update documentation before syncing code
2. **Merge, not rebase** - Single conflict resolution vs per-commit
3. **One branch at a time** - Complete verify→approve→push before next branch
4. **User verification required** - LLM can't push until user approves
5. **Clarify conflicts** - Ask user if unsure how to resolve

---

## Quick Start

| Need to... | Read |
|------------|------|
| **Start a fork sync** | [fork_sync_procedure.md](./fork_sync_procedure.md) ⭐ |
| Resolve merge conflicts | [merge_conflict_resolution.md](./merge_conflict_resolution.md) |
| Know what custom code to preserve | [llm_sync_guide.md](./llm_sync_guide.md) |
| Update docs after code changes | [doc_sync_tracker.md](./doc_sync_tracker.md) |
| Understand architecture | [xconnect_architecture.md](./xconnect_architecture.md) |
| See client (Android/Windows) changes | [windows_android_build_features.md](./windows_android_build_features.md) |
| See projector (Linux) changes | [linux_build_features.md](./linux_build_features.md) |
| Handle config.rs submodule | [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md) |

---

## Document Index

| File | Purpose |
|------|---------|
| **fork_sync_procedure.md** ⭐ | Complete 4-phase sync workflow |
| **merge_conflict_resolution.md** | Per-file conflict resolution guide |
| **llm_sync_guide.md** | Custom code patterns to preserve |
| **fork_maintenance_workflow.md** | Legacy workflow (see fork_sync_procedure.md) |
| **windows_android_build_features.md** | 116 files tracked |
| **linux_build_features.md** | 101 files tracked |
| **xconnect_architecture.md** | Network/modes |
| **hbb_common_submodule_guide.md** | Uncommitted config.rs |
| **xconnect_rename_tracker.md** | All renames |
| **xconnect_logo_checklist.md** | Logo assets |
| **doc_sync_tracker.md** | Track doc sync dates |

---

## Key Points

1. **Docs first, then code** - Sync documentation BEFORE syncing with upstream
2. **config.rs is uncommitted** - Submodule issue, apply manually per branch
3. **100% custom files are safe** - They don't exist in upstream, no conflicts
4. **Clarify unclear commits** - Ask user before assuming
5. **Never push without approval** - User must verify changes work
