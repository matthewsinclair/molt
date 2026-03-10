# Session Restart Context

## Last Session: 10 Mar 2026

### What Was Done

- Resleeved gyges (Mac Mini M2) as third Molt-managed sleeve
  - Cleaned chezmoi, RVM, old zsh plugins, archived ~/bin scripts
  - Relocated Doom Emacs: ~/.emacs.d -> ~/.config/emacs, ~/.doom.d backed up
  - Installed fzf, gh, neovim, VS Code 1.111.0 (replaced old manual install)
  - Generated ed25519 SSH key, added to GitHub
  - Created instances/gyges/ config, all 10 liberators installed
  - `molt doctor` all 9 checks pass
- Renamed `MOLT_PROJECTS_DIR` -> `MOLT_PRJ_DIR` across both repos (zero references remain)
- Added `MOLT_OPT_DIR` — derives from PRJ parent, overridable
- 55 tests passing (3 new for MOLT_OPT_DIR)

### What's Next

- `exec zsh` on gyges to pick up new shell config (RVM ghost functions in current session)
- Run `molt resleeve` on rhadamanth and kovacs (they need updated .zshenv with MOLT_PRJ_DIR)
- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- Export iTerm2 + Terminal.app profiles from rhadamanth

### Key Context

- Three sleeves: gyges (macOS M2), rhadamanth (macOS M4), kovacs (Ubuntu ARM64 VM)
- Symbolic directory vocabulary: `MOLT_PRJ_DIR` (projects), `MOLT_OPT_DIR` (third-party)
- `MOLT_PRJ_DIR` required (no default) — set in `.zshenv` symlinked from molt-matts
- `MOLT_OPT_DIR` defaults to `$(dirname "$MOLT_PRJ_DIR")/opt`
- 18 liberators, 55 tests
- gyges deviations noted: VS Code needed rm of old app before brew cask install, `doom sync` needs `--rebuild` flag
