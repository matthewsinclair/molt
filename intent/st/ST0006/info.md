---
st_id: ST0006
title: Sleeve agents: a named, role-bound home for a machine's local agent
status: WIP
created: 2026-10-21
completed:
---

# ST0006: Sleeve agents: a named, role-bound home for a machine's local agent

## Objective

A sleeve agent is a local agent (Claude Code, for now) that does machine-oriented work on one host, as the user: system administration, operations, documentation of the machine. Today it runs from `$HOME`, where it has no instruction file, no project-layer permissions, a memory slot shared with every other home-launched session, and leaves the harness's files loose in the home directory.

This thread gives a sleeve agent a home: `$MOLT_AGT_DIR/<host>-<role>/`, declared in the sleeve's manifest as an `[[agent]]` entry, rendered by Molt from a role profile kept in the user config repo, holding its role contract, its permissions and its memory. The harness's own state leaves `$HOME` for `$XDG_CONFIG_HOME/claude`, nothing recreates `~/.claude`, and a Claude launched with its cwd in `$HOME` is refused at its first prompt. Project agents (sessions run inside an Intent project, such as molt-vc) are out of scope: the project and Intent already bound them.

## Context

## Where this came from

hv, 21 Oct 2026, to kovacs-sysadm and molt-vc: a local agent on kovacs runs out of `$HOME`, leaves LLM files there, and is "a bit too risky for my liking". The ask: a way, in Molt, to install, name, configure and manage a local agent safely. kovacs-sysadm surveyed kovacs; molt-vc verified the Claude Code facts the design turns on (docs, plus one live test on rhadamanth). hv's rulings are below; the thread is specified by molt-vc, built by molt-cc and molt-dc, and the kovacs move is planned by kovacs-sysadm and executed by hv.

## Three layers

| Layer         | Where                                        | Owned by       | Holds                                                                                        |
| ------------- | -------------------------------------------- | -------------- | -------------------------------------------------------------------------------------------- |
| Role source   | Molt-matts `config/agents/roles/<role>/`     | hv, in git     | the role contract (`AGENTS.md`) and permission profile (`settings.json`) templates            |
| Agent home    | `$MOLT_AGT_DIR/<host>-<role>/`               | Molt, rendered | `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `memory/`, `work/`; the agent's cwd        |
| Harness state | `$XDG_CONFIG_HOME/claude` (`CLAUDE_CONFIG_DIR`) | Claude Code    | credentials, transcripts, plugins, user settings; one per machine, shared by every session   |

The agent home is both the agent's config and its runtime directory: Claude Code's project-layer config is whatever sits in the cwd's `.claude/`, so cwd and config home coincide by construction. `autoMemoryDirectory` pins memory to `<home>/memory/`, so an agent's memory travels with its home rather than hiding under a cwd slug in the harness state.

## Naming and roles (hv, 21 Oct)

- Sleeve agents are always `<hostname>-<role>`: `rhadamanth-sysadm`, `kovacs-ops`.
- Roles, normalised across rhadamanth, gyges and kovacs: `sysadm` (system administration; may change the machine; cannot be sandboxed), `ops` (operations and monitoring; observe and diagnose, writes only inside its home; sandbox on), `docs` (documentation; sandbox on).
- `MOLT_AGT_DIR` follows `MOLT_PRJ_DIR` and `MOLT_CFG_DIR`; default `$HOME/Devel/agt`, a peer of `prj/` and `cfg/`. Unix has no convention for an interactive agent that runs as the user; `/opt`, `/var/lib` and `/srv` are for software and services under a service account. A dedicated Unix account per agent is the stronger boundary and stays in view for later.

## hv's calls

1. Harness state goes to `$XDG_CONFIG_HOME/claude`. No `~/.claude` at all, no compat symlink: `CLAUDE_CONFIG_DIR` is rendered from one value (`MOLT_CLAUDE_CONFIG_DIR` in the instance vars) into `zshenv` and the GUI environment path (a LaunchAgent `setenv` on macOS, `environment.d` on Linux), and `molt doctor` treats a reappeared `~/.claude` or `~/.claude.json` as the signal that a launch path missed the variable.
2. Config and runtime home are the same directory.
3. Roles `sysadm`, `ops`, `docs`; declared on rhadamanth, gyges and kovacs.
4. Enforcement: the home's `.claude/settings.json` is a fence the agent could edit; the root-owned managed-settings file is the wall. `ops` and `docs` get fence plus sandbox; `sysadm` gets a managed deny floor as its own work package (WP06).
5. No launch verb. `molt agent list` and `molt agent config <name>`. Claude only; Codex later, if ever.

## Facts verified (21 Oct)

- `CLAUDE_CONFIG_DIR` relocates every `~/.claude` path, and also `~/.claude.json`: with the variable set to an empty directory, `claude config list` created `<dir>/.claude.json` (mode 600) and left `~/.claude.json` untouched. The docs do not say so; the test does.
- Settings precedence: managed, `--settings`, `.claude/settings.local.json`, `.claude/settings.json`, user. `permissions.allow/deny/ask` merge across levels and deny wins at every level. Managed file: `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS), `/etc/claude-code/managed-settings.json` (Linux), plus `managed-settings.d/`.
- `sandbox.enabled` stops sandboxed Bash from writing any `.claude` settings, hooks, shell rc files, `.git` config and the config dir, with no exemption; Edit and Write are outside the sandbox and only prompt.
- A `UserPromptSubmit` hook returning exit 2 blocks the prompt; Intent's in-session gate already uses it.
- A live session cannot move its own state: `mv ~/.claude` under a running Claude moves its transcript, credentials and state out from under it. The move is run from a plain terminal with every Claude session on the host quit.
- `liberators/claude.sh` hardcodes `$HOME/.claude` in five places; the variable must be honoured before it is set anywhere.

