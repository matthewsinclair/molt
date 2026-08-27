# Session Restart Context

## Last Session: 27 Aug 2026

### What Was Done

- **`dvb` shell function** landed in `molt-matts` (two edits): new autoload file `config/zsh/functions/dvb`, and `dvb` added to the `autoload -Uz` list at `config/zsh/zshrc:11`. It walks up from `$PWD` to the nearest `bin/devbin` and runs it.
- Fixed two defects in the body before landing it: `${^tried}` collapsed the candidate list onto one line (needs `[@]`), and a non-executable `bin/devbin` was skipped in silence so the walk could run a parent project's launcher instead. The latter now stops at rc=126.
- Verified through the real config in a fresh shell: rc=0 in a devbin project, rc=127 + multi-line candidate list from `$HOME`, rc=126 non-executable, rc=2 passed through from a failing child.
- **Whiteboard**: provisioned the `hv` node and wrote `intent/whiteboard/README.md`, which names `vc` as the node obliged to read `hv/inbox.*` and surface it to the human. Until now nothing was named, so escalations had nowhere durable to land.
- **Refreshed `intent/wip.md` and this file** against the as-built. Both were dated 12 Mar 2026 and claimed 83 tests / 19 liberators / v0.1.0.

### What's Next

- ST0001/WP-04: document Phase 1 bootstrap steps
- ST0001/WP-07: reproducible VM build and self-upgrading Molt
- Reconcile ST0001's status -- prior snapshots called Phase 1-6 complete while WP-04 and WP-07 are still open
- Devbin gap (devbin-vc's pen, not Molt's): `devbin doctor` reports a surviving retired alias but nothing reports a MISSING replacement, which is why `dvb` went unnoticed from `9ce1c88` until hv found it by opening shells
- Highlander risk to book: the `dvb` body now exists in three places -- `devbin/README.md:60`, `devbin/usage-rules.md:66` (prose), and `molt-matts/config/zsh/functions/dvb`. The durable fix is devbin shipping `devbin shell-init zsh`.
- Carried from March and unverified from this sleeve: gyges/kovacs starship deployment, gyges git remotes, iTerm2 colour tuning, rhadamanth default bg, GNOME Terminal Super bindings

### Key Context

- Measured 27 Aug 2026: 112 tests pass, ShellCheck clean over 27 scripts, 22 liberators, `VERSION` = 0.1.1, `intent doctor` 0 findings
- `~/.zshrc` is a symlink into `molt-matts/config/zsh/zshrc`; the functions dir is resolved from it via `readlink -f`. Note the path resolves as `Molt-matts` (capital M) on this case-insensitive filesystem -- same inode, not a second checkout.
- **Autoload files contain the BODY ONLY, no `dvb() { ... }` wrapper.** A wrapped file silently no-ops on first call (it merely defines the function) and works thereafter, which is worse than failing. `jump` and `git_current_branch` are the convention.
- `fpath` and `autoload` are read at shell startup -- a change to the functions dir needs a fresh shell, not a `source`
- VERSION file at project root is the single source of truth for the version
- CI runs bats on Linux and macOS; ShellCheck is non-blocking; git.bats needs a git user identity configured in the workflow
- iTerm2 SSH colors live in molt-{user} (user config), not the framework
- `molt upgrade` = config sync (fast, daily). `molt maintain` = system maintenance (slow, weekly)
- `envsubst` only substitutes `MOLT_*` variables -- safe for templates containing app `$vars`
- `doom upgrade` needs `--force` (Emacs `y-or-n-p` cannot read from shell stdin)
- The starship template has powerline chars (U+E0B0, U+E0B6) -- do not use the Write tool on it, it strips them
- `intent/wip.md`, `done.md`, and the ST `design/impl/tasks` files are authored, NOT renderer-owned; `intent/st/**/info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are generated and fenced in `.prettierignore`
