---
verblock: "15 Sep 2026:v0.21: Matthew Sinclair - config repos moved to ~/Devel/cfg; git and alacritty check coverage"
---

# Work In Progress

## Current Focus

**Nothing in flight.** Finished work lives in `done.md` (019 is the `~/Devel/cfg` move), the closed issues (`intent issues list --kind all`) and git.

TODO:

- **Flynn's jormungandr: parked by hv (15 Sep), "ignore that for now".** It would move its config repo with the same steps (below). Molt-flynn on rhadamanth is clean but 5 commits ahead of its origin, unpushed; pushing is Flynn's call.

Still open from the move:

- The Gtools `README.md:15` still says both working trees live in `~/Devel/prj/`. Handed to gtools-vc on 15 Sep at hv's request; it is Gtools' pen, not Molt's.

How a sleeve moves its config repos, for any later one:

1. Pull Molt to `549678e` or later, and Molt-matts. Survey: which repos exist (exact case on Linux), clean and pushed, nothing with its cwd inside, no Gtools CMS running.
2. Run the mv and the resleeve as ONE command: `mkdir -p ~/Devel/cfg && mv ~/Devel/prj/<repos> ~/Devel/cfg/ && MOLT_PRJ_DIR="$HOME/Devel/prj" "$HOME/Devel/prj/Molt/bin/molt" resleeve`. Once the mv lands `~/.zshenv` dangles, so a new shell (an agent's next Bash call included) has no `MOLT_PRJ_DIR`.
3. Repoint `~/.config/gtools/config.yaml` and `env` where they exist; `intent discover ~/Devel/cfg --depth 1`, then drop the old roots from `~/.config/intent/projects.json` (no remove verb).
4. Verify: `molt doctor` check 3 names `~/Devel/cfg/Molt-matts`, dotfile links resolve, `gtools doctor` where installed.

## Active Steel Threads

- None open. ST0001, ST0002 and ST0003 are closed.

## Waiting on hv

- (none)

## Upcoming Work

- **iTerm2 on rhadamanth still holds the Molt profile as rewritable** until it is relaunched, so a settings change to that profile can still write into Molt-matts. On any Mac, choose **Skip Dynamic Profiles** if iTerm2's Claude Code onboarding asks again.
- **Confirm iTerm2 keeps session GUIDs across a restart.** Per-session zsh history (Molt-matts `389ef6f`) is keyed on them, and only iTerm2's saved window state suggests they survive. Test at the next relaunch: run a distinctive command in one tab, quit and relaunch iTerm2, then press up-arrow in that tab (present) and in another (absent). If restored sessions get new GUIDs, key the files on window position instead.
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
