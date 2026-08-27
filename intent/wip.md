---
verblock: "27 Aug 2026:v0.12: Matthew Sinclair - Intent v3 port, dvb shell function, whiteboard roster"
---

# Work In Progress

## Current Focus

**015: `dvb` shell function + whiteboard roster (DONE, 27 Aug 2026)**

- `dvb` autoload function added to `molt-matts/config/zsh/functions/dvb`, registered on the `autoload -Uz` line in `config/zsh/zshrc`. Walks up from `$PWD` to the nearest `bin/devbin` and runs it, passing the child's exit code through.
- Devbin's `9ce1c88` retired the per-project launcher symlinks and offered `dvb` as the replacement, but shipped it only as a README snippet -- so it existed nowhere in any shell. This closes that.
- Two defects were found and fixed against the proposed body before it landed: the candidate list collapsed onto one line (`${^tried}` needs `[@]`), and a `bin/devbin` at mode 644 was stepped over in silence, letting the walk run a PARENT project's launcher. The second now stops with rc=126 and says why.
- Verified through the real config in a fresh shell, not a synthetic fpath: rc=0 in a devbin project, rc=127 with a multi-line candidate list from `$HOME`, rc=126 on the non-executable case, rc=2 passed through from a failing child.
- Whiteboard: `hv` node provisioned and `intent/whiteboard/README.md` written, naming `vc` as the node obliged to read `hv/inbox.*` and surface it to the human. Before this the escalation surface had no reader.

**014: Intent v3 port (DONE, 26-27 Aug 2026)**

- Migrated to Intent v3 canonical store; ST prose carried into the store per file, byte-verified
- Closed threads dehydrated to flat views; generated views fenced from prettier (`.prettierignore`)
- `intent doctor` reports 0 findings across 2 threads, 26 views, 40 files

**013: Docs, CI/CD, versioning, and iTerm2 SSH colors (DONE, Mar 2026)**

- VERSION file as single source of truth; `constants.sh` reads it with fallback
- CHANGELOG.md in Keep a Changelog format
- GitHub Actions: tests (Linux + macOS), ShellCheck, PR checks
- README: CI badge, upgrade --self, maintain, lifecycle hooks, three sleeves
- iTerm2 SSH background color wrapper (molt-{user}): tints per host on SSH

**012: molt upgrade --self (DONE)** / **011: Doom migration, upgrade scripts, hostname in prompt (DONE)** / **010: molt git + centralised git operations (DONE)** / **009: gyges resleeve + symbolic directory vocabulary (DONE)** / **008: Cmd key proper fix + per-app keybindings (DONE)** / **007: Phase 5 -- Upgrade, Emacs Keys, Tiling, VS Code (DONE)** / **006: Rhadamanth resleeve + chezmoi migration (DONE)** / **005: Make Molt Sleeveable (DONE)** / **004: Split terminal liberator into per-emulator liberators (DONE)** / **003: Bats test suite and CLI commands (DONE)** / **002: MOLT framework scaffolding (DONE)**

## Active Steel Threads

- ST0001: Bootstrap -- WIP. WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are still open; the other eleven are done.
- ST0002: Proper per-instance config of per-instance variables -- Completed 2026-03-23.

## Upcoming Work

Verified open on this machine:

- ST0001/WP-04: document Phase 1 bootstrap steps
- ST0001/WP-07: reproducible VM build and self-upgrading Molt
- Reconcile ST0001's status: prior snapshots called Phase 1-6 complete while two work packages remain open

Carried forward from March, not verifiable from this sleeve -- confirm before acting:

- Deploy starship template to gyges and kovacs (pull + `molt resleeve`)
- Fix gyges git remotes: named "upstream" with missing fetch refspecs (`git config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'`)
- Tune iTerm2 SSH background colors after seeing them in practice
- Check rhadamanth's actual default background color (reset currently uses 000000)
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Run `molt resleeve` on kovacs (needs MOLT_PRJ_DIR in .zshenv)

## Notes

Measured 27 Aug 2026: **112 tests pass**, ShellCheck clean over 27 scripts, **22 liberators**, `VERSION` = **0.1.1**, `intent doctor` 0 findings. Earlier snapshots claimed 83 tests / 19 liberators / v0.1.0 and were five months stale.

Three sleeves operational (kovacs, rhadamanth, gyges). `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. The VERSION file is the single source of truth for the version number.
