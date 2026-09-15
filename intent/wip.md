---
verblock: "15 Sep 2026:v0.20: Matthew Sinclair - backup liberator verdicts; CI on bash 3.2; per-session iTerm2 history"
---

# Work In Progress

## Current Focus

**In flight: move the config repos out of `~/Devel/prj/` into `~/Devel/cfg/`** -- Molt-matts, Molt-flynn and Gtools-geodica. hv asked on 15 Sep and said to continue straight after the localfold+compact. `~/Devel/cfg/` exists and is empty. Finished work lives in `done.md` (017, 018), the closed issues (`intent issues list --kind all`) and git.

Blast radius, measured on rhadamanth on 15 Sep:

- **10 symlinks dangle until `molt resleeve`**: `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.gitconfig`, `~/.gitconfig_matthewsinclair`, `~/.config/doom`, `~/.claude/keybindings.json`, VS Code `settings.json` and `keybindings.json`, and the iTerm2 `molt-profile.json`. A new shell opened before resleeve starts with no zsh config.
- **Gtools** reads `~/.config/gtools/config.yaml` (`manifest:`) and `~/.config/gtools/env` (`GTOOLS_CONFIG`). `~/.local/state/gtools/estate` is derived and rebuilds. Stop any running Gtools CMS first.
- **Intent's registry** `~/.config/intent/projects.json` has the Molt-matts and Molt-flynn roots. Gtools-geodica is not registered.
- `~/.ssh/config` and `~/.config/starship.toml` re-render once. Not affected: git remotes (GitHub and the Dropbox mirrors), Claude Code state, and `MOLT_PRJ_DIR` in `vars.sh`.
- Prose only: Gtools `README.md`, Molt `README.md`, `docs/guides/new-user.md`, and `projects_dir` in the template `molt.toml`.

The Molt side is done and needs no action: `MOLT_CFG_DIR` (`549678e`, issue 0005, closed). Each sleeve must pull Molt to `549678e` or later before it moves anything.

Per-machine steps:

1. Pull Molt, and Molt-matts, first.
2. Stop any Gtools CMS, and close shells and editors whose cwd is inside the repos.
3. Run the mv and the resleeve in one command: `mkdir -p ~/Devel/cfg && mv ~/Devel/prj/{Molt-matts,Molt-flynn,Gtools-geodica} ~/Devel/cfg/ && MOLT_PRJ_DIR="$HOME/Devel/prj" "$HOME/Devel/prj/Molt/bin/molt" resleeve`. The explicit env and absolute path matter: once the mv lands, `~/.zshenv` dangles, so any new shell (an agent's next Bash call included) has no `MOLT_PRJ_DIR`, and so no `MOLT_CFG_DIR` either.
4. Update the two Gtools config files and the Intent registry.
5. Verify with `molt doctor` (check 3 names `~/Devel/cfg/Molt-matts`) and a `gtools` command.

Order: hv chose gyges first (15 Sep). **gyges: done**, Molt-matts only. No gtools or Intent registry files exist there, doctor check 3 names `~/Devel/cfg/Molt-matts`, and every relinked dotfile resolves. Its auto mode refused the mv, so hv ran it on gyges. The resleeve backed up a regular-file `~/.gitignore_global` to `.gitignore_global.molt-backup.20260915135742`, differing only by `Icon` versus `Icon?`; deleting that is hv's call. **rhadamanth: done**. All three repos moved, and the resleeve relinked all 11 targets. `~/.config/gtools/config.yaml` and `env` are repointed (backups `*.pre-cfg-move.*`). The Intent registry now has the `~/Devel/cfg` roots via `intent discover ~/Devel/cfg --depth 1`, and the two old roots were removed by hand, since there is no remove verb (backup `projects.json.pre-cfg-move.*`). Doctor check 3, `gtools estate` and `gtools doctor` are all green, and gtools-vc/cc/ic were told.

Left for hv:

- `~/.claude/settings.json:167`: its allow rule still names `.../Devel/prj/Gtools-geodica/bin/mail-recent`. It is a permission setting, so vc did not touch it.
- The Gtools CMS and Gtools.app are stopped; restart them when wanted.
- Delete the `~/.gitignore_global.molt-backup.*` files on rhadamanth and gyges when wanted.
- Molt-matts `config/git/gitignore_global` ignores `*.sql` globally, since 9 Mar. Now linked, it hides no `.sql` file today (every ignored one is also covered by its repo's own `.gitignore`), but it will hide new ones.
- Doom projectile (`config/doom/custom/090-projectile-mode.el`) still searches only `~/Devel/prj`.
- The Gtools `README.md` prose still names the old path; that is the Gtools sessions' pen. kovacs follows; Flynn's jormungandr only if Flynn wants it. Molt-flynn on rhadamanth is clean but 5 commits ahead of its origin, unpushed. The move carries them along; pushing is Flynn's call.

## Active Steel Threads

- None open. ST0001, ST0002 and ST0003 are closed.

## Waiting on hv

- **Port Intent's `pipefail_sigpipe_check.sh`, or fix the 8 pipelines instead?** Raised by vc on 8 Sep in `whiteboard/hv/inbox.vc.md`. Molt has 8 `cmd | grep -q` pipelines. None loses today, because every writer's output is small, but under `pipefail` a writer that outgrows the ~64KB pipe buffer turns a found match into a failure, and in `if ! ... | grep -q` into a false "missing". vc's recommendation (15 Sep): skip the guard and convert the 8 sites to capture-then-match, as `lib/molt.sh:468` already does, tracked as an issue. `lib/molt.sh:707` needs an explicit empty-capture test first. The guard is per-repo, so porting it would be a fleet decision across Molt, Molt-matts, Utilz, devbin, Laksa and Lamplight.

## Upcoming Work

- **iTerm2 on rhadamanth still holds the Molt profile as rewritable** until it is relaunched, so a settings change to that profile can still write into Molt-matts. gyges needs to pull Molt-matts (`b58e0d4` profile, `389ef6f` history), and to choose **Skip Dynamic Profiles** if iTerm2's Claude Code onboarding asks again.
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
