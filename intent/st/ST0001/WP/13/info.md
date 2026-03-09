---
verblock: "09 Mar 2026:v0.1: matts - Initial WP"
wp_id: WP-13
title: "Tiling window manager (GNOME 46)"
scope: Medium
status: WIP
---

# WP-13: Tiling Window Manager (GNOME 46)

## Problem

No tiling window management configured on kovacs. Windows must be manually positioned and resized.

## Current State

- GNOME 46 on Wayland
- Ubuntu Tiling Assistant already installed (`gnome-shell-extension-ubuntu-tiling-assistant`)
- Super key overlay disabled (desktop liberator)
- No other tiling extensions (pop-shell, forge, etc.)

## Approach

Exploratory — start with what's already there before adding new extensions.

### Phase 1: Configure Ubuntu Tiling Assistant

- Research what Tiling Assistant exposes via gsettings/dconf
- Configure snap assist, tile groups, custom layouts
- Set up keybindings that work with the Cmd key (via Parallels Ctrl+Shift mapping)

### Phase 2: Evaluate & Extend (if needed)

If Tiling Assistant is insufficient, consider:

- **Forge** — GNOME extension, more powerful tiling, auto-tiles
- **Pop-shell** — COSMIC-style tiling, more opinionated
- Both are GNOME extensions, not full WM replacements

### Phase 3: MOLT Integration

- New `tiling.sh` liberator, or extend `desktop.sh`
- Config in `molt-matts/instances/kovacs/` for per-instance tiling prefs

## Acceptance Criteria

- [ ] Tiling shortcuts work (half-screen, quarter-screen, etc.)
- [ ] Windows snap to grid with keyboard
- [ ] Configuration captured in MOLT (reproducible)
- [ ] Documented which extension/approach was chosen and why

## Dependencies

- WP-12 (Emacs keybindings) — keybinding approach informs tiling shortcuts
