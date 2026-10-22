---
wp_id: WP-02
title: [[agent]] manifest table, MOLT_AGT_DIR and the agents liberator; molt agent list|config
scope: S
status: Done
---

# WP-02: [[agent]] manifest table, MOLT_AGT_DIR and the agents liberator; molt agent list|config

## Objective

Declare sleeve agents as `[[agent]]` tables in the sleeve's manifest, resolve one agents root (`MOLT_AGT_DIR`) through one validator, render each enabled agent's home (`AGENTS.md` from preamble, role and host overlay; `CLAUDE.md`; `.claude/settings.json`; `memory/`; `work/`) from the user repo's role, report and inspect them with `molt agent list` and `molt agent config`, and have the home-launch guard refuse a launch anywhere under the root that is not an agent home.


Owner: molt-cc. Branch `st0006-wp02` in a git worktree, on top of WP01; molt-vc reviews and merges.

## Contract

1. **Manifest.** `instances/<host>/molt.toml` gains `[[agent]]` tables: `role = "sysadm"` (required; one of the roles the user repo defines), `enabled = true` (default), `harness = "claude"` (default, the only value this thread accepts). The name is derived, never written: `<hostname>-<role>`, so the convention cannot be mistyped. The parser is the existing `[[liberator]]` one, generalised to take the table name (`_molt_liberator_entries` becomes one table parser; Highlander), and `test/manifest.bats` covers `[[agent]]` as it covers `[[liberator]]`.
2. **`MOLT_AGT_DIR`.** Default: the `agt/` sibling of `MOLT_PRJ_DIR`, computed exactly as Molt-matts' zshenv computes it (`${MOLT_PRJ_DIR:h}/agt`), defined where `MOLT_PRJ_DIR` and `MOLT_CFG_DIR` are, and that is the one resolver: a `vars.sh` that exports a different `MOLT_AGT_DIR` is refused, as is a root that is relative or untidy, or at or above `$HOME`, `MOLT_PRJ_DIR` or `MOLT_CFG_DIR` (one validator in `lib/agent.sh`, called by both liberators; critic-shell, 21 Oct). Exported from zshenv by Molt-matts (WP03). An agent's home is `$MOLT_AGT_DIR/<name>`.
3. **The `agents` liberator.** For each enabled agent, `agents_install` renders the home from the user repo's `config/agents/roles/<role>/`: `AGENTS.md` from three layers in order: the config repo's role-independent `config/agents/AGENTS.md.tmpl` when it has one (AC016: text common to every sleeve agent lives there and in no role template), the role's `AGENTS.md.tmpl`, and, when the sleeve has one, the instance overlay `instances/<host>/agents/<role>.md` (host facts that are true on this machine only: its stack layout, what is installed, known issues; the role template is one file for every host, so kovacs' "this VM, ext4, `~/mac`" cannot live in it: kovacs-sysadm), `CLAUDE.md` as the `@AGENTS.md` stub, `.claude/settings.json` from `settings.json.tmpl` with `autoMemoryDirectory` set to `<home>/memory`; creates `memory/` and `work/`. Rendering is Molt's `envsubst` with `MOLT_HOSTNAME`, `MOLT_AGENT_NAME`, `MOLT_AGENT_ROLE`, `MOLT_AGENT_HOME` available; `.molt-rendered` digest sidecars decide re-rendering, as for ssh. `memory/` and `work/` are the agent's and are never written by Molt after creation. A role the user repo does not define is a fault naming the role and the path looked in. Rendering a home does not depend on the harness state having moved (WP01): the first `molt upgrade` on kovacs renders the home while kovacs-sysadm is still live and WP01's move is refused, so that it can copy its files in before hv runs the move (kovacs-sysadm H2). `agents_check` and `agents_verify` report missing or stale homes; `agents_upgrade` re-renders stale ones.
4. **`molt agent list`** prints each declared agent: name, role, home, enabled, and whether its rendered files are current. **`molt agent config <name>`** prints the home, the role, each rendered file's currency, and the effective permissions: `permissions.allow/deny/ask` merged from the managed file, the user settings and the home's `.claude/settings.json`, each rule tagged with the layer it came from. An undeclared name fails and lists the declared ones.
5. **The home-launch guard's second rule (AC014).** WP01's `claude-home-guard.sh.tmpl` gains, with the resolved `MOLT_AGT_DIR` rendered in as a literal: a session whose `CLAUDE_PROJECT_DIR` lies under `MOLT_AGT_DIR` without being an agent home itself (the agents root, or anything below a home) is refused, naming the home to launch from; a session started exactly in a home passes. The claude liberator exports the resolved root for its renders and refuses to render the hook with a missing or relative one, and doctor compares the root baked into the rendered hook with the resolved one, reporting a mismatch as "re-run molt upgrade" (the install re-renders, so that is true).

## Tests

Fake user repo with a role dir; fake `$MOLT_AGT_DIR`; render, re-render no-op, stale after the template changes or the instance overlay changes; render with and without an overlay; undefined role fault; derived name; `agent config` merging three fake settings layers and tagging each rule's source; the `[[agent]]` parser cases in `manifest.bats`; the guard's four AC014 cases, the render-time root refusal and the doctor row (AT053 to AT058); the preamble present and absent, the overlay still last (AC016).

## Out of scope

Codex renderer. Launch verb. The role contents themselves (WP03).

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0006/acceptance.md`, under the `WP-02` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
