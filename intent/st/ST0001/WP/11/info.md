---
verblock: "09 Mar 2026:v0.1: matts - Initial WP"
wp_id: WP-11
title: "Inline upgrade (molt upgrade)"
scope: Small
status: Done
---

# WP-11: Inline Upgrade (`molt upgrade`)

## Problem

No way to pull framework + config updates and re-apply them. Currently manual: `git pull` in both repos, then `molt resleeve`.

## What Was Done

Added `molt upgrade` command that:

1. Checks both repos for uncommitted changes (fails gracefully if dirty)
2. `git pull --ff-only` in the molt framework repo (`$MOLT_ROOT`)
3. `git pull --ff-only` in the user config repo (discovered via `molt_find_user_repo`)
4. Reports version before/after if MOLT_VERSION changes
5. Re-runs `molt resleeve` (or shows what would happen with `--dry-run`)

### Implementation

- `cmd_upgrade()` in `lib/molt.sh` — core logic
- `upgrade` case added to `bin/molt` dispatcher
- Help text updated
- Reuses `molt_find_user_repo` for stack discovery
- `--dry-run` support: pulls repos but skips resleeve, shows what liberators would run

## Acceptance Criteria

- [x] `molt upgrade` pulls latest from both repos
- [x] `molt upgrade --dry-run` shows what would happen without resleeving
- [x] Fails gracefully if repos have uncommitted changes
- [x] Reports version before/after if changed
- [x] Re-runs resleeve after pulling

## Dependencies

None