## Constraints

- kovacs will be brew-only, and Molt itself will gain a brew install mode (hv, 21 Oct; not ready yet, and Molt on kovacs is a dev checkout for now). So: nothing in this thread may be anti-brew. Rendered files (the hook script, env files, GUI files, agent homes) reference no checkout path; what a sleeve agent needs at prompt time lives under `~/.config/molt/` or the agent home, where a brew-installed Molt will put it just the same.
- gyges is fixed later, not today (hv): its sleeve agent becomes `gyges-sysadm` when WP04 reaches it.
- Molt manages the user-scope `CLAUDE.md` and `AGENTS.md` under the config dir as links from the user repo's `config/claude/` (hv, 21 Oct), so the cross-session rules are the same on every sleeve; kovacs lacked the Git Commits rule until 20 Oct while rhadamanth had it.
- Intent on rhadamanth is off limits (board watchout 16).
- Molt's CI runner is bash 3.2; run bats under `/bin/bash` too.
- No AI attribution in any commit; messages end `(C) hello@matthewsinclair.com`.
- Three Molt sessions share one checkout on rhadamanth: cc and dc work in git worktrees on `st0006-wp<NN>` branches; vc reviews and merges to main.
- `[[agent]]` entries land in the Molt-matts manifests only after WP02's parser is on every sleeve that reads them.

## Work Packages

| WP    | Title                                                                                                                  | Size | Status      |
| ----- | ---------------------------------------------------------------------------------------------------------------------- | ---- | ----------- |
| WP-01 | Harness state leaves $HOME: claude liberator honours CLAUDE_CONFIG_DIR, renders it, moves once, refuses $HOME launches | S    | WIP         |
| WP-02 | [[agent]] manifest table, MOLT_AGT_DIR and the agents liberator; molt agent list/config                                | S    | Not Started |
| WP-03 | Roles in Molt-matts: sysadm, ops, docs contracts and profiles; [[agent]] entries for rhadamanth, gyges, kovacs         | S    | Not Started |
| WP-04 | Move kovacs-sysadm into its home; then rhadamanth, then gyges                                                          | S    | Not Started |
| WP-05 | docs/guides/sleeve-agents.md: naming, roles, layers, the move                                                          | S    | Not Started |
| WP-06 | Managed deny floor for sysadm                                                                                          | S    | Not Started |

## Acceptance

Acceptance Criteria and Acceptance Tests are RENDERED into `acceptance.md`, which is a GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in this thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
