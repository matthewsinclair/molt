---
verblock: "08 Mar 2026:v0.2: matts - Updated with framework status"
---

# Work In Progress

## Current Focus

**003: Bats test suite and CLI commands (DONE)**

- Created test infrastructure adapted from Utilz patterns
- 42 tests across 6 files, all passing
- Added `molt doctor`, `molt test`, `molt list`, `molt version` CLI commands
- HOME sandboxed in manifest tests to prevent accidental real-home access

**002: MOLT framework scaffolding (WP-05, WIP)**

- CLI, core lib, 12 liberators, manifest support all working
- Test suite in place
- Remaining: README update, template rendering design

## Active Steel Threads

- ST0001: Bootstrap — Phase 1 COMPLETE, Phase 2 framework WIP

## Upcoming Work

- Set up kovacs SSH for direct GitHub access (WP-02)
- Install Nerd Fonts (WP-03)
- Fix Cmd key passthrough (WP-01, PARKED)
- README update for two-repo model
- Template rendering design
- Reproducible VM build (WP-07, future)

## Notes

All 12 liberators passing `molt doctor` checks (10/11 enabled liberators installed, keys is disabled/parked). local-bin shows as not installed due to PATH issue — `$HOME/bin` not on PATH in the doctor check context.
