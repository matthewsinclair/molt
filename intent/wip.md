---
verblock: "22 Oct 2026:v0.34: Matthew Sinclair - globalfold; ST0006 WP06 done, WP04 rhadamanth next"
---

# Work In Progress

## Current Focus

**ST0006, sleeve agents, has one work package left: WP04, the moves.** A sleeve agent is a local agent (Claude Code) doing machine-oriented work on one host as the user, named `<hostname>-<role>` with roles `sysadm`, `ops`, `docs`, living in a home at `$MOLT_AGT_DIR/<name>/` rendered from a role in Molt-matts, with Claude Code's state in `$XDG_CONFIG_HOME/claude`, a guard that refuses a launch from `$HOME` or from a shell that missed the config dir, and, for `sysadm`, a managed deny floor root owns. kovacs-sysadm runs from its home under the floor; rhadamanth and gyges are not moved yet. The guide is `docs/guides/sleeve-agents.md`, which also records the three agent kinds, sleeve, project and estate, and their naming. Four project nodes share this checkout: vc specifies, validates and merges; cc builds code in `~/Devel/prj/Molt-wt/<branch>`; dc builds docs and fixes issues; ac authors. Everyone commits only their own paths from main, and only vc pushes.

## DOING

- **ST0006 WP04, the moves.** kovacs is done (AC008). rhadamanth is next on hv's date, by the runbook's rhadamanth section: Chrome's native host quit at B4, B9 only from a shell opened after the move; once rhadamanth declares `MOLT_CLAUDE_CONFIG_DIR` its next `molt upgrade` also installs the floor, with hv at the sudo prompt. gyges later, when Tailscale is on. The thread's contract already passes in full, so hv rules whether WP04 and ST0006 close after rhadamanth with gyges carried as a todo.
- **ST0005 WP03, gyges on Homebrew utilz**, when hv can reach gyges through gyges-infra.

## TODO

- **Issue 0032, hv's ruling: Claude Code's sandbox cannot start on Ubuntu.** `bwrap-userns-restrict` confines bwrap's children under a blanket capability deny, which an AppArmor local include cannot lift. Options in the issue: a Molt-managed replacement profile, disabling it plus the sysctl, or leaving ops and docs shell-less on Linux. Build on `molt_sudo_install` and `molt_sudo_remove`, now in `lib/molt.sh`; then dc's `kovacs-creds.sh` runs A and B for the bubblewrap table and the guide's "still owed" sentence goes.
- **Issue 0022** (Molt tracks `.claude/settings.local.json`): dc applies on hv's own word in dc's session, after Intent canon carries the keys; the three Intent defects on vc's board (todo 8) go to intent-vc when a session is up.
- **Issues 0015, 0016, 0018**: hv's rulings, as before (offline `molt upgrade`; `molt_error` to stderr; the manifest `depends` key).
- **rhadamanth's `molt upgrade` refuses while the shared checkout carries live board views** (P4). Use `molt resleeve` on dev days; the condition ends when rhadamanth's Molt comes from brew. Molt from brew is coming (hv), with no thread yet.
- **gyges, next time Tailscale is on, through gyges-infra**: ST0005 WP03 (`source = "brew"`, doctor); resync Molt and Molt-matts onto the purged histories (fetch, `reset --hard`, reflog expire, gc); check its Claude Code attribution config; `molt upgrade` for the npm liberator and the 21 and 22 Oct Molt-matts changes (it renders no floor until it declares the config dir); its sleeve agent becomes `gyges-sysadm` at its WP04 turn; declare `[terminal] bg_color` and regenerate the ssh wrapper; watch the first `molt upgrade` after Intent 3.2.1 (Intent 0527); the Gtools Sinclair estate deploy (gtools-vc's pen).
- **farcaster and pihole, when next reachable**: resync onto the purged histories; `molt upgrade` for the npm liberator, which configures nothing where npm is absent.
- **How a sleeve moves its config repos** (for Flynn's jormungandr, parked by hv): pull Molt and Molt-matts; mv and resleeve as ONE command with `MOLT_PRJ_DIR` set and molt by absolute path, since `~/.zshenv` dangles after the mv; repoint `~/.config/gtools/config.yaml`, `intent discover ~/Devel/cfg --depth 1`, drop the old roots from `~/.config/intent/projects.json`; `molt doctor` check 3 names `~/Devel/cfg/Molt-matts`.
- **Small, carried**: confirm the Tactile install hint's URL from another network (issue 0014; hv's, the classifier refuses the `--resolve` form to vc); test whether iTerm2 keeps session GUIDs across a restart (per-session history is keyed on them); Claude Code's iTerm2 triggers are not in the Molt dynamic profile; `desktop`'s gsettings block is hardcoded; devbin 0203 committed in devbin, unpushed; `floor.json` is read once to validate and once to install, so an edit mid-run could land unvalidated (the user's own file; noted, not an issue).
- **Not this project's**: the Gtools side of the estate-agent rename (the `-vc` references in Gtools-sinclair and Gtools-geodica, the Gtools contract's naming, and the Geodica content-root move to `~/Dropbox/Geodica`) is with sinclair-estate, geodica-estate and gtools-vc; Gtools `README.md:15` (gtools-vc); devbin's README snippet and `dvb` body copies (devbin-vc).

## Notes

Three sleeves in daily use: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels; farcaster and pihole are Pis with a small stack. `molt upgrade` = pull and fast config sync; `molt resleeve` = the sync without the pull; `molt maintain` = heavy system maintenance. `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

A sleeve takes the managed floor when its manifest enables a `sysadm` agent and its `vars.sh` declares `MOLT_CLAUDE_CONFIG_DIR`: `molt upgrade` then asks for sudo once to install `managed-settings.d/molt-sysadm.json` beside a sidecar it writes first, and the floor binds every Claude Code session on the sleeve, hv's included. Elsewhere Molt renders none, removes only a drop-in whose sidecar it wrote, and doctor's check 14 passes as none needed. Three agent kinds, three naming schemes: sleeve `<hostname>-<role>`, project `<project>-<suffix>`, estate `<estate>-estate`; an estate session must start in or below the directory holding the deployed `.claude/`, since Claude Code loads from the launch directory and its parents, never a child.

A rendered file is re-rendered when the digest of its inputs no longer matches the `.molt-rendered` sidecar, and since 21 Oct the sidecar also records the digest of what molt wrote, so only a hand edit is backed up. A builder's pre-commit gate runs `intent doctor` at the committed head in its worktree, so a whiteboard view a verb re-rendered must be committed with that verb's event, by its owner. Commit ids from before 20 Oct may be stale after the AI-attribution purge; `intent/ref/2026-10-20-history-purge-commit-maps.md` translates them.

The `backup` liberator observes; it never mounts, attaches or configures. `backup_verify` exits 2 when the share-side checks could not run, which is the normal state. `recentRuns` records finished runs only.
