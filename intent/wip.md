---
verblock: "21 Oct 2026:v0.32: Matthew Sinclair - localfold; ST0006 sleeve agents in build"
---

# Work In Progress

## Current Focus

**ST0006, sleeve agents, is in build.** A sleeve agent is a local agent (Claude Code) doing machine-oriented work on one host as the user, named `<hostname>-<role>` with roles `sysadm`, `ops`, `docs`. It gets a home at `$MOLT_AGT_DIR/<name>/` (default `~/Devel/agt`), declared as an `[[agent]]` entry and rendered from a role profile in Molt-matts; the harness state leaves `$HOME` for `$XDG_CONFIG_HOME/claude`; a Claude launched in `$HOME` is refused. The thread's context carries hv's rulings and the verified Claude Code facts; read it before touching any of this. Three sessions share this checkout: vc specifies, validates, reviews and merges; molt-cc builds code on `~/Devel/prj/Molt-wt/<branch>`; molt-dc builds the guide; kovacs-sysadm plans its own move. Everyone commits only their own paths from main.

**ST0005 stays open for gyges alone** (utilz from Homebrew there; WP03), until hv can reach it.

TODO:

- **Flynn's jormungandr: parked by hv (15 Sep), "ignore that for now".** It would move its config repo with the same steps (below). Molt-flynn on rhadamanth is clean but 5 commits ahead of its origin, unpushed; pushing is Flynn's call.

How a sleeve moves its config repos, for any later one:

