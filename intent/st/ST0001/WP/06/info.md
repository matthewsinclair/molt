---
verblock: "08 Mar 2026:v0.3: matts - Audit complete, fixes applied"
wp_id: WP-06
title: "Highlander and Thin Coordinator audit"
scope: Small
status: Done
---

# WP-06: Highlander and Thin Coordinator audit

## Objective

Audit all config and setup produced during Phase 1 against three principles:

1. **Highlander Rule**: Each setting defined in exactly one place. No duplication of concerns across files.
2. **Thin Coordinator**: Config files should coordinate/source/delegate, not contain business logic or complex inline functions.
3. **PFIC** (Pure-Functional Idiomatic Code): Pattern matching over conditionals, pipelines for transformations, descriptive naming, no silent failures.

## Scope

- molt-matts/config/ (all dotfiles)
- Any config on kovacs that isn't yet in molt-matts
- keyd, systemd, and other system-level config

## Deliverables

- Audit report captured in this WP
- List of violations with severity and recommended fix
- Fixes applied (or deferred to other WPs if structural)

## Acceptance Criteria

- [ ] Every config file in molt-matts/config/ reviewed
- [ ] No Highlander violations remain (or are documented as accepted exceptions)
- [ ] No fat coordinators (shell rc files doing too much)
- [ ] Audit findings recorded below

## Dependencies

- None — this is the first WP to execute

---

## Audit Findings

### Files Reviewed

| File                             | Status   |
| -------------------------------- | -------- |
| config/zsh/zshrc                 | REVIEWED |
| config/zsh/zshenv                | REVIEWED |
| config/zsh/zprofile              | REVIEWED |
| config/git/gitconfig             | REVIEWED |
| config/tmux/tmux.conf            | REVIEWED |
| config/alacritty/alacritty.toml  | REVIEWED |
| config/starship/starship.toml    | REVIEWED |
| config/gtk/gtk.css               | REVIEWED |
| config/claude/keybindings.json   | REVIEWED |
| config/doom/\* (all files)       | REVIEWED |
| /etc/keyd/default.conf           | REVIEWED |
| Symlink integrity (all dotfiles) | VERIFIED |

---

### HIGHLANDER VIOLATIONS

#### H1: Git aliases defined in TWO places (MEDIUM)

- **Where**: `config/git/gitconfig` defines `lg` alias. `config/zsh/zshrc` defines `gs`, `ga`, `gc`, `gd`, `gco`, `gl`, `gsf`, `gpthis` as shell aliases.
- **Problem**: Git aliases live in two owners. The gitconfig `lg` alias is a git alias (`git lg`). The zshrc ones are shell aliases (`gs` expands to `git status`). These are technically different mechanisms, but they serve the same concern: "shortcuts for git commands."
- **Severity**: Medium. Not a direct conflict, but violates the spirit. Someone looking for "where are git shortcuts?" has to check two files.
- **Recommendation**: Pick one owner. Either move all git shortcuts to gitconfig as `[alias]` entries (and use `git st`, `git co`, etc.), or keep them all as shell aliases in zshrc. Not both. Shell aliases are more flexible (can do `gpthis` with subshell), so recommend: keep shell aliases in zshrc, remove gitconfig `lg` alias, add an equivalent `gl` variant if the graph format is wanted.

#### H2: Email address defined in TWO places (LOW)

- **Where**: `config/git/gitconfig` has `hello@matthewsinclair.com`. `config/doom/config.el` has `matthew.sinclair@gmail.com`.
- **Problem**: Two different email addresses, so not technically a duplication, but the "identity" concern is split across two files. If Matt changes his preferred email, he has to remember both.
- **Severity**: Low. These may legitimately be different (work vs personal), but worth noting.
- **Recommendation**: Document the intent. If they're intentionally different, add a comment in each. If they should be the same, unify.

#### H3: Font family defined in TWO places (LOW)

- **Where**: `config/alacritty/alacritty.toml` sets `family = "DejaVu Sans Mono"`. `config/doom/config.el` sets font to `"DejaVu Sans Mono"` (Linux) or `"Menlo"` (macOS).
- **Problem**: The font choice for the terminal and the editor are set independently. If you switch fonts (eg to a Nerd Font in WP-03), you need to update both.
- **Severity**: Low. These are genuinely different applications. But the coupling is worth noting for WP-03.
- **Recommendation**: When WP-03 (Nerd Fonts) is done, ensure both are updated. Consider whether a single "preferred font" variable could be sourced by both (future MOLT templating concern).

