---
verblock: "23 Sep 2026:v0.22: Matthew Sinclair - ST0004: Intent from Homebrew on gyges; Molt off rhadamanth's Intent"
---

# Work In Progress

## Current Focus

**Nothing in flight.** Finished work lives in `done.md` (020 is ST0004, Intent from Homebrew), the closed issues (`intent issues list --kind all`) and git.

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

- None open. ST0001 to ST0004 are closed.

## Waiting on hv

- **Clear vc's four 8 Sep messages from hv's inbox.** All four are actioned (issues 0001, 0002 and 0008 closed; ST0001 closed). It is hv's inbox, so only hv clears it: `intent wb clear vc --node hv`.

## Upcoming Work

- **Confirm iTerm2 keeps session GUIDs across a restart.** Per-session zsh history (Molt-matts `389ef6f`) is keyed on them, and only iTerm2's saved window state suggests they survive. iTerm2 on rhadamanth last restarted 2026-09-22 21:40Z; whether the test was run then is not known, and a passive look at the history files (one born before that restart and written after it, within the same minute) proves nothing. Test at the next relaunch: run a distinctive command in one tab, quit and relaunch iTerm2, then press up-arrow in that tab (present) and in another (absent). If restored sessions get new GUIDs, key the files on window position instead.
- **The ssh wrapper resets a tab to `#000000`, but rhadamanth's base iTerm2 profile is `#15191F`** -- separate light and dark colours, both `#15191F`, in the 10 Mar export (Molt-matts `config/iterm2/profile.json`; macOS is in Light mode). A tab comes back from ssh slightly blacker than it started. The reset is `liberators/zsh.sh:69`; resetting to the profile's colour is small. Not scheduled; hv's call. The live profile may differ from the export.
- **Claude Code's iTerm2 triggers are not in the Molt dynamic profile** (still none, 23 Sep). If wanted, add them to `config/iterm2/molt-profile.json` by hand so the change shows in git.
- **Sidecars record the template path as of the last render, and nothing refreshes it.** `~/.ssh/config.molt-rendered` still names `~/Devel/prj/Molt-matts/config/ssh/config.tmpl`, the pre-move path, which no longer exists; starship's names `~/Devel/cfg/...`. The lowercase case-folding seen earlier is gone from both. Informational while the digest recomputes the path from its `source` argument.
- **When Intent 3.2.1 reaches gyges, watch the first `molt upgrade` after the `brew upgrade`** (Intent 0527; the fix landed at Intent `9358663ff` and ships in 3.2.1). The 3.2.0 gate home names a keg the upgrade deletes. The intent check should report "install is gone", install should run `intent bootstrap`, and the home should then name `opt/intent/libexec`. It is the one path of ST0004 not yet seen live. No project on gyges has the pre-commit gate installed (hv: leave the hooks for now), so nothing is refused there meanwhile; `intent bootstrap` once by hand also repairs it.
- **Decide whether `desktop` should own more of GNOME than it does.** It manages the GTK stylesheet (3.0 and 4.0) and dock favourites; its gsettings block is still hardcoded.

Carried, not this project's to fix:

- Devbin's `README.md:60` snippet still carries both defects fixed in `a4e6cb2`; the `dvb` body lives in three places and has diverged; `devbin doctor` reports surviving retired aliases but nothing reports a MISSING replacement. All three are devbin-vc's pen.

Carried from March, unverified from this sleeve -- confirm before acting:

- Tune iTerm2 SSH background colors after seeing them in practice
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator (still none in the liberator or `config/gnome-terminal`, 23 Sep)
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority

## Notes

Three sleeves: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels. `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

Configs are re-rendered when a content digest of (template + `instances/<host>/vars.sh`) no longer matches the one recorded in the `.molt-rendered` sidecar. It is not an mtime comparison: git restamps files whose content never changed, and across two filesystems mtime produces false negatives, which is the silent direction.

The `backup` liberator observes; it never mounts, attaches or configures. SuperDuper owns the share mount and the sparsebundle. `backup_verify` exits 2 when the share-side checks (SMB dialect, attach budget) could not run, which is the normal state because SuperDuper mounts the share only while copying. `recentRuns` in `tiles.json` records finished runs only, so a running copy is detected separately, and cancelled or failed runs are often hv's own interruptions.
