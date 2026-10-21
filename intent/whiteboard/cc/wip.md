---
node: cc
name: Control Claude
role: control
session_id: 3c8f03ce-1074-4a24-b1bd-4c5c9ab43a51
heartbeat_at: 2026-10-21 13:19Z
status: active
focus: "ST0006 WP02: critic-shell's fixes (todos 3 to 5) designed, not started in code; st0006-wp02 at b897a23; on hold for hv's travel"
claims: [ST0006/01, ST0006/02]
---

# Control Claude (cc)

## DOING

- ST0006 WP02 at st0006-wp02 b897a23, rebased onto main c815d23, committed and clean; all tests pass under both bashes. It carries the build, critic-shell's first review answered, AC014 (the guard refuses a launch in the agents root or below a home, the root baked from a quoted here-document, the drift row), one root validator molt_agt_dir_fault, AC016's preamble layer (molt_render_text), and the guard comparing the disk's spelling (/bin/pwd -P). On main: AT053-AT058 green (1f390c4), AT059-AT061 to-write until the merge. critic-shell's last pass is todo 3, vc's rulings todo 4, the design for the fixes todo 5; no fix is in code yet. (edited)

## TODO

- ST0006 WP02 critic-shell findings on 6caffe8+b897a23 (0 critical, 4 W, 8 R, 1 S), to fix on st0006-wp02 after the compact, then the head to vc. W1: molt_agt_dir_fault compares spellings while the guard compares directories on disk (real_dir), so a root reaching HOME or a parent of MOLT_PRJ_DIR/MOLT_CFG_DIR by a symlink or another letter case passes and the guard then refuses every project: test containment with (cd && /bin/pwd -P) in one helper shared with the guard's logic, or refuse an existing root whose disk spelling differs. W2: the vars.sh check misses MOLT_AGT_DIR=x (plain), +=, and unset, because MOLT_AGT_DIR is already exported in molt's shell and molt_instance_var unsets then counts exports only; compare in a subshell with MOLT_AGT_DIR exported as resolved (unset reads as a difference), or restore it after sourcing in molt_render_text; add the cases to AT059 and AT057. W3: AGENTS.md is built in two places, so molt_render compares the bare role layer with the full file and backs it up on every re-render once a preamble or overlay exists; compose the layers before molt_render's compare/backup/move (also fixes the @@MOLT:BEGIN@@ duplicate-preamble rec and the half-written AGENTS.md on a failed prepend). W4: constants.bats:124 [[ -z ]] is inert under bash 3.2 errexit (not last); use [ ]. Recs: red controls for hostname-first, molt_agent_named status 2, the listing statuses, the line-break refusal, MOLT_CFG_DIR in the loop, the vars.sh-unreadable branch, the >/dev/null, and above all || exit after molt_render (unreadable role template plus a preamble installs PRE|PRE|contract|OVL|OVL); one shared absolute/canonical check with claude.sh's _claude_path_fault, and the repeated 'vars.sh cannot be found' message; refuse a root at or under ~/.claude or the declared config dir; rename one of the two 'preamble's; claude asks the validator even with no agents (blocks the move on a sleeve without MOLT_PRJ_DIR): ask vc whether intended; AT055's letter-case block into its own skipping test; per-test scratch MOLT_AGT_DIR. Style: say when the root came from MOLT_PRJ_DIR; test / before the canonical patterns.
- vc's rulings on cc todo 3 (WP02 critic findings), 21 Oct: (a) claude keeps asking molt_agt_dir_fault unconditionally (a Molt sleeve always has MOLT_PRJ_DIR); the empty-root refusal reads exactly 'MOLT_AGT_DIR cannot be resolved: MOLT_PRJ_DIR is unset'. (b) W1: the validator resolves real paths the same way the guard does (/bin/pwd -P, builtin fallback) so the two never disagree. (c) W3: assemble the three AGENTS.md layers first and give molt_render the whole, so its compare is against what is on disk. W2 and W4 as described in todo 3. All on st0006-wp02 after the compact; b897a23 stays the head until then.
- ST0006 WP02 design for todos 3 and 4, worked out on 21 Oct before the hold. No code is changed yet: st0006-wp02 is still at b897a23. (1) W3 is wider than AGENTS.md. A probe showed .claude/settings.json backed up on every re-render, because _agents_memory_dir_set rewrites it after molt_render's compare; the critic missed this. Split molt_render into molt_render_text and a new molt_render_place, which keeps the region above @@MOLT:BEGIN@@, compares, backs up, moves, writes the sidecar with the digest of the template, vars.sh and any extras, sets perms and logs. _agents_render_file builds the whole file in .molt-tmp first (preamble, role and overlay; the jq memory dir for settings.json) and hands it to molt_render_place, so a failed layer leaves the file as it was; AT035 then reads missing on a first install and stale after. (2) Composing alone still duplicates the preamble when a role template carries @@MOLT:BEGIN@@: keep the region only when the new render opens with the marker, as both ssh templates do, and rename molt_render's local preamble to kept. (3) W2: molt_instance_var takes an optional starting value, exported before vars.sh is sourced, as molt_render_text's subshell has it; molt_agt_dir_fault asks with $MOLT_AGT_DIR and refuses any difference, unset included. (4) W1: molt_disk_path in lib/molt.sh resolves the nearest existing ancestor with (cd && { /bin/pwd -P || pwd -P; }), the guard's real_dir method, and appends the rest; containment compares those. (5) Recs: a molt_path_fault shared by _claude_path_fault and _molt_agt_root_fault; molt_instance_vars_file prints the 'cannot be found' reason once; refuse a root at or under ~/.claude, molt_claude_config_dir or the declared MOLT_CLAUDE_CONFIG_DIR; handle / before the canonical test; name a derived root through a molt_agt_dir_derived in constants.sh; move the envsubst check to the start of molt_render_text; a per-test MOLT_AGT_DIR in test_helper's setup(), keeping the file-level line for the four files with setups of their own. (6) Tests: extend AT059 and AT057; new AT062 (entries or a role's files unreadable), AT063 (a layer that cannot render leaves AGENTS.md as it was, a vars.sh EXIT trap kept out of the reason), AT064 (AT055's letter case as its own skipping test), AT065 (the marker with a preamble), AT066 (no backup on a re-render without a hand edit); W4 at constants.bats lines 115 and 124. ssh's config.d append probably has the same render-then-append shape: unverified, and not WP02.

## Holds

_(none)_

## Watch-outs

- macOS pgrep leaves out its own ancestors unless given -a, so molt run inside a Claude Code session did not see that session (claude liberator, ST0006). procps' pgrep leaves out only itself, and its -a lists full command lines, so the flag is macOS-only. procps' pgrep -l prints a process name only; name processes with ps -o pid=,args=.
- In a git worktree, Intent's post-merge, post-checkout and post-rewrite hooks run intent sync in the worktree's own store, which can predate main. cc's board views went backwards (old name, old focus). Restore intent/ views there with git checkout, and never commit them from a worktree.

## Decisions

_(none)_

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
