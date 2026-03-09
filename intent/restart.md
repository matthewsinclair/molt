# Session Restart Context

## Last Session: 09 Mar 2026

### What Was Done

- WP-08 (Template system): `molt_render`, `molt_install_config`, 9 bats tests, SSH liberator updated, doctor checks 8-9
- WP-10 (chezmoi migration): rhadamanth fully resleeved, chezmoi retired
  - `.zprofile` updated with Homebrew `brew shellenv` init
  - Git config merged with `gitignore_global`, identity include
  - Git liberator links additional files
  - Fixed `bin/molt` symlink resolution and arithmetic crash
  - All 9 enabled liberators installed on rhadamanth
- 52 tests passing across both sleeves

### What's Next

- Verify WP-10 changes on kovacs (no regressions)
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Fix Cmd key passthrough (PARKED)
- Reproducible VM build (WP-07, future)

### Key Context

- `MOLT_PROJECTS_DIR` is required — set in `.zshenv` which is symlinked from molt-matts
- 15 liberators, no package installs, two sleeves (kovacs + rhadamanth)
- rhadamanth manifest: tmux disabled, iterm2 enabled, alacritty/gnome-terminal/keys/desktop disabled
- `hostname -s` used for all instance lookups (macOS returns rhadamanth.lan)
- chezmoi retired from rhadamanth — safety net at `github.com-matthewsinclair:matthewsinclair/cfg-dotfiles.git`
- `bin/molt` resolves symlinks before computing `MOLT_ROOT` (works via `~/bin/molt`)
- Doctor check 8 (SSH key) gives false warning on rhadamanth — key is named `personalid`, not `id_ed25519`
