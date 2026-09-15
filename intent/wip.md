---
verblock: "15 Sep 2026:v0.19: Matthew Sinclair - backup liberator verdicts; wip cut back to doing and todo"
---

# Work In Progress

## Current Focus

**Nothing in flight.** Finished work lives in `done.md` (017, 018), the closed issues (`intent issues list --kind all`) and git.

## Active Steel Threads

- None open. ST0001, ST0002 and ST0003 are closed.

## Waiting on hv

- **Port Intent's `pipefail_sigpipe_check.sh`?** Raised by vc on 8 Sep in `whiteboard/hv/inbox.vc.md`. No Molt site loses today; the case for it is growth. The guard is per-repo, so this is a fleet decision across Molt, Molt-matts, Utilz, devbin, Laksa and Lamplight. `lib/molt.sh:707` is the one site where the obvious herestring remedy is wrong.

## Upcoming Work

- **iTerm2 on rhadamanth still holds the Molt profile as rewritable** until it is relaunched, so a settings change to that profile can still write into Molt-matts. gyges needs to pull Molt-matts `b58e0d4`, and to choose **Skip Dynamic Profiles** if iTerm2's Claude Code onboarding asks again.
- **Claude Code's iTerm2 triggers are not in the Molt dynamic profile.** If wanted, add them to `config/iterm2/molt-profile.json` by hand so the change shows in git.
- **Sidecars record a case-folded path.** Every `.molt-rendered` names its template as `.../molt-matts/...` lowercase, the path molt resolved through case folding. Informational while the digest recomputes the path from its `source` argument, but it is on-disk state that survives a rename and would then resolve only on a case-insensitive filesystem.
- **The `intent` liberator's model breaks when Intent arrives via brew.** It assumes a source checkout: it finds `${MOLT_INTENT_HOME}/bin/intent` and links it into `~/bin`. A brew install lands at `/opt/homebrew/bin/intent`, which wins on PATH over both `~/.local/bin` and `~/bin`. Needs a rewrite rather than a patch. Not scheduled; hv's call. When it happens, `~/bin/intent` should go so there is one source of truth.
- **Decide whether `desktop` should own more of GNOME than it does.** It manages the GTK stylesheet (3.0 and 4.0) and dock favourites; its gsettings block is still hardcoded.

Carried, not this project's to fix:

- Devbin's `README.md:60` snippet still carries both defects fixed in `a4e6cb2`; the `dvb` body lives in three places and has diverged; `devbin doctor` reports surviving retired aliases but nothing reports a MISSING replacement. All three are devbin-vc's pen.

Carried from March, unverified from this sleeve -- confirm before acting:

- Tune iTerm2 SSH background colors after seeing them in practice
- Check rhadamanth's actual default background color (reset currently uses 000000)
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth

## Notes

Three sleeves: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels. `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

Configs are re-rendered when a content digest of (template + `instances/<host>/vars.sh`) no longer matches the one recorded in the `.molt-rendered` sidecar. It is not an mtime comparison: git restamps files whose content never changed, and across two filesystems mtime produces false negatives, which is the silent direction.

The `backup` liberator observes; it never mounts, attaches or configures. SuperDuper owns the share mount and the sparsebundle. `backup_verify` exits 2 when the share-side checks (SMB dialect, attach budget) could not run, which is the normal state because SuperDuper mounts the share only while copying. `recentRuns` in `tiles.json` records finished runs only, so a running copy is detected separately, and cancelled or failed runs are often hv's own interruptions.
