# Session Restart Context

## Last Session: 11 Mar 2026

### What Was Done

- Added `molt maintain` command with `_maintain()` callback pattern
  - brew liberator: brew update/upgrade/cleanup/doctor + npm global update
  - editors_maintain(): `doom upgrade --force` (auto-accepts Emacs y-or-n-p prompts)
  - Supports targeted (`molt maintain brew`) and `--dry-run` modes
- Starship prompt: `matts@hostname` with per-host color via template
  - Converted starship.toml to .tmpl, added MOLT_PROMPT_HOST_COLOR to vars.sh
  - Fixed molt_render() to only substitute MOLT_* vars (envsubst filter)
  - Fixed zsh_check() to detect missing/dangling starship.toml
- Doom migration on rhadamanth: removed ~/.emacs.d and ~/.doom.d
- Removed share_history from zshrc (terminals no longer share history)
- 83 tests passing, 19 liberators

### What's Next

- Deploy to gyges: pull both repos + `molt resleeve` (will render starship template)
- Deploy to kovacs: same
- Fix gyges git remotes: named "upstream" with missing fetch refspecs
  - Fix: `git config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'`
- Persist GNOME Terminal Super bindings in gnome-terminal liberator

### Key Context

- `molt upgrade` = config sync (fast, daily). `molt maintain` = system maintenance (slow, weekly)
- envsubst now only substitutes MOLT_* variables -- safe for templates with app $vars
- doom upgrade uses --force to bypass Emacs y-or-n-p (reads from internal stdin, not terminal)
- Starship template uses powerline chars (U+E0B0, U+E0B6) -- Write tool strips these, use sed on git-extracted originals
- ~/.emacs.d.bak still exists on rhadamanth -- safe to remove once confirmed
- 19 liberators, 83 tests, three sleeves (kovacs, rhadamanth, gyges)
