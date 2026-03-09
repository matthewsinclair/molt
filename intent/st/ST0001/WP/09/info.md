---
verblock: "09 Mar 2026:v0.1: matts - As-built"
wp_id: WP-09
title: "Split terminal liberator into per-emulator liberators"
scope: Medium
status: Done
---

# WP-09: Split terminal liberator into per-emulator liberators

## Objective

Replace the monolithic `terminal.sh` liberator (which only handled Alacritty on Linux and was a no-op on macOS) with independent per-emulator liberators that can be enabled/disabled per-instance.

## Context

Matt prefers GNOME Terminal over Alacritty on kovacs. The old terminal liberator had no way to manage GNOME Terminal, and couldn't be selectively enabled per emulator. Splitting allows each sleeve to pick its terminal(s).

## Key Principle

Molt does NOT install packages. Liberators check if a tool is available (`command -v`), configure it if present, and fail with a hint if missing.

## Deliverables

- [x] `liberators/alacritty.sh` — extracted from terminal.sh, no package install
- [x] `liberators/gnome-terminal.sh` — dconf-based profile management with fixed UUID
- [x] `liberators/iterm2.sh` — iTerm2 dynamic profiles (macOS, placeholder config)
- [x] `liberators/terminal-app.sh` — Terminal.app profile import (macOS, placeholder config)
- [x] `molt-matts/config/gnome-terminal/profile.dconf` — Molt profile (JetBrainsMono NF 14pt, dark theme)
- [x] `molt-matts/instances/kovacs/molt.toml` updated with four new liberator entries
- [x] `liberators/terminal.sh` deleted
- [x] Fixed `cmd_list`/`cmd_doctor` stdout leak from `_check` functions (`2>/dev/null` → `&>/dev/null`)
- [x] GNOME Terminal profile loaded and set as default on kovacs

## Remaining

- Export iTerm2 dynamic profile from rhadamanth → `molt-matts/config/iterm2/molt-profile.json`
- Export Terminal.app profile from rhadamanth → `molt-matts/config/terminal-app/Molt.terminal`

## Design Notes

- `gnome-terminal.sh` uses fixed UUID (`b1dfa3e8-9a6d-4c5e-8e7f-molt00000001`) for idempotent dconf management
- `iterm2.sh` uses dynamic profiles (JSON dropped into `~/Library/Application Support/iTerm2/DynamicProfiles/`)
- `terminal-app.sh` uses `open` to import `.terminal` files, `defaults write` to set default
- All four liberators follow the standard `_check/_install/_verify` lifecycle
