---
verblock: "08 Mar 2026:v0.2: matts - As-built with testing and CLI"
wp_id: WP-05
title: "MOLT framework scaffolding"
scope: Large
status: WIP
---

# WP-05: MOLT framework scaffolding

## Objective

Create the initial structure and scaffolding for the MOLT framework in the molt repo. This is where templates, scripts, and tooling will live — the shared infrastructure that any user's molt-{userid} repo builds on.

## Context

Framework has been substantially built out. The molt repo now has a working CLI, core library, 12 liberators, manifest support, and a bats test suite.

## Deliverables

- [x] Directory structure: `bin/`, `lib/`, `liberators/`, `test/`, `templates/`
- [x] Working CLI (`bin/molt`) with commands: resleeve, status, list, doctor, test, version, help
- [x] Core library: logging, platform detection, symlinks, dependency checks, manifest parsing
- [x] Liberator framework: load/check/install/verify lifecycle, batch operations, discovery
- [x] 12 liberators covering system, shell, git, editors, terminal, keys, desktop, dev-tools, ssh, utilz
- [x] Manifest system (`molt.toml`): enabled/disabled, OS filtering, instance overrides
- [x] Bats test suite: 42 tests, 6 files, all passing
- [x] `molt doctor`: 7-step diagnostic
- [ ] README updates reflecting the framework structure
- [ ] Template system design (how config templates get rendered per-instance)

## Acceptance Criteria

- [x] molt repo has a clear, documented directory structure for framework code
- [x] At least one working script or template demonstrating the pattern
- [ ] README explains the two-repo model (molt + molt-{userid})
- [x] Design decisions captured in ST0001/design.md

## As-Built Summary (08 Mar 2026)

### Framework structure
```
bin/molt            — CLI entry point (thin coordinator)
lib/constants.sh    — Configurable paths (Highlander Rule)
lib/molt.sh         — Core utilities + CLI commands
lib/liberator.sh    — Liberator lifecycle framework
liberators/*.sh     — 12 liberator modules
test/               — 42 bats tests, HOME-sandboxed
templates/          — molt.toml.example
```

### Test suite
- `test/test_helper.bash` — shared infrastructure adapted from Utilz
- `test/molt.bats` — 11 CLI tests
- `test/constants.bats` — 10 constants tests
- `test/liberator.bats` — 9 framework tests
- `test/manifest.bats` — 6 manifest parsing tests (HOME sandboxed to temp dir)
- `test/liberators/zsh.bats` — 6 exemplar liberator tests

### CLI commands added this session
- `molt doctor` — 7-step system diagnostics with ✓/✗/⚠ output
- `molt test [liberator]` — run bats test suite (all or per-liberator)
- `molt list` — list liberators with enabled/disabled/installed status
- `molt version` — show version string

## Dependencies

- WP-04 (bootstrap runbook) — DONE, informs automation
- Remaining: README update, template rendering design
