# Session Restart Context

## Last Session: 09 Mar 2026

### What Was Done

- Stripped package manager calls from 7 liberators (system, zsh, git, tmux, editors, dev-tools, utilz)
- Added `molt resleeve --dry-run`
- Created `rhadamanth/molt.toml` manifest and `bin/bootstrap.sh`
- Forensic review: fixed SSH key detection, config.d idempotency, errexit resilience, editors guards, molt_render backups, zsh macOS compat
- Removed hardcoded `MOLT_PROJECTS_DIR` default -- must be set via env var
- Added `MOLT_PROJECTS_DIR` to zshenv, zshrc, instance vars.sh, sleeve manifests
- Updated README with all changes
- Fixed `hostname -s` across entire codebase for macOS compat
- All tests passing on kovacs

### What's Next

- Commit and push changes from both repos (molt + molt-matts)
- First resleeve dry-run then resleeve on rhadamanth
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Fix Cmd key passthrough (PARKED)

### Key Context

- `MOLT_PROJECTS_DIR` is now required -- set in `.zshenv` which is symlinked from molt-matts
- Running molt from a non-zsh context (e.g. bash, cron) needs `MOLT_PROJECTS_DIR` set explicitly
- 15 liberators, no package installs, two sleeves (kovacs + rhadamanth)
- rhadamanth manifest: tmux disabled, iterm2 enabled, alacritty/gnome-terminal/keys/desktop disabled
- `hostname -s` used for all instance lookups (macOS returns rhadamanth.lan)
