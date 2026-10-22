---
wp_id: WP-06
title: Managed deny floor for sysadm
scope: S
status: WIP
---

# WP-06: Managed deny floor for sysadm

## Objective

A sysadm sleeve agent's credential denies hold at a layer the agent cannot edit: Molt renders hv's floor, the two Read denies for `~/.ssh/id_*` and `~/.aws/credentials`, into Claude Code's managed drop-in on every sleeve whose manifest enables a sysadm agent, through sudo, and removes a floor it rendered from a sleeve that no longer does, so `molt agent config` shows the rules as managed and `molt doctor` says when a sleeve carries the wrong thing.

## Ruling

hv, 21 Oct 2026, via cc: the floor's contents are credentials only, the two rules the role fence carries today, `Read(~/.ssh/id_*)` and `Read(~/.aws/credentials)`; nothing else (not a fence lock, not destructive-Bash denies, not "whatever the role's deny is"). Its scope (hv, 22 Oct, after seeing two answers side by side): every sleeve whose `molt.toml` declares an enabled `[[agent]]` with `role = "sysadm"` AND whose `vars.sh` declares `MOLT_CLAUDE_CONFIG_DIR`, the switch that arms the move and the home's guard hook; so kovacs now, rhadamanth at its WP04 move, gyges at its move. Elsewhere Molt renders none and removes a floor file it rendered earlier. A managed file binds every Claude Code session on the sleeve, and deny always wins, so the floor also binds hv's own sessions there: that is the point, and the guide says so.

## Where things live

- **Contents, in Molt-matts**: `config/agents/roles/sysadm/floor.json`, one JSON object `{"permissions": {"deny": [...]}}` holding exactly the two rules. It sits beside the role's `AGENTS.md.tmpl` and `settings.json.tmpl`, which carry the same two rules as the fence hv can see in the home. The duplication is deliberate: the fence is the agent's own view of its limits; the floor is the same limits where the agent cannot reach them. Molt derives nothing: the file is hv's.
- **Mechanism, in Molt**: the agents liberator, which already knows which `[[agent]]` roles are enabled, renders the floor beside the homes and removes one it rendered earlier. Two lib helpers in `lib/molt.sh`, after tiling.sh's shape: render to a user tmp as `molt_render` does, then `sudo install -m 644` into `<managed dir>/managed-settings.d/molt-sysadm.json`, with a `.molt-rendered` sidecar beside it, root-owned 644, written the same way; and a remove that takes both. `molt_claude_managed_dir` (`lib/molt.sh:1154`) names the dir per platform; its comment changes from "nothing in molt writes it" to "molt writes molt-sysadm.json there through sudo, and nothing else". Tests fake sudo (`FAKE_SUDO_STATUS`, as `tiling.bats`) and override the managed dir (as `agents.bats` does); no test touches the real one.
- **Removal rule**: only a drop-in whose sidecar molt wrote is removed; a `molt-sysadm.json` with no molt sidecar is left alone and reported, since somebody else put it there.
- **Faults**: a sleeve with an enabled sysadm agent and no `floor.json`, or a `floor.json` that is not one object with `permissions.deny`, fails check and install naming the file, as a missing role template does. sudo absent or refusing fails install naming it; nothing is written unprivileged into the managed dir.
- **Visibility**: `molt agent config <host>-sysadm` already lists the managed layer above local, home and user (`lib/agent.sh:389`); on a sleeve carrying the floor its two rules show tagged managed. `molt doctor` gains check 14: a sysadm sleeve whose floor is missing or stale, and a sleeve with no sysadm agent carrying a molt-written floor, each warn; otherwise pass.
- **Docs**: the guide gains a Managed floor section (what it is, where, that a sudo prompt may come mid `molt upgrade` on a sysadm sleeve, how to see it, the removal rule, that it binds hv's sessions too). Molt-matts' `roles/sysadm/AGENTS.md.tmpl` credential sentence stops saying "until a managed floor (Molt ST0006 WP06) walls them off" and says the floor is in place.

## Rollout

Molt first (cc, worktree `issue`-style branch `st0006-wp06`), CI green, vc merges; then Molt-matts (`floor.json` and the role text); then `molt upgrade` on kovacs, where hv answers the sudo prompt, and `molt agent config kovacs-sysadm` and doctor give AC020's evidence. rhadamanth and gyges declare no config dir today and get nothing until their moves.

## Out of scope

Any further floor contents (hv's call, later); a floor for ops or docs; the kovacs sandbox (bubblewrap) decision; the fence lock hv did not choose.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0006/acceptance.md`, under the `WP-06` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
