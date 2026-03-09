---
verblock: "09 Mar 2026:v0.2: matts - As-built: Tactile 7x3, liberator done"
wp_id: WP-13
title: "Tiling window manager (GNOME 46)"
scope: Medium
status: Done
---

# WP-13: Tiling Window Manager (GNOME 46)

## Problem

No tiling window management configured on kovacs. Windows must be manually positioned and resized.

## What Was Done

### Evaluated Ubuntu Tiling Assistant

Ubuntu Tiling Assistant was already installed but only supports direct keybinding tiling (Super+Arrow → half screen, etc.). No grid picker mode — you'd need to memorize a keybinding for every arrangement. Not viable for 20+ Divvy-style layouts.

### Installed Tactile Extension

Tactile (`tactile@lundal.io`) provides a Divvy-like two-step workflow:

1. Press trigger key → grid overlay appears on screen
2. Type two keys to define a rectangle (first key = one corner, second = opposite corner)
3. Window snaps to that rectangle

The keyboard physically maps to screen position — same mental model as Divvy on macOS.

### Configuration

- **Trigger:** Shift+Opt+Cmd+T (= `<Shift><Alt><Super>t` on Linux)
  - Can't use Shift+Alt+Super+D because Parallels passes it to macOS Divvy
- **Grid:** 7 columns x 3 rows
  ```
  Q W E R T Y U
  A S D F G H J
  Z X C V B N M
  ```
- **Gap:** 4px between tiled windows
- **Maximize:** enabled (full-grid selection maximizes)

### Technical Notes

- Installed manually: download zip from extensions.gnome.org, `gnome-extensions install`, requires logout/login
- Schema must be copied to `/usr/share/glib-2.0/schemas/` and compiled for gsettings to work
- Both `grid-cols`/`grid-rows` AND `col-N`/`row-N` weight settings must be set (they're independent)
- Parallels intercepts some Cmd combos before they reach the VM — keybinding choice constrained

### MOLT Integration

- `tiling.sh` liberator created: checks extension installed/active, configures grid and keybinding via gsettings
- Added to kovacs manifest (`molt.toml`) with `depends = ["desktop"]`

## Acceptance Criteria

- [x] Tiling shortcuts work (half-screen, quarter-screen, thirds, sixths, etc.)
- [x] Windows snap to grid with keyboard (two-key rectangle selection)
- [x] Configuration captured in MOLT (tiling.sh liberator, reproducible)
- [x] Documented which extension/approach was chosen and why

## Dependencies

- WP-12 (Emacs keybindings) — keybinding approach informed tiling shortcut choice
