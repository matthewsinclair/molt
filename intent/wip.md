---
verblock: "09 Mar 2026:v0.3: matts - Terminal liberator split complete"
---

# Work In Progress

## Current Focus

**004: Split terminal liberator into per-emulator liberators (DONE)**

- Replaced monolithic `terminal.sh` with four independent liberators:
  - `alacritty.sh` — GPU-accelerated terminal (linux, macos)
  - `gnome-terminal.sh` — dconf-based profile management (linux)
  - `iterm2.sh` — dynamic JSON profiles (macos, placeholder)
  - `terminal-app.sh` — .terminal profile import (macos, placeholder)
- Created `molt-matts/config/gnome-terminal/profile.dconf` (JetBrainsMono Nerd Font 14pt, dark theme)
- GNOME Terminal profile installed and set as default on kovacs
- Fixed `cmd_list` and `cmd_doctor` stdout leak from `_check` functions (`2>/dev/null` → `&>/dev/null`)
- Molt no longer runs `apt install` — liberators fail with hints if binaries missing
- 15 liberators total, all tests passing

**003: Bats test suite and CLI commands (DONE)**

- Created test infrastructure adapted from Utilz patterns
- All tests passing
- Added `molt doctor`, `molt test`, `molt list`, `molt version` CLI commands
- HOME sandboxed in manifest tests to prevent accidental real-home access

**002: MOLT framework scaffolding (WP-05, DONE)**

- CLI, core lib, 12 liberators, manifest support all working
- Test suite in place
- Template rendering system (WP-08) complete

## Active Steel Threads

- ST0001: Bootstrap — Phase 1 COMPLETE, Phase 2 framework WIP

## Upcoming Work

- Set up kovacs SSH for direct GitHub access (WP-02)
- Install Nerd Fonts (WP-03)
- Fix Cmd key passthrough (WP-01, PARKED)
- Export iTerm2 and Terminal.app profiles from rhadamanth (placeholder configs)
- Reproducible VM build (WP-07, future)

## Notes

15 liberators, all tests passing. `molt list` shows clean output (no leaked Zen: lines). gnome-terminal and alacritty both enabled and installed on kovacs. iterm2 and terminal-app disabled (macOS-only placeholders). local-bin shows as not installed due to PATH issue in doctor check context.
