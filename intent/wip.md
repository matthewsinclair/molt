---
verblock: "16 Oct 2026:v0.29: Matthew Sinclair - the Tactile URL check needs another network"
---

# Work In Progress

## Current Focus

**Nothing in flight.** Finished work lives in `done.md` (021 is the status line and the resleeve fixes), the closed issues (`intent issues list --kind all`) and git.

TODO:

- **Flynn's jormungandr: parked by hv (15 Sep), "ignore that for now".** It would move its config repo with the same steps (below). Molt-flynn on rhadamanth is clean but 5 commits ahead of its origin, unpushed; pushing is Flynn's call.

How a sleeve moves its config repos, for any later one:

1. Pull Molt to `549678e` or later, and Molt-matts. Survey: which repos exist (exact case on Linux), clean and pushed, nothing with its cwd inside, no Gtools CMS running.
2. Run the mv and the resleeve as ONE command: `mkdir -p ~/Devel/cfg && mv ~/Devel/prj/<repos> ~/Devel/cfg/ && MOLT_PRJ_DIR="$HOME/Devel/prj" "$HOME/Devel/prj/Molt/bin/molt" resleeve`. Once the mv lands `~/.zshenv` dangles, so a new shell (an agent's next Bash call included) has no `MOLT_PRJ_DIR`.
3. Repoint `~/.config/gtools/config.yaml` and `env` where they exist; `intent discover ~/Devel/cfg --depth 1`, then drop the old roots from `~/.config/intent/projects.json` (no remove verb).
4. Verify: `molt doctor` check 3 names `~/Devel/cfg/Molt-matts`, dotfile links resolve, `gtools doctor` where installed.

## Active Steel Threads

- None open. ST0001 to ST0004 are closed.

## Waiting on hv

- **Molt-matts `e3af373` (pushed) carries a `Co-Authored-By: Claude` and a `Claude-Session:` trailer**, against the no-attribution rule. Rewriting pushed history is hv's call; vc has not touched it.
- **The fleet sweep `intent claude upgrade --apply --skip-settings` is pending.** `intent doctor` on 15 Oct advised that CLAUDE.md and AGENTS.md are behind Intent 3.2.3's templates.
- **Issue 0015: what an offline `molt upgrade` should do.** A failed git pull (framework, user config, Doom config) is reported as "skipped", with a cause that cannot be true: an up-to-date pull exits 0. git's own reason goes to /dev/null. Making it fail needs a ruling: either stop the upgrade, or run the hooks on the trees it has and fail at the end.
- **Issue 0016, a separate pass if wanted:** `molt_error` writes to stdout, so a captured call's diagnostics never reach the user, eg the search-path help when no config repo is found. Sending error lines to stderr changes what every captured call collects.
- **`molt upgrade editors` on kovacs, when hv chooses.** The plain-sync path of 0013 has not run live there. Doom's record and the running Emacs both read 30.2, so it should run `doom sync` without `--rebuild`, show Doom's output and exit 0.

## Upcoming Work

### gyges, at the weekend, when hv starts it

hv, 15 Oct: "a weekend project, not tonight". gyges is at home in the UK. On 15 Oct `gyges.lan` did not resolve from rhadamanth and Tailscale was stopped, so start Tailscale first; changes on gyges go through gyges-infra (board watchout 16).

- **Deploy the Gtools Sinclair estate on gyges, visible inside the house to anyone at home.** A recreational hack-around; part of the point is to see whether a deploy like that can be done from here. Gtools is gtools-vc's pen, so bring it in.
- **Declare gyges' `[terminal] bg_color` and regenerate its ssh wrapper.** Read the live iTerm2 profile background first (rhadamanth's came from the plist: `plutil -extract "New Bookmarks" json -o - ~/Library/Preferences/com.googlecode.iterm2.plist`). Nothing checks the rendered wrapper (`~/.config/molt/iterm2-ssh-colors.sh`), so `molt upgrade` will not refresh it: it is regenerated only when `zsh_install` runs. gyges and kovacs carry the old one (exit status lost, reset to black) until then.
- **When Intent 3.2.1 reaches gyges, watch the first `molt upgrade` after the `brew upgrade`** (Intent 0527; the fix landed at Intent `9358663ff` and ships in 3.2.1). The 3.2.0 gate home names a keg the upgrade deletes. The intent check should report "install is gone", install should run `intent bootstrap`, and the home should then name `opt/intent/libexec`. It is the one path of ST0004 not yet seen live. No project on gyges has the pre-commit gate installed (hv: leave the hooks for now), so nothing is refused there meanwhile; `intent bootstrap` once by hand also repairs it.