1. Pull Molt to `06ca019` or later, and Molt-matts. Survey: which repos exist (exact case on Linux), clean and pushed, nothing with its cwd inside, no Gtools CMS running.
2. Run the mv and the resleeve as ONE command: `mkdir -p ~/Devel/cfg && mv ~/Devel/prj/<repos> ~/Devel/cfg/ && MOLT_PRJ_DIR="$HOME/Devel/prj" "$HOME/Devel/prj/Molt/bin/molt" resleeve`. Once the mv lands `~/.zshenv` dangles, so a new shell (an agent's next Bash call included) has no `MOLT_PRJ_DIR`.
3. Repoint `~/.config/gtools/config.yaml` and `env` where they exist; `intent discover ~/Devel/cfg --depth 1`, then drop the old roots from `~/.config/intent/projects.json` (no remove verb).
4. Verify: `molt doctor` check 3 names `~/Devel/cfg/Molt-matts`, dotfile links resolve, `gtools doctor` where installed.

## Active Steel Threads

- **ST0006, sleeve agents.** Order of landing: WP01 (molt-cc, in build on `st0006-wp01`: the claude liberator honours `CLAUDE_CONFIG_DIR`, renders env.sh, the GUI file and the `$HOME` hook, moves the state once, links the user-scope `CLAUDE.md`/`AGENTS.md`; everything gated on the sleeve declaring `MOLT_CLAUDE_CONFIG_DIR`), then WP02 (molt-cc: `[[agent]]`, `MOLT_AGT_DIR`, the agents liberator with the per-instance overlay, `molt agent list|config`), then WP05 (molt-dc, the guide; plan shown to hv first), then WP03 (Molt-matts: roles, `[[agent]]` entries, zshenv line, `config/claude/CLAUDE.md` and `AGENTS.md` seeds; the variable is NOT declared there), then WP04 (kovacs first: phase A copy-only by kovacs-sysadm once its home renders, phase B by hv declaring the variable and running the move with every Claude quit, phase C verify; then rhadamanth with Chrome quit; gyges later), then WP06 (managed deny floor for sysadm; hv names the floor's contents). vc reviews each WP against its ACs before merging; cc records ATs on main.
- **ST0005, WP03 (WIP): roll the per-sleeve `source` out to gyges.** hv agreed brew for gyges. Set `source = "brew"` on its utilz entry, run `molt doctor` there through gyges-infra, then close WP03 and the thread. The WP body records where each sleeve stands.

## Waiting on hv

- **ST0006 WP06: the contents of the sysadm deny floor**, when WP01 to WP05 have landed. The mechanism is specified; what sysadm may never do is hv's.
- **Molt from brew is coming (hv, 21 Oct), not today, and no thread carries it yet.** ST0006 renders nothing that names a checkout path so as not to make it harder.
- **Issue 0015: what an offline `molt upgrade` should do.** A failed git pull (framework, user config, Doom config) is reported as "skipped", with a cause that cannot be true: an up-to-date pull exits 0. git's own reason goes to /dev/null. Making it fail needs a ruling: either stop the upgrade, or run the hooks on the trees it has and fail at the end. utilz's checkout-mode pull has the same shape.
- **Issue 0016, a separate pass if wanted:** `molt_error` writes to stdout, so a captured call's diagnostics never reach the user, eg the search-path help when no config repo is found. Sending error lines to stderr changes what every captured call collects.
- **Issue 0018: the manifest's `depends` key is documented as ordering liberators, and nothing reads it.** Make molt honour it, assert it in doctor as check 4 does `user_repo`, or drop it from the manifests and the docs.
- **GitHub still serves the purged commits by their old ids** until its own garbage collection, and Molt is public. GitHub Support can remove them sooner if hv wants that.
- **devbin issue 0203 (its README's Homebrew section) is committed in devbin as `6ba65d73`, not pushed.** Pushing it is devbin's, or hv's.
- **`molt upgrade editors` on kovacs.** hv's full `molt upgrade` there on 20 Oct runs the editors hook, so the plain-sync path of issue 0013 has probably run by now. vc has not seen its output; ask kovacs-sysadm for the editors lines if it matters.

## Upcoming Work

### gyges, the next time Tailscale is on and hv can see it

gyges is at home in the UK, and changes on it go through gyges-infra (board watchout 16).

- **ST0005 WP03:** `source = "brew"` on gyges' utilz entry, then `molt doctor`.
- **ST0006 WP04 on gyges:** declare `MOLT_CLAUDE_CONFIG_DIR`, run the move with every Claude quit, and its sleeve agent becomes `gyges-sysadm` (hv: later, not today).
- **Resync its Molt and Molt-matts clones onto the purged histories:** nothing local, fetch, `reset --hard`, reflog expire, gc. These are the steps kovacs ran on 20 Oct (board todo 5).
- **Check gyges' Claude Code attribution config**, the `~/.claude/settings.json` attribution keys and the "## Git Commits" rule in `~/.claude/CLAUDE.md`, as kovacs now has them.
- **Deploy the Gtools Sinclair estate on gyges, visible inside the house to anyone at home.** A recreational hack-around; part of the point is to see whether a deploy like that can be done from here. Gtools is gtools-vc's pen, so bring it in.
- **Declare gyges' `[terminal] bg_color` and regenerate its ssh wrapper.** Read the live iTerm2 profile background first (rhadamanth's came from the plist: `plutil -extract "New Bookmarks" json -o - ~/Library/Preferences/com.googlecode.iterm2.plist`). Nothing checks the rendered wrapper (`~/.config/molt/iterm2-ssh-colors.sh`), so `molt upgrade` will not refresh it: it is regenerated only when `zsh_install` runs. gyges and kovacs carry the old one (exit status lost, reset to black) until then.
- **When Intent 3.2.1 or later reaches gyges, watch the first `molt upgrade` after the `brew upgrade`** (Intent 0527; the fix landed at Intent `9358663ff` and ships in 3.2.1). The 3.2.0 gate home names a keg the upgrade deletes. The intent check should report "install is gone", install should run `intent bootstrap`, and the home should then name `opt/intent/libexec`. It is the one path of ST0004 not yet seen live. No project on gyges has the pre-commit gate installed (hv: leave the hooks for now), so nothing is refused there meanwhile; `intent bootstrap` once by hand also repairs it.

### farcaster and pihole, when next reachable

- Resync their Molt and Molt-matts clones onto the purged histories, as above (board todo 6). utilz is disabled on both.

### Other

- **Confirm the Tactile install hint's URL live** (issue 0014). Plain DNS for extensions.gnome.org fails from here. On 16 Oct the name resolved on neither rhadamanth (even unsandboxed) nor kovacs, and timed out when rhadamanth asked 1.1.1.1 and 8.8.8.8 directly, though both answer github.com. Cloudflare's DNS over HTTPS answers it (CNAME `ingress.openshift.gnome.org`, 54.221.220.94, TTL 60), so something on this network's path drops DNS for that name. From another network, `curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' 'https://extensions.gnome.org/download-extension/tactile@lundal.io.shell-extension.zip?shell_version=50.1'` should answer 302 with a versioned zip. On this one it needs `--resolve extensions.gnome.org:443:<address>`, with the address looked up again over DNS over HTTPS; Claude Code's auto-mode classifier refused that to vc, so it is hv's to run. It is GNOME Shell's own installer endpoint, and it appears only in the hint printed when Tactile is missing.
- **Confirm iTerm2 keeps session GUIDs across a restart.** Per-session zsh history (Molt-matts `e96d3c5`) is keyed on them, and only iTerm2's saved window state suggests they survive. iTerm2 on rhadamanth last restarted 2026-09-22 21:40Z; whether the test was run then is not known, and a passive look at the history files (one born before that restart and written after it, within the same minute) proves nothing. Test at the next relaunch: run a distinctive command in one tab, quit and relaunch iTerm2, then press up-arrow in that tab (present) and in another (absent). If restored sessions get new GUIDs, key the files on window position instead.
- **Claude Code's iTerm2 triggers are not in the Molt dynamic profile** (still none, 23 Sep). If wanted, add them to `config/iterm2/molt-profile.json` by hand so the change shows in git.
- **Sidecars record the template path as of the last render, and nothing refreshes it.** `~/.ssh/config.molt-rendered` still names `~/Devel/prj/Molt-matts/config/ssh/config.tmpl`, the pre-move path, which no longer exists; starship's names `~/Devel/cfg/...`. The lowercase case-folding seen earlier is gone from both. Informational while the digest recomputes the path from its `source` argument.
- **Decide whether `desktop` should own more of GNOME than it does.** It manages the GTK stylesheet (3.0 and 4.0) and dock favourites; its gsettings block is still hardcoded.

Carried, not this project's to fix:

- The Gtools `README.md:15` still says both working trees live in `~/Devel/prj/`. Handed to gtools-vc on 15 Sep; Gtools' pen.
- Devbin's `README.md:60` snippet still carries both defects fixed in `5f51520`; the `dvb` body lives in three places and has diverged; `devbin doctor` reports surviving retired aliases but nothing reports a MISSING replacement. All three are devbin-vc's pen, as is issue 0203.

Carried from March, unverified from this sleeve -- confirm before acting:

- Tune iTerm2 SSH background colors after seeing them in practice
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator (still none in the liberator or `config/gnome-terminal`, 23 Sep)
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority

## Notes

Three sleeves in daily use: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels; farcaster and pihole are Pis with a small stack. `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

Commit ids from before 20 Oct may be stale. The AI-attribution purge gave new ids to Molt's commits from 4 Sep onward and to almost all of Molt-matts'. `intent/ref/2026-10-20-history-purge-commit-maps.md` translates them; `done.md`, this file and `CHANGELOG.md` were translated when it was folded.

Configs are re-rendered when a content digest of (template + `instances/<host>/vars.sh`) no longer matches the one recorded in the `.molt-rendered` sidecar. It is not an mtime comparison: git restamps files whose content never changed, and across two filesystems mtime produces false negatives, which is the silent direction.

The `backup` liberator observes; it never mounts, attaches or configures. SuperDuper owns the share mount and the sparsebundle. `backup_verify` exits 2 when the share-side checks (SMB dialect, attach budget) could not run, which is the normal state because SuperDuper mounts the share only while copying. `recentRuns` in `tiles.json` records finished runs only, so a running copy is detected separately, and cancelled or failed runs are often hv's own interruptions.
