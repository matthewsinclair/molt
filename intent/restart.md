# Session Restart Context

## Last Session: 27 Aug 2026 (globalfold -- closed clean)

### What Was Done

- **`dvb` shell function** landed in `molt-matts` (`a4e6cb2`): new autoload file `config/zsh/functions/dvb`, plus `dvb` added to the `autoload -Uz` list at `config/zsh/zshrc:11`. Walks up from `$PWD` to the nearest `bin/devbin` and runs it.
- Fixed two defects in the proposed body before landing it: `${^tried}` collapsed the candidate list onto one line (needs `[@]`), and `-x` with no `-f` arm let a mode-644 `bin/devbin` be stepped over so the walk ran a PARENT project's launcher and returned rc=0. The latter now stops at rc=126.
- Verified through the real config in a fresh shell -- rc=0 in a devbin project, rc=127 + multi-line candidate list from `$HOME`, rc=126 non-executable, rc=2 passed through -- and hv confirmed it live in their own shell.
- **Whiteboard** (`131642d`): provisioned the `hv` node and wrote `intent/whiteboard/README.md`, naming `vc` as the node obliged to read `hv/inbox.*` and surface it to the human. Until then nothing was named, so escalations had nowhere durable to land.
- **Re-cut `intent/wip.md`, `intent/restart.md` and `intent/done.md`** against the as-built. The first two were dated 12 Mar 2026 and claimed 83 tests / 19 liberators / v0.1.0.
- `vc` localfolded: session archived to `intent/whiteboard/vc/.history/20260827/wip.md`, board released to `status: paused`.

### What's Next

- ST0001/WP-04: document Phase 1 bootstrap steps
- ST0001/WP-07: reproducible VM build and self-upgrading Molt -- **partly met already**; `molt upgrade` exists with `--self`, `--dry-run` and targeted liberators, so three of six acceptance rows are arguably satisfied and only the VM-build half is untouched. Ticking rows is an `intent ac` change against canon and hv's call.
- `molt-matts` is an Intent project with ZERO steel threads and the `dvb` work landed there untracked. Opening its first thread is hv's call.
- Not Molt's to fix, tracked so it is not lost: devbin's `README.md:60` snippet still carries BOTH defects fixed in `a4e6cb2`; the `dvb` body now lives in three places and has already diverged, with `devbin shell-init zsh` as the durable fix; and `devbin doctor` reports a surviving retired alias but nothing reports a MISSING replacement. All three are devbin-vc's pen.
- Carried from March and unverified from this sleeve: gyges/kovacs starship deployment, gyges git remotes, iTerm2 colour tuning, rhadamanth default bg, GNOME Terminal Super bindings

### Key Context

- Measured 27 Aug 2026: 112 tests pass, ShellCheck clean over 27 scripts, 22 liberators, `VERSION` = 0.1.1, `intent doctor` 0 findings
- `~/.zshrc` is a symlink into `molt-matts/config/zsh/zshrc`; the functions dir is resolved from it via `readlink -f`. That resolves as `Molt-matts` (capital M) on this case-insensitive filesystem -- same inode, verified on three paths, not a second checkout.
- **Autoload files contain the BODY ONLY, no `dvb() { ... }` wrapper.** A wrapped file silently no-ops on first call (it merely defines the function) and works thereafter, which is worse than failing. `jump` and `git_current_branch` are the convention.
- `fpath` and `autoload` are read at shell startup -- a change to the functions dir needs a fresh shell, not a `source`
- A negative control with ONE candidate cannot see a list-formatting bug. Depth-1 failure cases prove the exit code and nothing about the output.
- VERSION file at project root is the single source of truth for the version
- CI runs bats on Linux and macOS; ShellCheck is non-blocking; git.bats needs a git user identity configured in the workflow
- iTerm2 SSH colors live in molt-{user} (user config), not the framework
- `molt upgrade` = config sync (fast, daily). `molt maintain` = system maintenance (slow, weekly)
- `envsubst` only substitutes `MOLT_*` variables -- safe for templates containing app `$vars`
- `doom upgrade` needs `--force` (Emacs `y-or-n-p` cannot read from shell stdin)
- The starship template has powerline chars (U+E0B0, U+E0B6) -- do not use the Write tool on it, it strips them
- `intent/wip.md`, `done.md`, and the ST `design/impl/tasks` files are authored, NOT renderer-owned; `intent/st/**/info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are generated and fenced in `.prettierignore`
- The whiteboard has two nodes: `hv` (human, `session_id: none`) and `vc`. Molt has no control node, so `vc` both validates and, when hv says so, builds. Roster: `intent/whiteboard/README.md`.