### Other

- **Confirm the Tactile install hint's URL live** (issue 0014). Plain DNS for extensions.gnome.org fails from here. On 16 Oct the name resolved on neither rhadamanth (even unsandboxed) nor kovacs, and timed out when rhadamanth asked 1.1.1.1 and 8.8.8.8 directly, though both answer github.com. Cloudflare's DNS over HTTPS answers it (CNAME `ingress.openshift.gnome.org`, 54.221.220.94, TTL 60), so something on this network's path drops DNS for that name. From another network, `curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' 'https://extensions.gnome.org/download-extension/tactile@lundal.io.shell-extension.zip?shell_version=50.1'` should answer 302 with a versioned zip. On this one it needs `--resolve extensions.gnome.org:443:<address>`, with the address looked up again over DNS over HTTPS; Claude Code's auto-mode classifier refused that to vc, so it is hv's to run. It is GNOME Shell's own installer endpoint, and it appears only in the hint printed when Tactile is missing.
- **Confirm iTerm2 keeps session GUIDs across a restart.** Per-session zsh history (Molt-matts `389ef6f`) is keyed on them, and only iTerm2's saved window state suggests they survive. iTerm2 on rhadamanth last restarted 2026-09-22 21:40Z; whether the test was run then is not known, and a passive look at the history files (one born before that restart and written after it, within the same minute) proves nothing. Test at the next relaunch: run a distinctive command in one tab, quit and relaunch iTerm2, then press up-arrow in that tab (present) and in another (absent). If restored sessions get new GUIDs, key the files on window position instead.
- **Claude Code's iTerm2 triggers are not in the Molt dynamic profile** (still none, 23 Sep). If wanted, add them to `config/iterm2/molt-profile.json` by hand so the change shows in git.
- **Sidecars record the template path as of the last render, and nothing refreshes it.** `~/.ssh/config.molt-rendered` still names `~/Devel/prj/Molt-matts/config/ssh/config.tmpl`, the pre-move path, which no longer exists; starship's names `~/Devel/cfg/...`. The lowercase case-folding seen earlier is gone from both. Informational while the digest recomputes the path from its `source` argument.
- **Decide whether `desktop` should own more of GNOME than it does.** It manages the GTK stylesheet (3.0 and 4.0) and dock favourites; its gsettings block is still hardcoded.

Carried, not this project's to fix:

- The Gtools `README.md:15` still says both working trees live in `~/Devel/prj/`. Handed to gtools-vc on 15 Sep; Gtools' pen.
- Devbin's `README.md:60` snippet still carries both defects fixed in `a4e6cb2`; the `dvb` body lives in three places and has diverged; `devbin doctor` reports surviving retired aliases but nothing reports a MISSING replacement. All three are devbin-vc's pen.

Carried from March, unverified from this sleeve -- confirm before acting:

- Tune iTerm2 SSH background colors after seeing them in practice
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator (still none in the liberator or `config/gnome-terminal`, 23 Sep)
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority

## Notes

Three sleeves: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels. `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

Configs are re-rendered when a content digest of (template + `instances/<host>/vars.sh`) no longer matches the one recorded in the `.molt-rendered` sidecar. It is not an mtime comparison: git restamps files whose content never changed, and across two filesystems mtime produces false negatives, which is the silent direction.

The `backup` liberator observes; it never mounts, attaches or configures. SuperDuper owns the share mount and the sparsebundle. `backup_verify` exits 2 when the share-side checks (SMB dialect, attach budget) could not run, which is the normal state because SuperDuper mounts the share only while copying. `recentRuns` in `tiles.json` records finished runs only, so a running copy is detected separately, and cancelled or failed runs are often hv's own interruptions.
