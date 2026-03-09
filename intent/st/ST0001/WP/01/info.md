---
verblock: "09 Mar 2026:v0.3: matts - Resolved via Parallels keyboard shortcuts"
wp_id: WP-01
title: "Fix Cmd key passthrough from Parallels"
scope: Medium
status: Done
---

# WP-01: Fix Cmd key passthrough from Parallels

## Objective

Get the Cmd (leftmeta) key from the macOS host (rhadamanth) through Parallels and into the Linux VM (kovacs), so that keyd can map it to a custom layer for CUA-style shortcuts. Cmd must remain distinct from Ctrl.

## Context

- keyd config is correct and ready (/etc/keyd/default.conf)
- The Cmd key was briefly working, then stopped after Parallels keyboard config changes
- Parallels appears to be swallowing Cmd at the hypervisor level
- Matt reset Parallels to defaults but Cmd is still not arriving in the VM
- Possible causes: Parallels keyboard profile, GNOME/Mutter compositor grab

## macOS Key Mapping Reference (rhadamanth)

This is the exhaustive map of how editing, cursor, and modifier keys work on macOS. The goal is to reproduce this behavior on kovacs (Ubuntu) via keyd.

### Hardware

- **Machine**: M4 MacBook Pro (Apple Silicon)
- **Keyboard layout**: Australian (`com.apple.keylayout.Australian`)
- **Built-in keyboard**: No Right Control, no Right Command
- **External keyboard (14248-3-0)**: Not currently connected (profile stored)
- **No custom DefaultKeyBinding.dict** — all standard macOS bindings
- **No hidutil remapping** active (null)

### Modifier Key Remapping (System Preferences)

| Keyboard         | Caps Lock | Left Control | Right Control |
| ---------------- | --------- | ------------ | ------------- |
| Built-in (0-0-0) | Control   | Caps Lock    | Caps Lock     |
| External (14248) | Caps Lock | Control      | Control       |
| Apple KB (1452)  | Caps Lock | Control      | Control       |

Net effect on built-in: **Caps Lock IS the Control key**. Physical Ctrl key becomes Caps Lock.

### Modifier Keys

| macOS Name | Symbol | USB HID   | Physical Position (built-in)      | Role in shortcuts                 |
| ---------- | ------ | --------- | --------------------------------- | --------------------------------- |
| Control    | `^`    | 0xE0/0xE4 | Caps Lock position (remapped)     | Terminal/Emacs control            |
| Option     | `⌥`    | 0xE2/0xE6 | Between Ctrl and Cmd (both sides) | Special chars, word-level editing |
| Command    | `⌘`    | 0xE3/0xE7 | Adjacent to Space (both sides)    | Primary shortcut modifier         |
| Shift      | `⇧`    | 0xE1/0xE5 | Standard position (both sides)    | Uppercase, extend selection       |
| Fn/Globe   |        | 0xE9      | Bottom-left corner                | Function keys, emoji picker       |

### Cursor Movement Keys

| Action                  | macOS Shortcut        | Emits / Behavior          | Ubuntu Equivalent Needed |
| ----------------------- | --------------------- | ------------------------- | ------------------------ |
| Character left          | `←`                   | Move left 1 char          | Same                     |
| Character right         | `→`                   | Move right 1 char         | Same                     |
| Word left               | `⌥←`                  | Move left 1 word          | `Ctrl+←`                 |
| Word right              | `⌥→`                  | Move right 1 word         | `Ctrl+→`                 |
| Line start (soft)       | `⌘←` or `Home`        | Move to start of line     | `Home`                   |
| Line end                | `⌘→` or `End`         | Move to end of line       | `End`                    |
| Line start (hard/col 0) | `Ctrl+A`              | Move to column 0          | `Ctrl+A` (terminal)      |
| Line end (hard)         | `Ctrl+E`              | Move to end of line       | `Ctrl+E` (terminal)      |
| Line up                 | `↑`                   | Move up 1 line            | Same                     |
| Line down               | `↓`                   | Move down 1 line          | Same                     |
| Paragraph up            | `⌥↑`                  | Move up 1 paragraph       | (no standard equivalent) |
| Paragraph down          | `⌥↓`                  | Move down 1 paragraph     | (no standard equivalent) |
| Page up                 | `Fn+↑` or `Page Up`   | Scroll up 1 page          | `Page Up`                |
| Page down               | `Fn+↓` or `Page Down` | Scroll down 1 page        | `Page Down`              |
| Document start          | `⌘↑` or `Ctrl+Home`   | Move to start of document | `Ctrl+Home`              |
| Document end            | `⌘↓` or `Ctrl+End`    | Move to end of document   | `Ctrl+End`               |