---

### THIN COORDINATOR VIOLATIONS

#### T1: zshrc is a FAT COORDINATOR (MEDIUM)

- **Where**: `config/zsh/zshrc` (124 lines)
- **Problem**: The zshrc contains multiple inline function definitions that are business logic, not coordination:
  - `path_add()` (lines 18-22) — utility function
  - `git_current_branch()` (line 64-66) — git helper
  - `jump/mark/unmark/marks` (lines 76-79) — bookmark system (4 functions)
  - `e()` (line 98) — emacs client wrapper
  - `noctrld()` (lines 101-106) — env var wrapper
- **What it should be**: A thin coordinator that sources/delegates. The functions above should live in separate script files (eg `~/.local/bin/` or `molt-matts/config/zsh/functions/`) and the zshrc should just source or autoload them.
- **Severity**: Medium. It works, but it's doing too much. The bookmark system alone is 4 functions + an alias. The zshrc should be: env vars, PATH, source tools, done.
- **Recommendation**: Extract functions into `config/zsh/functions/` and autoload them, or move utility scripts to `~/.local/bin/`. Keep zshrc to: env, path, history opts, completion, aliases (one-liners only), tool activation.

#### T2: doom/config.el is a FAT COORDINATOR (MEDIUM)

- **Where**: `config/doom/config.el` (173 lines)
- **Problem**: config.el is supposed to be the thin coordinator that loads the custom/\*.el modules. It does do that (lines 67-86), which is good. But it ALSO contains substantial inline logic:
  - Ispell/spell checking config (lines 94-112) — 18 lines including a function definition and advice
  - Frame geometry persistence (lines 119-163) — 44 lines, two functions, multiple hooks
- **What it should be**: Basic settings (user, font, theme) + `load!` calls to custom modules. That's it.
- **Severity**: Medium. The ispell and frame-geometry code should be in their own custom/\*.el files (eg `custom/110-ispell.el` and `custom/120-frame-geometry.el`).
- **Recommendation**: Extract ispell config to `custom/110-ispell.el`. Extract frame geometry to `custom/120-frame-geometry.el`. config.el becomes ~40 lines of pure coordination.

---

### PFIC VIOLATIONS

#### P1: Nested conditionals in zshrc path_add (LOW)

- **Where**: `config/zsh/zshrc` line 19
- **Problem**: `if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]` — nested conditional. In shell this is idiomatic, but could be cleaner as a guard-return pattern.
- **Severity**: Low. Shell is shell. This is about as clean as bash/zsh gets.
- **Recommendation**: Accept as-is. Shell doesn't have pattern matching like Elixir.

#### P2: Hardcoded Homebrew paths in doom/config.el (LOW)

- **Where**: `config/doom/config.el` lines 42-44
- **Problem**: Hardcoded `/opt/homebrew/bin` and `/opt/homebrew/opt/grep/libexec/gnubin`. Platform-specific paths baked into a config that's shared across platforms.
- **Severity**: Low. Guarded by `(when (memq window-system '(mac ns)))` so it only fires on macOS. But it's still hardcoded platform knowledge in a cross-platform file.
- **Recommendation**: Accept for now. The platform guard makes it safe. Could be extracted to a `custom/005-platform.el` if config.el gets slimmed down per T2.

---

### MISSING FROM MOLT-MATTS

#### M1: keyd config NOT in molt-matts (MEDIUM)

- **Where**: `/etc/keyd/default.conf` exists on kovacs but is NOT in `molt-matts/config/` or `molt-matts/instances/kovacs/`.
- **Problem**: This is system-level config that was hand-written. If kovacs is rebuilt, it's lost.
- **Severity**: Medium. It's parked/commented-out anyway, but the config should be captured.
- **Recommendation**: Add to `molt-matts/instances/kovacs/keyd/default.conf`. This is genuinely per-instance (different hardware = different key mappings).

#### M2: nvim/LazyVim config NOT in molt-matts (LOW)

- **Where**: `~/.config/nvim` is a git clone (LazyVim starter), not symlinked from molt-matts.
- **Problem**: If Matt customizes LazyVim, those customizations aren't captured.
- **Severity**: Low. If it's stock LazyVim with no customizations, this is fine.
- **Recommendation**: If/when nvim is customized, move config into molt-matts.

