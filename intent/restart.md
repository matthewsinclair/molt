# Session Restart Context

## Last Session: 09 Mar 2026

### What Was Done

- Split `terminal.sh` into four per-emulator liberators: `alacritty.sh`, `gnome-terminal.sh`, `iterm2.sh`, `terminal-app.sh`
- Created `molt-matts/config/gnome-terminal/profile.dconf` (Molt profile: JetBrainsMono NF 14pt, dark theme, unlimited scrollback)
- Ran gnome-terminal liberator — profile loaded via dconf, set as default
- Fixed stdout leak in `cmd_list`/`cmd_doctor` — `_check` info messages no longer pollute list output
- Enforced "no package install" rule — all four liberators fail with hint if binary missing
- Updated `molt-matts/instances/kovacs/molt.toml` — replaced `terminal` with `alacritty` + `gnome-terminal` (enabled) + `iterm2` + `terminal-app` (disabled)
- Deleted `liberators/terminal.sh`
- All tests pass, `molt doctor` clean, `molt list` clean

### What's Next

- Export iTerm2 dynamic profile and Terminal.app profile from rhadamanth → fill placeholder configs
- WP-02: Set up kovacs SSH for direct GitHub access
- WP-03: Install Nerd Fonts
- WP-01: Fix Cmd key passthrough (PARKED)
- Commit and push changes from both repos

### Key Context

- 15 liberators now (was 12, +4 new, -1 deleted terminal.sh)
- gnome-terminal uses fixed UUID `b1dfa3e8-9a6d-4c5e-8e7f-molt00000001` for idempotent dconf management
- iterm2 and terminal-app are macOS-only placeholders — config files not yet exported from rhadamanth
- `&>/dev/null` fix in `lib/molt.sh` suppresses all \_check output during list/doctor (was only suppressing stderr)