### Selection Keys (add Shift to any cursor movement)

| Action                   | macOS Shortcut | Ubuntu Equivalent Needed |
| ------------------------ | -------------- | ------------------------ |
| Select character left    | `⇧←`           | `Shift+←`                |
| Select character right   | `⇧→`           | `Shift+→`                |
| Select word left         | `⌥⇧←`          | `Ctrl+Shift+←`           |
| Select word right        | `⌥⇧→`          | `Ctrl+Shift+→`           |
| Select to line start     | `⌘⇧←`          | `Shift+Home`             |
| Select to line end       | `⌘⇧→`          | `Shift+End`              |
| Select line up           | `⇧↑`           | `Shift+↑`                |
| Select line down         | `⇧↓`           | `Shift+↓`                |
| Select to document start | `⌘⇧↑`          | `Ctrl+Shift+Home`        |
| Select to document end   | `⌘⇧↓`          | `Ctrl+Shift+End`         |
| Select all               | `⌘A`           | `Ctrl+A`                 |

### Editing Keys (CUA / Standard)

| Action           | macOS Shortcut | Ubuntu Equivalent Needed     |
| ---------------- | -------------- | ---------------------------- |
| Cut              | `⌘X`           | `Ctrl+X`                     |
| Copy             | `⌘C`           | `Ctrl+C`                     |
| Paste            | `⌘V`           | `Ctrl+V`                     |
| Undo             | `⌘Z`           | `Ctrl+Z`                     |
| Redo             | `⌘⇧Z`          | `Ctrl+Shift+Z` or `Ctrl+Y`   |
| Find             | `⌘F`           | `Ctrl+F`                     |
| Find next        | `⌘G`           | `Ctrl+G` or `F3`             |
| Find previous    | `⌘⇧G`          | `Ctrl+Shift+G` or `Shift+F3` |
| Replace          | `⌘⌥F`          | `Ctrl+H`                     |
| Save             | `⌘S`           | `Ctrl+S`                     |
| Save as          | `⌘⇧S`          | `Ctrl+Shift+S`               |
| New              | `⌘N`           | `Ctrl+N`                     |
| Open             | `⌘O`           | `Ctrl+O`                     |
| Close tab/window | `⌘W`           | `Ctrl+W`                     |
| Quit             | `⌘Q`           | `Ctrl+Q` or `Alt+F4`         |
| Print            | `⌘P`           | `Ctrl+P`                     |
| Bold             | `⌘B`           | `Ctrl+B`                     |
| Italic           | `⌘I`           | `Ctrl+I`                     |
| Underline        | `⌘U`           | `Ctrl+U`                     |

### Text Deletion Keys

| Action               | macOS Shortcut    | Ubuntu Equivalent Needed |
| -------------------- | ----------------- | ------------------------ |
| Delete char left     | `Backspace`       | `Backspace`              |
| Delete char right    | `Delete` / `Fn+⌫` | `Delete`                 |
| Delete word left     | `⌥⌫`              | `Ctrl+Backspace`         |
| Delete word right    | `⌥Delete`         | `Ctrl+Delete`            |
| Delete to line start | `⌘⌫`              | (no standard equivalent) |
| Delete to line end   | `Ctrl+K`          | `Ctrl+K` (terminal kill) |

### Terminal/Shell Keys (Emacs-style, same on both platforms)

| Action              | Shortcut | Notes                       |
| ------------------- | -------- | --------------------------- |
| Beginning of line   | `Ctrl+A` | Same on both platforms      |
| End of line         | `Ctrl+E` | Same on both platforms      |
| Forward char        | `Ctrl+F` | Same on both platforms      |
| Back char           | `Ctrl+B` | Same on both platforms      |
| Kill to end of line | `Ctrl+K` | Same on both platforms      |
| Kill word back      | `Ctrl+W` | Same on both platforms      |
| Transpose chars     | `Ctrl+T` | Same on both platforms      |
| Previous command    | `Ctrl+P` | Same on both platforms      |
| Next command        | `Ctrl+N` | Same on both platforms      |
| Search history      | `Ctrl+R` | Same on both platforms      |
| Clear screen        | `Ctrl+L` | Same on both platforms      |
| Interrupt (SIGINT)  | `Ctrl+C` | Same on both platforms      |
| EOF / logout        | `Ctrl+D` | Same (guarded by IGNOREEOF) |
| Suspend (SIGTSTP)   | `Ctrl+Z` | Same on both platforms      |

### Window/Tab Management