#### M3: .DS_Store files in molt-matts (TRIVIAL)

- **Where**: `config/.DS_Store`, `config/doom/.DS_Store`
- **Problem**: macOS junk files committed to the repo.
- **Recommendation**: Add `.DS_Store` to `.gitignore`, remove from tracking.

---

### CLEAN PASSES

These files passed audit with no issues:

- **config/zsh/zshenv**: Minimal, comment-only. Correct.
- **config/zsh/zprofile**: Empty placeholder to prevent system defaults. Correct.
- **config/git/gitconfig**: Clean, minimal, no duplication (except H1 above).
- **config/tmux/tmux.conf**: Clean, well-commented, no logic, pure config. Excellent.
- **config/alacritty/alacritty.toml**: Minimal, clean. Good thin config.
- **config/gtk/gtk.css**: Minimal, single concern. Good.
- **config/claude/keybindings.json**: Minimal, clean.
- **config/doom/init.el**: Standard Doom module list. Correct.
- **config/doom/packages.el**: Clean package declarations.
- **config/doom/early-init.el**: Platform-guarded performance tweaks. Clean.
- **config/doom/custom.el**: Auto-generated by Emacs. Leave alone.
- **Symlink integrity**: All dotfiles correctly symlinked from molt-matts. No orphans.
- **config/starship/starship.toml**: Clean, single concern. Good.

---

## Summary

| Category   | Finding                            | Severity | Action                    |
| ---------- | ---------------------------------- | -------- | ------------------------- |
| Highlander | H1: Git aliases in two places      | Medium   | Unify to one location     |
| Highlander | H2: Email in two places            | Low      | Document intent           |
| Highlander | H3: Font in two places             | Low      | Address in WP-03          |
| Thin Coord | T1: zshrc has inline functions     | Medium   | Extract to functions/ dir |
| Thin Coord | T2: config.el has inline logic     | Medium   | Extract to custom/\*.el   |
| PFIC       | P1: Nested conditional in path_add | Low      | Accept (shell idiom)      |
| PFIC       | P2: Hardcoded Homebrew paths       | Low      | Accept (guarded)          |
| Missing    | M1: keyd config not in molt-matts  | Medium   | Add to instances/kovacs/  |
| Missing    | M2: nvim config not tracked        | Low      | Track when customized     |
| Missing    | M3: .DS_Store files                | Trivial  | gitignore                 |

### Recommended Priority

1. **T1 + T2** (Fat coordinators) — these are the biggest structural issues
2. **H1** (Git aliases) — quick fix, pick one owner
3. **M1** (keyd config) — capture before it's forgotten
4. **M3** (.DS_Store) — trivial cleanup
5. Rest are low/accept

---

## Fixes Applied

All medium-severity items fixed on 08 Mar 2026:

| Finding                       | Fix Applied                                                                                                                                                                                                            |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| H1: Git aliases in two places | Removed `[alias]` section from gitconfig. Added `glg` alias to zshrc. All git shortcuts now in zshrc only.                                                                                                             |
| T1: zshrc fat coordinator     | Extracted `path_add`, `git_current_branch`, `jump`, `mark`, `unmark`, `marks` to `config/zsh/functions/`. zshrc now autoloads via `fpath`. `noctrld` kept inline (shell state manipulation). `e()` converted to alias. |
| T2: config.el fat coordinator | Extracted ispell config to `custom/110-ispell.el`. Extracted frame geometry to `custom/120-frame-geometry.el`. config.el down from 173 to 95 lines.                                                                    |
| M1: keyd not in molt-matts    | Copied `/etc/keyd/default.conf` to `instances/kovacs/keyd/default.conf`.                                                                                                                                               |
| M3: .DS_Store                 | Already in .gitignore, not tracked. Non-issue.                                                                                                                                                                         |

### Accepted (no fix needed)

| Finding                      | Reason                                                               |
| ---------------------------- | -------------------------------------------------------------------- |
| H2: Email in two places      | Different emails for different purposes (git vs emacs). Intentional. |
| H3: Font in two places       | Different apps, will unify when Nerd Fonts installed (WP-03).        |
| P1: Nested conditional       | Shell idiom, as clean as it gets.                                    |
| P2: Hardcoded Homebrew paths | Platform-guarded, safe.                                              |
| M2: nvim not tracked         | Stock LazyVim, no customizations yet.                                |
