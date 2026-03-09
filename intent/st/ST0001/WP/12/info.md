---
verblock: "09 Mar 2026:v0.1: matts - Initial WP"
wp_id: WP-12
title: "Emacs macOS keybindings on Linux"
scope: Small
status: Done
---

# WP-12: Emacs macOS Keybindings on Linux

## Problem

`010-keys.el` wraps all Cmd (Super/`s-`) keybindings in `(when (eq system-type 'darwin) ...)`. On Linux via Parallels, Cmd+C/V/X are mapped by the hypervisor to Ctrl+Shift+C/V/X. Emacs receives `C-S-c`, not `s-c` or `C-c`. So Cmd+C does nothing useful in Emacs.

## What Was Done

Added a `gnu/linux` block to `010-keys.el` that maps `C-S-` (Ctrl+Shift) combos to the same functions as the macOS `s-` bindings. This matches what Parallels actually sends when Cmd is pressed.

Updated the stale comment about keyd mapping Cmd→Ctrl (no longer accurate).

### Bindings Added

All core editing bindings: copy, paste, cut, select-all, undo, find, save, close-buffer, new-file, goto-line, kill-buffer, comment-toggle, tab-switching, quit, beginning/end of buffer/line/page, save-all.

macOS-only bindings (AppleScript dialogs, iconify-frame, preview) were intentionally excluded.

## Acceptance Criteria

- [x] Cmd+C/V/X/S/Z/A/F work in Emacs on kovacs
- [x] Ctrl+C (evil/emacs prefix) still works as before
- [x] No conflicts with Doom Evil mode defaults
- [x] `doom sync` runs clean after changes

## Dependencies

None (config change only)
