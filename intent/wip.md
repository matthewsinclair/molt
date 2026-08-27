---
verblock: "27 Aug 2026:v0.13: Matthew Sinclair - globalfold: dvb, whiteboard roster, snapshots re-cut"
---

# Work In Progress

## Current Focus

Nothing in flight. The session of 27 Aug 2026 closed out clean -- full detail for each item below is in `done.md`.

**015: `dvb` shell function, whiteboard roster, snapshot re-cut (DONE, 27 Aug 2026)** -- `dvb` installed in molt-matts and verified in a fresh shell; two defects in the proposed body fixed before landing; `hv` node and roster README stood up so the escalation surface has a named reader; `wip.md` / `restart.md` re-cut off five-month-stale March figures. Commits `131642d` (molt), `a4e6cb2` (molt-{user}).

**014: Intent v3 port (DONE, 26-27 Aug 2026)** -- migrated to the v3 canonical store, ST prose carried per file and byte-verified, generated views fenced from prettier. `intent doctor` 0 findings.

**013 and earlier** -- see `done.md`.

## Active Steel Threads

- ST0001: Bootstrap -- WIP. WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are open; the other eleven are done.
- ST0002: Proper per-instance config of per-instance variables -- Completed 2026-03-23.

## Upcoming Work

Verified open on this machine:

- ST0001/WP-04: document Phase 1 bootstrap steps
- ST0001/WP-07: reproducible VM build and self-upgrading Molt. **Partly met already** -- `molt upgrade` exists with `--self`, `--dry-run` and targeted liberators, so three of its six acceptance rows are arguably satisfied and only the VM-build half is untouched. Which rows to tick is an `intent ac` change against canon and hv's call.
- `molt-matts` is an Intent project with zero steel threads, and the `dvb` work landed there untracked. Opening its first thread is hv's call.

Not this project's to fix, tracked so it is not lost:

- Devbin's `README.md:60` snippet still carries both defects fixed in `a4e6cb2`, so anyone pasting from it gets a shortcut that can run the wrong project's launcher and report success. Routed to devbin-vc.
- The `dvb` body now lives in three places and has already diverged. The durable fix is devbin shipping `devbin shell-init zsh`; devbin-vc holds that pen.
- `devbin doctor` reports a surviving retired alias but nothing reports a MISSING replacement, which is why `dvb` went unnoticed from `9ce1c88` until hv found it by opening shells.

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

Measured 27 Aug 2026: **112 tests pass**, ShellCheck clean over 27 scripts, **22 liberators**, `VERSION` = **0.1.1**, `intent doctor` 0 findings. Snapshots before this session claimed 83 tests / 19 liberators / v0.1.0 and were five months stale.

Three sleeves operational (kovacs, rhadamanth, gyges). `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. The VERSION file is the single source of truth for the version number.