| Action                | macOS Shortcut   | Ubuntu Equivalent Needed          |
| --------------------- | ---------------- | --------------------------------- |
| New tab               | `⌘T`             | `Ctrl+Shift+T` (terminal)         |
| Close tab             | `⌘W`             | `Ctrl+Shift+W` (terminal)         |
| Next tab              | `⌘⇧]` or `⌃Tab`  | `Ctrl+Tab` or `Ctrl+PageDown`     |
| Previous tab          | `⌘⇧[` or `⌃⇧Tab` | `Ctrl+Shift+Tab` or `Ctrl+PageUp` |
| Switch to tab N       | `⌘1`..`⌘9`       | `Alt+1`..`Alt+9`                  |
| Split pane vertical   | `⌘D`             | (app-specific)                    |
| Split pane horizontal | `⌘⇧D`            | (app-specific)                    |
| New window            | `⌘N`             | `Ctrl+Shift+N` (terminal)         |
| Minimize              | `⌘M`             | `Super+H`                         |
| Full screen           | `⌘⌃F` or `Fn+F`  | `F11` or `Super+F`                |
| App switcher          | `⌘Tab`           | `Alt+Tab`                         |
| Spotlight/Search      | `⌘Space`         | `Super` (GNOME Activities)        |

### iTerm2-Specific Settings

| Setting                | Value              | Notes                                |
| ---------------------- | ------------------ | ------------------------------------ |
| Option Key Sends       | Normal (0)         | Option is NOT Meta (use for ⌥ chars) |
| Right Option Key Sends | Normal (0)         | Same                                 |
| Terminal type          | xterm-256color     | Standard                             |
| Font                   | HackNFM-Regular 12 | Hack Nerd Font Mono                  |

### Key Mapping Principles for Ubuntu (keyd)

1. **Command = Ctrl for CUA shortcuts**: On macOS, `⌘` is the primary shortcut modifier. On Ubuntu, `Ctrl` fills this role natively. The challenge is muscle memory — if using a Mac keyboard on kovacs, the physical `⌘` key should emit `Ctrl`.

2. **Option = word-level movement**: On macOS, `⌥+Arrow` moves by word. On Ubuntu, `Ctrl+Arrow` does this. If `⌘` is mapped to `Ctrl`, then `⌥` needs to emit `Ctrl` for word movement... but that conflicts with CUA.

3. **Terminal Ctrl keys must remain**: `Ctrl+C` (interrupt), `Ctrl+Z` (suspend), `Ctrl+A/E/K` (Emacs line editing) must work identically on both platforms. These use the physical Ctrl key on macOS (which is Caps Lock position, remapped).

4. **The fundamental tension**: macOS uses two modifier keys for what Ubuntu does with one (`Ctrl`). `⌘` for app shortcuts, `⌥` for word-level editing, `Ctrl` for terminal. Ubuntu uses `Ctrl` for all three. keyd needs to resolve this three-way merge.

## Solution (As-Built)

The fix was entirely in **Parallels keyboard shortcuts config** on rhadamanth (the macOS host):

- Parallels has a keyboard shortcuts mapping feature that intercepts Cmd+key combos before they reach the VM
- Configured Parallels to map Cmd+C → Ctrl+Shift+C, Cmd+V → Ctrl+Shift+V, Cmd+X → Ctrl+Shift+X
- This sends the standard terminal copy/paste chords (Ctrl+Shift+C/V/X) which Alacritty and GNOME Terminal handle natively
- **keyd is not involved** — translation happens at the hypervisor level
- keyd config (`/etc/keyd/default.conf`) reduced to minimal (no remapping needed)

### Why keyd didn't work

Parallels was converting Cmd+key combos to Ctrl+key before they reached the VM. `keyd monitor` showed `leftcontrol + c` when pressing Cmd+C, not `leftmeta + c`. The bare `leftmeta` keypress arrived correctly, but Parallels intercepted the combo. No amount of keyd config could fix a problem upstream of the input layer.

### Key principle preserved

Cmd != Ctrl. They remain distinct:

- **Cmd+C** → Ctrl+Shift+C → copy (via Parallels mapping)
- **Ctrl+C** → SIGINT (unchanged, direct)

## Deliverables

- [x] Working Cmd+C/V/X for copy/paste/cut in Alacritty and GNOME Terminal
- [x] Ctrl remains a separate modifier (Cmd ≠ Ctrl)
- [x] Documentation of the fix (this file + keyd config comment)

## Acceptance Criteria

- [x] Cmd+C/V/X work in Alacritty and other apps
- [x] Ctrl+C still sends SIGINT (not copy)
- [x] Terminal Emacs keys (Ctrl+A/E/K/C/Z) work correctly

## Status: DONE
