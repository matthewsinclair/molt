# Done

## 025: The managed floor landed and holds on kovacs; estate agents named; two liberator follow-ups closed (DONE)

- **ST0006 WP06, the managed deny floor for sysadm, built, merged and verified in one morning (22 Oct).** hv's final scope, after seeing two earlier answers side by side: a sleeve takes the floor when its manifest enables a `sysadm` agent AND its `vars.sh` declares `MOLT_CLAUDE_CONFIG_DIR`, so kovacs now, rhadamanth and gyges at their moves; the contents are credentials only, `Read(~/.ssh/id_*)` and `Read(~/.aws/credentials)`, in Molt-matts `config/agents/roles/sysadm/floor.json`. cc's code (Molt merge 8656983): `molt_sudo_install` and `molt_sudo_remove` in `lib/molt.sh` write root-owned files through sudo from a user copy and never any other way; the agents liberator validates `floor.json` before rendering any home, installs its bytes as `managed-settings.d/molt-sysadm.json` with a sidecar written first, removes only a drop-in beside molt's own sidecar, names a foreign one and leaves it; `molt agent config` tags the rules managed; doctor gains check 14; an unreadable `vars.sh` fails every caller by name. dc's guide section and a role sentence true with or without the floor (Molt-matts 5220ca8). Verified on kovacs by kovacs-sysadm after hv's `molt upgrade` from a plain terminal: the drop-in in the managed layer above the fence, doctor 14/14, both files root 644. The contract passes 21/21; WP04 alone stays open.
- **Three agent kinds (hv, 22 Oct):** sleeve `<hostname>-<role>`, project `<project>-<suffix>`, estate `<estate>-estate`. The `-vc` suffix on the two Gtools estate sessions was an Intent project-agent suffix on a Gtools agent; they are sinclair-estate and geodica-estate now. The guide and the blog brief carry the third kind. The boot difference hv saw between them was a launch-directory fact: Claude Code loads `CLAUDE.md` and settings from the launch directory and its parents, never a child, and geodica's deployed `.claude/` sits in `Geodica/Consulting`, its registered content root. The Gtools side of the rename and the root move went to the estate Claudes.
- **Issues 0033 and 0034 closed, each merged with CI green:** keys and tiling write and remove their root-owned files through the new helpers rather than raw `sudo cp` and `sudo rm` (0033); the keys liberator names and stops on a failed keyd clone, build, service enable or start, or reload, where each had gone unchecked (0034).
- **A pre-commit gate lesson:** a builder's worktree gate runs `intent doctor` at the committed head, where a whiteboard view re-rendered by a verb but committed without that verb's event reads as skew. The view goes with the event, by its owner; a throwaway detached worktree and a read-only doctor find the file.
- **The reboot mid-morning cost nothing:** cc banked a WIP head first, every board was committed, and the sessions resumed from their transcripts.

## 024: Sleeve agents built and the first one moved into its home; nine issues closed on the way (DONE)

- **ST0006, sleeve agents, went from a plan to a running agent in one day (21 Oct).** hv's ask: run a local Claude on kovacs safely, with a name, a role and a fence, managed by Molt. The design: a sleeve agent is `<hostname>-<role>`, distinct from a project agent; roles `sysadm`, `ops`, `docs`; a home at `$MOLT_AGT_DIR/<name>/` holding its contract (`AGENTS.md`, from a role-independent preamble, the role's contract and a per-host overlay), its fence (`.claude/settings.json`) and its memory; Claude Code's state out of `$HOME` into `$XDG_CONFIG_HOME/claude`; a guard that refuses a launch from `$HOME`, from the agents root, below a home, or from a shell that missed the config dir.
- **WP01 (Molt 695e961):** the claude liberator honours `MOLT_CLAUDE_CONFIG_DIR`, moves `~/.claude` and `~/.claude.json` once with a backup, publishes `env.sh`, `environment.d` or a launchd plist, and writes the home guard hook into the user settings. The variable is the switch: nothing happens on a sleeve that does not declare it.
- **WP02 (bea7420):** the `[[agent]]` manifest table, `MOLT_AGT_DIR`, the agents liberator rendering homes from roles with the overlay, `molt agent list|config`, and the guard refusing a session started below a home.
- **WP03 (Molt-matts d48886f, 45e344c):** the three roles, the preamble, kovacs' sysadm overlay, `[[agent]]` entries for rhadamanth, gyges and kovacs; ops and docs also deny `~/.ssh` and `~/.aws/credentials` to sandboxed Bash through `sandbox.credentials.files`, which hv tested live on rhadamanth under Seatbelt (denied, with `ssh -G` still running; a `Read()` deny also refuses a Bash command naming the path before it runs). Closed 22 Oct with its deliverables merged.
- **WP05 (4968355):** `docs/guides/sleeve-agents.md`, every quoted item verified against the code. **WP07:** the blog brief `docs/blog/bl0001-so-you-want-to-run-a-local-agent.md`; hv writes the prose.
- **WP04 on kovacs (runbook in the WP record, final at 2915240):** phase A by kovacs-sysadm live (copies only), phase B by hv at a plain terminal, phase C by kovacs-sysadm from its new session. The move itself held first time. The lessons were in B9: a Claude started from a shell opened before the move has no config dir and rebuilds `~/.claude` as a fresh install, login included, which the guard could not see because the guard lived in the config dir the launch missed (issue 0030); and `~/.npm` is not debris but the status line's npx cache (issue 0031). c4 passes on every line; AC008 is satisfied; kovacs-sysadm runs from `~/Devel/agt/kovacs-sysadm` with its memory in the home and nothing of Claude Code's left in `$HOME`. Claude Code's auto-mode classifier stopped kovacs-sysadm's `rm -rf` twice, rightly, and hv ran the removals by hand. WP04 stays open for rhadamanth and gyges.
- **WP06 is specified and started**: hv named the floor (credentials only; sysadm sleeves only; removed elsewhere), the contract is on the thread (AC010, AC017 to AC021, AT068 to AT075), cc builds.
- **Issues closed, each merged with CI green under both bashes:** 0023 (`molt upgrade` restarts on the code it pulled), 0024 (ssh renders `~/.ssh/config` whole and refuses a static file out loud), 0025 (a `vars.sh` with an EXIT, RETURN or DEBUG trap is read to its end), 0026 (doctor's doubled prefix), 0027 (ssh refuses a static config up front), 0028 (doctor's manifest step survives a manifest with no `user_repo`), 0029 (a render over molt's own untouched file takes no backup: the sidecar records the output digest), 0030 (the home guard runs from the home's own settings too and refuses a session that missed the config dir), 0031 (a new `npm` liberator renders `~/.npmrc` with the cache under `~/.cache/npm` on every sleeve; hv: "fix it everywhere"). Filed for hv: 0032, Claude Code's sandbox cannot start on Ubuntu because `bwrap-userns-restrict` denies capabilities to bwrap's children, diagnosed read-only by kovacs-sysadm.
- **Process that held up over four Claudes in one checkout:** vc specifies, validates and merges; builders work in `Molt-wt/<branch>` worktrees; everyone commits by pathspec from main; a merge is tested in a detached scratch worktree (both bashes, shellcheck, the branch's tests red on main's code) and replayed on main with the code diff against the tested head proven empty; `intent at` rows go to-write, red, green; issues are filed and fixed as they are found. The shared checkout's live board views make `molt upgrade` refuse on rhadamanth (P4), so `molt resleeve` is the dev-day verb.
- **Not done, by ruling:** rhadamanth's and gyges' moves (hv's dates); the kovacs sandbox fix (issue 0032, hv's option); Molt from brew (coming, no thread).
- Commits: Molt `695e961`, `bea7420`, `4968355`, `da8da33`, `c295b94`, `f4a1156`, `a1ec2e1`, `032a473`, `bb083c0`, `ee3679e`, `5a21904`, `5cefa98`, `2915240`, `134cf50`, `ebe14a3` and this fold's; Molt-matts `d48886f`, `9f1fa46`, `e352b7c`, `45e344c`, `423b800`

## 023: AI attribution purged from history, utilz from a checkout or Homebrew per sleeve, and check 10's false alarm on Homebrew's Linux home (DONE)

- **The AI-attribution trailers were purged from Molt's and Molt-matts' history on hv's order** ("STRICTLY FORBIDDEN. Purge that from the git record immediately").
  - Molt-matts had 28 commits carrying `Co-Authored-By` or `Claude-Session` lines, back to 8 Mar. Molt had 36 `Claude-Session` lines, from 4-7 Sep.
  - `git filter-repo` rewrote only the messages that carried a trailer. Every commit kept its tree, author and dates, and Molt's commits before 4 Sep and its two tags kept their ids.
  - GitHub, both Dropbox mirrors, rhadamanth and kovacs are on the new histories, with the old objects gone. gyges and the Pis wait (board todos 5 and 6).
  - `intent/ref/2026-10-20-history-purge-commit-maps.md` translates old ids, and this file, `wip.md` and `CHANGELOG.md` were translated.
  - A first pass trimmed trailing newlines from every message, which gave a 9 Mar commit with no trailer a new id and moved both tags. It was caught before any push, because the tags moved.
- **kovacs's Claude Code no longer writes attribution.** It now has the attribution keys in `~/.claude/settings.json` (hv ran the merge) and the "## Git Commits" rule in `~/.claude/CLAUDE.md`, as rhadamanth does. The October trailers came from kovacs sessions.
- **`molt doctor` check 10 warned on every sleeve** (issue 0017). It counted `/home/linuxbrew`, the system account's home that holds Homebrew's Linux prefix and that the user repo's zprofile names, as another user's home. That one home is exempt; a near-miss name, and another home in the same file, are still reported.
- **ST0005: the utilz liberator takes Utilz from a checkout or from Homebrew, as each sleeve declares** (WP01 and WP02 done, all five criteria met, WP03 open for gyges).
  - kovacs-sysadm reported "utilz: repo not found" on kovacs, which hv made brew-only on 19 Oct. On rhadamanth the same check passed while Homebrew's utilz ran ahead of the checkout's links, which is the defect ST0004 fixed for intent.
  - hv ruled for a per-sleeve `source` over brew-only. Both modes now check which utilz, and which of its utilities, PATH runs. Brew mode installs by full formula name, links nothing, and leaves upgrades to `brew upgrade` rather than `molt upgrade`.
  - The Homebrew half of the check is shared with intent in `lib/molt.sh`.
  - rhadamanth (Molt-matts `e567a83`) and kovacs (`9c92ca4`, kovacs-sysadm's) are on brew. kovacs's doctor shows check 6 at 15/15.
- **Homebrew 7.0.10's trust gate, measured against an empty trust store.** An install by full name trusts the formula; a short name is refused; a plain `brew upgrade` skips an untrusted tap's formula with only a warning, and exits 0. Molt installs by full name, its check reports an installed formula Homebrew does not trust, and install trusts exactly that one.
- **critic-shell reviewed ST0005.** It found 1 critical (an assertion errexit could not see fail), 3 warnings and 8 recommendations, all answered in `092384c`. That includes one parser for `molt.toml`'s `[[liberator]]` blocks where there had been three, which gives the same, non-empty answer on all five instance manifests, on linux and macos.
- Filed: issue 0018 (the manifest's `depends` key is documented, and nothing reads it), and devbin issue 0203 (its README says the tap does not exist, and installs by a short name), committed in devbin and not pushed.
- Suite 223 -> 231, under `/bin/bash` 3.2 and Homebrew bash 5.3; CI green on every push.
- Commits: `0c9f2e5`, `fe17190`, `94d04df`, `b44d3cc`, `6ba41db`, `092384c`, `342b774` and this fold's (molt); `e567a83`, `9c92ca4` (molt-{user}); `6ba65d73` (devbin)

## 022: Doom rebuilds after an Emacs upgrade, a failed hook fails the run, and Tactile's schema stays current (DONE)

- **kovacs-sysadm found both on kovacs on 16 Oct**, after its release upgrade from Ubuntu 24.04 to 26.04.1 took Emacs from 29.3 to 30.2.
- **doom sync asked to rebuild every package, read EOF and failed, and molt still said "Sleeve ready"** (issue 0013). `editors_upgrade` threw Doom's stderr away and warned, `molt upgrade` warned again and resleeved, and `molt maintain` exited 0. molt now compares the Emacs version Doom recorded at its last sync (`$DOOMLOCALDIR/etc/sync`) with the running one and passes `--rebuild` when they differ, warning when it cannot tell. Doom's own `-!`/`--force` is no fix: it skips the rebuild along with the prompt (board watch-out 17). A failed doom command fails the editors hook, a failed hook makes `molt upgrade` and `molt maintain` name it and exit 1, and the resleeve after a failed upgrade does not call the sleeve ready. resleeve's body moved into `lib/molt.sh` as `molt_resleeve`, beside the upgrade that calls it.
- **Tactile's gsettings schema was copied into `/usr/share/glib-2.0/schemas` only when none was there** (issue 0014), so a Tactile update would never reach it, and the sudo, compile and gsettings calls were unchecked. Nothing had broken yet on kovacs (Tactile 38, GNOME Shell 50.1). Install now refreshes the copy whenever it differs, compiles the extension's schema under `--strict` first, takes out a copy the system compile rejects, and fails instead of reporting complete; check and verify report a stale copy. Refreshing needs sudo, so an unattended run without it fails the step out loud. The install hint asks extensions.gnome.org for the build that fits the running shell instead of pinning one; that URL is not yet confirmed live (wip.md).
- **kovacs-sysadm's third report, the ccstatusline link, was already fixed** by `12a613d` (15 Oct), and kovacs had the link.
- **Checked on kovacs by kovacs-sysadm:** `molt doctor` 13/13, `molt resleeve --dry-run` ok for all 14 liberators, and Doom's record and the running Emacs both read 30.2. The live `molt upgrade editors` there waits for hv.
- critic-shell's review and test-check are applied, and eight deliberate breakages each turned a test red under both interpreters. Issues 0015 and 0016 record what the review found outside the change, for hv.
- Suite 202 -> 223, under `/bin/bash` 3.2 and Homebrew bash 5.3; CI green on Ubuntu, with macOS skipped on push by design.
- Commits: `b7ea054`, `d15e178`, `3c8f6ef` and this fold's (molt)

## 021: The status line, and resleeve telling the truth about failures (DONE)

- **The claude liberator manages the Claude Code status line** (issue 0009, gtools-vc's todo 92). It links the ccstatusline layout from Molt-matts and writes only the `statusLine` key of `~/.claude/settings.json`; the file itself is never linked. Another tool had replaced rhadamanth's statusLine and molt could not put it back. `molt_report_link_faults` and `molt_link_all` replaced six copies of the link loop.
- **resleeve stopped at the first failed liberator under bash 5** (issue 0010): `((failed++))` from 0 returns 1 under `set -e`. CI's bash 3.2 carried on, so CI never saw it. resleeve now runs every liberator and exits 1 when one failed.
- **`molt_link` said "Linked:" when it had not linked** (issue 0010), and 16 liberator call sites ignored its failure, so resleeve printed "installed". critic-shell found the call sites after the first fix.
- **The iTerm2 ssh wrapper returned 0 for a failed ssh** (issue 0011), and reset a tab to black (issue 0012). It returns ssh's status and resets to the sleeve's own `[terminal] bg_color`, `15191f` on rhadamanth. hv tested xterm's OSC 111: iTerm2 ignores it after `SetColors`, so the colour has to be declared.
- Suite 189 -> 202, under `/bin/bash` 3.2 and Homebrew bash 5.3; CI green including macOS (dispatched by hand, since a push skips it).
- Commits: `12a613d`, `a6ac811`, `6e0a1ac` and the folds (molt); `f158572`, `9376363` (molt-{user})

## 020: Intent comes from Homebrew, and Molt keeps off rhadamanth's Intent (DONE)

- **gyges reported the intent liberator ok under a warning that nothing used the link** (ST0004). The link reached Intent 2.6.0, the v2 script in a frozen pre-rewrite checkout. A login shell ran Homebrew's 3.2.0 and an interactive non-login shell ran the 2.6.0. The check asked whether its `~/bin` link was sound, never which Intent anything ran, and its shadow warning went quiet in exactly the shell where v2 ran. v2.6.0 refuses a v3 project with an error and writes nothing, so nothing was damaged.
- **The intent liberator is brew-only.** It installs from `matthewsinclair/intent/intent` and fails, naming the path, when `intent` on PATH is not Homebrew's, or when the pre-commit gate's home is missing, names an install that is gone, or names another one. Install runs `intent bootstrap` only for a missing or dangling home. Gone: repo discovery, the v2 fallback, the `~/bin/intent` link, the `git pull` of the checkout, `molt git` over it, and `MOLT_INTENT_HOME`.
- **hv's rulings, 23 Sep.** gyges is the test bed for Intent from brew with no local dev tree, and Intent-from-brew problems go to intent-vc. Nothing to do with Intent on rhadamanth is to be touched, so its manifest disables the liberator, which had been running `git pull --ff-only` in the Intent dev checkout on every full `molt upgrade`. kovacs has no Intent, and hv says it will not for now.
- **gyges cleaned by gyges-infra with hv's approval.** `~/bin/intent` and the checkout were removed, and `~/.local/bin/intent` had already gone. All 189 local commits in that checkout were already upstream under rewritten hashes. Then `molt upgrade` there reported the intent liberator ok, naming Homebrew's 3.2.0, with no warnings.
- **Found on the test bed, filed by intent-vc as Intent 0527 (high, for 3.2.1).** `intent bootstrap` records the versioned keg (`Cellar/intent/3.2.0/libexec`) as the gate home, `brew upgrade` deletes that keg, and the gate then refuses every commit until bootstrap runs again. The new check reports that state and install repairs it.
- Suite 200 -> 189 (15 checkout-era tests and one `molt git` test out, 5 in), under `/bin/bash` 3.2 and Homebrew bash 5.3.
- `.claude/restart.md` is an entry point again. It had carried 27 Aug state into every wake prompt since.
- What Molt learned about Intent went to intent-vc: v2.6.0 refuses a v3 project; pre-rewrite clones cannot fast-forward; `~/.local/bin/intent` is a dev-machine convention that other machines kept stale; release and dev builds print the same version; Molt now copies the shim's gate-home resolution. intent-vc landed the 0527 fix at Intent `9358663ff` for 3.2.1 and put a supported gate-root query on its post-3.2.1 backlog.
- Retired from `wip.md` after checking the machines: the rewritable iTerm2 profile (iTerm2 on rhadamanth restarted 2026-09-22 21:40Z, after the 15 Sep fix, and the profile in git has no `Rewritable` flag), and the March item to export the iTerm2 and Terminal.app profiles (done 10 Mar, Molt-matts `ce0a168`). The March background-colour item is now a measured one.
- Commits: `4fec7a7`, `e3c3391`, `8972f27` and this fold's (molt); `710f135` (molt-{user})

## 019: Config repos moved to `~/Devel/cfg`, and two liberators that checked less than they installed (DONE)

- **Config repos live in `~/Devel/cfg`, not `~/Devel/prj`** (issue 0005). hv's call: Molt-matts, Molt-flynn and Gtools-geodica are configuration, not projects. Molt searched only `MOLT_PRJ_DIR` and `$HOME` for the user repo, so every command would have failed after the move. `MOLT_CFG_DIR` defaults to the `cfg/` sibling of `MOLT_PRJ_DIR` and is searched first; `MOLT_PRJ_DIR` stays in the list so an unmoved sleeve still resolves. `bootstrap.sh` clones the config repo there as `Molt-{user}` and `new-user` scaffolds there.
- **Moved on all three sleeves, 15 Sep.** gyges first, where its Claude auto mode refused the mv and hv ran it. Then rhadamanth, once hv stopped the Gtools CMS and Gtools.app: `~/.config/gtools/{config.yaml,env}` repointed, Intent registry roots swapped (`intent discover ~/Devel/cfg`, old roots removed by hand as there is no remove verb), and gtools-vc/cc/ic told. Then kovacs, Molt-matts only, 13/13 doctor. The mv and `molt resleeve` must run as ONE command with `MOLT_PRJ_DIR` set and molt called by absolute path, because `~/.zshenv` dangles in between.
- **`git_check` and `git_verify` tested only `~/.gitconfig`** (issue 0006). `~/.gitignore_global` was a stale regular file on rhadamanth and gyges and nothing said so until the move broke `~/.gitconfig` and install ran. One `_git_links` list now feeds check, install and verify, each link must point into the user repo, and verify fails when it cannot find the repo. Closing it surfaced a formatter/renderer clash: `.prettierignore` predated issue views, so prettier rewrote `intent/issues/0006.md` and doctor refused the commit. Issue views are now fenced; the skewed 0006 view was removed (no verb re-renders a closed issue's view; doctor is clean without it).
- **`alacritty` never flagged a template-form config** (issue 0007), found by kovacs. It passed `molt_config_stale` an absolute `.tmpl` path, which looked for `.tmpl.tmpl` and answered "not stale", so kovacs's `~/.config/alacritty/alacritty.toml` dangled from 8 Sep while resleeve said ok. Fixed, `molt_config_stale` now rejects that call shape loudly, and the liberator has its first 7 tests. Landed on kovacs the same day: resleeve re-rendered the config over the dangling link, a second run reports ok without re-rendering, and no link points into `~/Devel/prj/Molt-matts`.
- **hv's leftovers from the move, all fixed at hv's request.** The Claude allow rule for `mail-recent` now names `~/Devel/cfg/Gtools-geodica`. hv restarted the Gtools CMS and Gtools.app, and the CMS serves from `~/Devel/cfg`. The move's backups on rhadamanth are deleted after diffing each against its live file, and gyges deleted its own, plus an older one from 10 Mar, and pulled Molt-matts to `f0ae8a3`. Molt-matts stops ignoring `*.sql` globally (it un-hid nothing: every matched file is also ignored by its own repo), and Doom projectile searches `~/Devel/cfg`.
- **The pipefail question is closed by hv's ruling: convert, don't port the guard** (issue 0008). All six pipelines ending in `grep -q` now capture, then match. `molt_foreign_home_paths` could already lose (a foreign path at the top of a large file went unreported under SIGPIPE); its conversion tests for an empty capture explicitly, and the large-file test fails against the old code.
- Suite 179 -> 200, every run under both `/bin/bash` 3.2 and Homebrew bash 5.3, with negative controls against the pre-fix code for 0006, 0007 and 0008.
- Commits: `06ca019`, `5016253`, `7e8f23b`, `da345cb`, `445760d`, `e08733b`, `5032d00` (molt); `fb29758`, `f0ae8a3` (molt-{user})

## 018: Backup liberator verdicts, CI on bash 3.2, and iTerm2 profile and history (DONE)

- **`backup_verify` passed without checking anything** (issue 0001). Away from home it returned 0 before reading any SuperDuper state; with the share unmounted, mounted but not answering, or its image unreadable, it skipped the share-side checks and still printed "Verified". Local `tiles.json` checks now run everywhere. Verify exits 0 when every check ran and passed, 1 when a check failed, and 2 when nothing failed but the share-side checks could not run. `backup_check` lost the same away-from-home early return.
- **Run history was misreported** (issue 0002). An empty history was stated as "no backup exists", which a recreated job disproves, and a failed latest run hid when the last good copy was. Check and verify now share `_backup_run_assess` instead of two copies that already disagreed about cancelled runs.
- **A running copy was invisible** (issue 0003). `recentRuns` records only finished runs, so both commands reported a failed run while hv's copy was 11% done. `_backup_copying` is the one probe, also used by `backup_maintain`. A running copy is always named, and it clears a cancelled or failed latest run only when the last successful copy is within `BACKUP_MAX_AGE_DAYS`.
- `test/liberators/backup.bats`: 31 tests, the liberator's first. 17 of the first 23 fail on the pre-fix liberator. Suite 148 -> 179.
- **Molt-matts was stuck mid-rebase** after a 15 Sep pull. iTerm2 3.7.1 had rewritten `config/iterm2/molt-profile.json` on two machines within three minutes: once in its own serialisation (`2209489`), once down to a 4-key stub (`da54ef3`). Resolved by skipping the stub, whose keys were all in `2209489`. Cause: iTerm2's Claude Code onboarding offers "Mark Rewritable & Install" for dynamic profiles, which adds `"Rewritable": true` and lets iTerm2 write settings changes back through the symlink into git. hv ruled iTerm2 does not write into terminal config unannounced; the profile was restored byte-for-byte to `a92970b`, without the flag.
- Retired from vc's 8 Sep escalations: the SuperDuper schedule mismatch. rhadamanth's job runs at 03:00, inside its `03:00-05:00` window.
- **CI was red for two pushes after `ac8e1a1`** (issue 0004). GitHub's `macos-26-arm64` runner has only bash 3.2, which keeps the backslash in `${VAR:-{...\}}`, so a `backup.bats` fixture was invalid JSON there and 22 tests failed. The suite had only been run under Homebrew bash 5.3. Fixed with a plain assignment: 179/179 under bash 3.2 and 5.3 locally, and CI green with the backup tests running, not skipping, on the macOS runner.
- Retired from `wip.md`: the ST0001 AC001 revert question, overtaken on 8 Sep when ST0001 closed with AC001-AC007 all satisfied.
- **Per-session zsh history in iTerm2** (Molt-matts). Each iTerm2 session keeps its own history file under `~/.local/state/zsh/sessions`, keyed on the session GUID, so a restored window gets its own history back. New sessions start from `~/.zsh_history`, and at exit a session's commands are appended to both. Same mechanism as `/etc/zshrc_Apple_Terminal`: the shell writes to a scratch file because `fc -AI` writes only new commands when appending to the current `HISTFILE`. The shared file is append-only, because quitting iTerm2 closes every pane at once. Verified with expect-driven shells; GUID persistence across an iTerm2 restart is not yet verified.
- Commits: `ac8e1a1`, `6a5f57d`, `2ceb2ac`, `dee6510` (molt); `ffcbad5`, `e96d3c5` (molt-{user})

## 017: Honest-instrument sweep, ST0001 closed (DONE)

One defect class, 8 Sep: an instrument that reports success while the condition it names is false.

- `molt doctor` check 6 printed a tick for every ratio, so `0/16` rendered like `16/16`, and discarded the reason the check function had printed. Now warns, names the liberators and prints the reason.
- `intent_verify` passed on the mismatched link `intent_check` warns about: it asked whether the link resolved, never whether it resolved to what the liberator installs.
- The `intent` liberator found the Intent repo by probing for `bin/intent`, so Intent's v2-script deletion would have sent hv to clone a repo already on disk. It now identifies a repo by being one.
- `molt doctor` check 13: the declared font must be one fontconfig resolves. Not `fc-match`, which returns Verdana for a font that does not exist.
- `e` in Molt-matts had always discarded its filename argument: an alias appends arguments after a body ending in `&`.
- **ST0001 closed after six months**, 15/15 work packages. WP-07 was half met and was split; its VM-build half became ST0003, since fiat-closed by hv. WP-04's runbook was three months stale and was brought current.
- kovacs moved onto its own ext4 clones. Running one sleeve case-sensitive found three defects APFS had hidden: dangling links passing `[[ -L ]]` (`e8b929c`), renders compared by mtime (`687df61`), and a stack running from another machine's checkout (check 11). Keep one sleeve case-sensitive for this reason.
- **Resolved, not to be re-opened.** Font vars are wired, not deleted: `alacritty.toml` is a template fed from `vars.sh`. Fonts get a check, not an installer. gyges already had key access to rhadamanth (`4d68bbb`). gyges's branch was merged (`82432ea`). A kovacs ProxyJump is correctly deferred while kovacs is unreachable. From 4 Sep: repo directory case normalised to `Molt-{user}`; `user_repo` asserted by doctor check 4; remote naming (`local`/`upstream` vs `origin`) is not a defect; the `claude` liberator owns `~/.claude/keybindings.json`; `desktop` links gtk-3.0 and gtk-4.0; doctor check 12 warns on `core.ignorecase`; `intent_check` tells "resolves" from "resolves to what we installed".
- Commits: `06e240b`, `2fb3f02`, `b7c2e6b`, `13d2fcc` (molt)

## 016: NAS backup migration, and four silent-success bugs in the framework (DONE)

- **SuperDuper moved off hand-made `.asif` images onto its own sparsebundles.** rhadamanth's daily backup had failed every run since 4 Sep 02:59 with `resolve — missingField("disk7s1 belongs to a disk image; bind the image file instead")`, after succeeding for two weeks. The job's destination was anchored to the APFS volume _inside_ a hand-created image; that binding is enriched in the daemon's memory and survives only until the image detaches. A share drop at 22:12 on 3 Sep detached it, and `enrichBinding` could never rebuild it: `attach-heal: ... appeared but enrichment still failed — leaving unenriched`. The fix is to select the SMB **share** as the destination and take SuperDuper's "Use an Image..." button, which creates and owns `<host>.sparsebundle` at the share root with a `.sd4claim` lock. Both Macs migrated. Written up in full at `/Volumes/backup/notes/supersuper4-synology-nas-backup-post-mortem.md`.
- **The `backup` liberator was rewritten around that.** It no longer attaches, creates or touches the image -- SuperDuper does all of it, and anything that competes for the image can permanently break the job's binding. `maintain` no longer force-detaches, which could have pulled the destination out from under a running copy. `MOLT_BACKUP_VOLUME` is gone; `MOLT_BACKUP_IMAGE` now names the sparsebundle. A missing image is a warning, not an error -- it belongs to SuperDuper and legitimately does not exist until a job has been set up.
- **The mount agent had never once worked: 2,015 failures out of 2,015 since 20 Aug, a 100% failure rate, unnoticed** because backups still ran whenever the image happened to be attached by other means. Two causes, both silent. `/Volumes` is `root:wheel drwxr-xr-x`, so the script's `mkdir -p` could never succeed as a normal user; it failed behind `2>/dev/null` and `mount_smbfs` then died on the missing mount point. And a LaunchAgent running a plain script gets no TCC grant for network volumes, so `open`/`readdir` are denied while `stat` still passes -- a script guarding with `test -e` clears its own precondition and then fails at the real work. Now mounts via NetAuth, which creates the mount point as root and takes the password from the keychain, needs no Full Disk Access, and logs the tool's real stderr with the password scrubbed. Log trimmed to 30 days, and only rewritten when there is something to drop.
- **`molt_config_stale`** added, then rebuilt. molt only re-renders when a liberator's check fails, so a template change never propagated: the check passed, install was skipped, and the sleeve ran the old rendered file while reporting ok. gyges did exactly that for a morning. First implementation compared mtimes; gyges and kovacs independently showed mtime cannot answer the question -- git restamps files whose content never changed, a touched-but-identical template reads stale, and across two filesystems a FUSE mount truncating to whole seconds against an ext4 file carrying nanoseconds in the same second reports "not newer", a **false negative**, silently skipping a render that was needed. Now digests the template **and** `instances/<host>/vars.sh`, recorded in the `.molt-rendered` sidecar. vars.sh matters because `molt_render` substitutes it, so a vars-only edit changes the output while marking nothing stale -- and it is by definition the per-machine file, the least visible edit there is. Fails closed. Nine cases verified.
- **`molt_render` now honours `@@MOLT:BEGIN@@`.** The templates told users "add your own entries ABOVE this line" and rendering replaced the whole file anyway. Latent for as long as templates never changed; `molt_config_stale` made renders routine and turned it live, wiping a `Host *` block out of rhadamanth's `~/.ssh/config` during testing.
- **`molt doctor` check 11: the stack must be on local storage.** kovacs reported 10/10 green while running entirely out of rhadamanth's working tree -- `~/Devel/prj` was a symlink to `/media/psf/Home/Devel/prj`, same device and inode, one index and one HEAD shared between two machines. Check 10 could not see it: it greps config for foreign home paths, and the coupling was structural, not textual. Rejects `fuse*`, `nfs*`, `smb*`, `cifs`, `9p`, `virtiofs` and friends; validated on kovacs, the only sleeve that can currently fail it.
- **`molt upgrade` warns about unpushed commits and untracked files.** The clean check refused on uncommitted changes but said nothing about commits never pushed -- and that is the damaging case, because `pull --ff-only` cannot fast-forward past them, is skipped with a soft warning, and every other sleeve upgrades to a tree without the fixes while reporting success.
- **`doom upgrade` short-circuits before the package sync** when Doom itself is current, so packages orphaned by a failed run are never retried and `molt maintain` reports success regardless. Found on kovacs, stuck at 181/191 after a straight.el fetch died. `editors_maintain` now runs `doom sync -u` unconditionally.
- **Emacs rebuilt on both Macs** after `brew upgrade` moved tree-sitter 0.26 -> 0.27; emacs-plus hard-links keg-only libs by exact soname. gyges also dropped `--with-imagemagick`, retiring that recurrence at source, and `editors_check` now warns on any machine still carrying the linkage.
- `.gitignore`'s `Icon\r` matched a file literally named `Iconr`, never the Finder stub -- the source of the perpetual "1 untracked file" warning. rhadamanth's `lan-hosts.conf` had drifted well behind its live `~/.ssh/config`, missing the bare aliases and a `kovacs` block entirely; kovacs was about to clone an ssh config with no `kovacs` entry.
- rhadamanth's VS Code was **1.111.0 from March**, neither brew-managed nor self-updating; brought under the cask at 1.136.1 to match gyges.
- Commits: `5f01655`, `8bc901e`, `a9e8813`, `687df61` (molt); `5d8537e`, `c495df5`, `0c628d3`, `fed1c0a`, `72a8b42`, `b45bd22` (molt-{user})

## 015: `dvb` shell function, whiteboard roster, snapshot re-cut (DONE)

- **`dvb` shell function** installed in molt-matts: new autoload file `config/zsh/functions/dvb`, registered on the `autoload -Uz` line at `config/zsh/zshrc:11`. Walks up from `$PWD` to the nearest `bin/devbin` and runs it, passing the child's exit code through.
  - Devbin's `9ce1c88` retired the per-project launcher symlinks and offered `dvb` as the replacement, but shipped it only as a README snippet. Measured: zero references in devbin's `bin/ lib/ tests/ docs/`, two in prose, and zero hits across all four of hv's zsh init files. The shortcut every devbin project assumed had never existed anywhere.
  - Lands in molt-matts rather than the framework: devbin's `usage-rules.md:66` says shell config and never a project, and the framework would otherwise hard-code one project's launcher into every sleeve.
  - **Two defects fixed before landing**, both verified under `zsh -f`: `${^tried}` collapsed the candidate list onto one line (needs `[@]`; byte-identical to the correct form at depth 1, which is why a `/tmp` negative control could not catch it); and `-x` with no `-f` arm let a mode-644 `bin/devbin` be stepped over so the walk ran a PARENT project's launcher and returned rc=0 -- now stops at rc=126 with the path named.
  - Verified through the real config in a fresh shell: rc=0 in a devbin project, rc=127 with a multi-line candidate list from `$HOME`, rc=126 non-executable, rc=2 passed through. hv confirmed live in their own shell.
- **Whiteboard escalation surface** stood up: provisioned the `hv` node, seeded inboxes both directions, and wrote `intent/whiteboard/README.md` naming `vc` as the node obliged to read `hv/inbox.*` and surface it to the human. Before this the board had one node, no roster, and no reader -- a write surface with no named reader is a queue, not a channel.
- **Snapshots re-cut off March**: `intent/wip.md` and `intent/restart.md` claimed 83 tests / 19 liberators / v0.1.0 and were five months stale. Measured 2026-08-27: 112 tests, ShellCheck clean over 27 scripts, 22 liberators, VERSION 0.1.1, `intent doctor` 0 findings. March's gyges/kovacs items carried forward marked unverifiable from this sleeve rather than silently re-asserted.
- Fixed the unsubstituted `{user}` author placeholder in wip.md's verblock that `fc20931` missed.
- ST0001 checked and found correct: WP-04 and WP-07 genuinely Not Started; the earlier "Phase 1-6 COMPLETE" was a different axis (phases map to focus items, not WP numbers).
- Commits: `131642d` (molt); `5f51520` (molt-{user})

## 014: Intent v3 port (DONE)

- Migrated the project to the Intent v3 canonical store
- Substituted the author placeholder ahead of the migration
- Declared the open set and dehydrated the closed threads' flat views, by hand, ahead of `organize --default --force`
- Carried the v2 buckets' prose into the store per file, byte-verified, and pruned what was proven carried
- Fenced the renderer-owned views from prettier in `.prettierignore` -- generated views have one writer and it is the renderer. Established the owned set by perturbation rather than by family resemblance: `info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are restored by the renderer; `design.md`, `impl.md`, `tasks.md`, `claude/wip.md`, `intent/wip.md` and `intent/done.md` keep the perturbation and are authored.
- ST0002 dated and closed; `intent doctor` 0 findings
- Commits: `fc20931`, `84726b0`, `4212bf6`, `e94ed2b`, `fb053ab`, `555dd08`

## 013: Docs, CI/CD, versioning, and iTerm2 SSH colors (DONE)

- VERSION file as single source of truth; `constants.sh` reads it with fallback
- CHANGELOG.md in Keep a Changelog format (Unreleased + 0.1.0 sections)
- GitHub Actions CI/CD:
  - `tests.yml`: bats on Linux + macOS, ShellCheck (non-blocking), test summary
  - `pr-checks.yml`: documentation checks, commit message length, PR size warnings
  - `.github/workflows/README.md`: workflow documentation
  - Fixed CI: added git identity config for test runners (git.bats needs it)
- README.md: CI badge, `upgrade --self`, `maintain`, targeted variants, lifecycle hooks, 4 new liberators (brew, intent, pplr, web), three sleeves
- getting-started.md: self-update, maintain, recommended workflow section
- iTerm2 SSH background color wrapper in molt-{user}:
  - `config/zsh/iterm2-ssh-colors.sh`: tints background per host on SSH
  - gyges=navy, kovacs=forest, shrike=burgundy, yggdrasil=olive
  - zshrc sources it (only on iTerm2)
- Tagged v0.1.0
- 83 tests passing, 19 liberators
- Commits: `c38a284`, `37ff0bc` (molt); `ce00951` (molt-{user})

## 012: molt upgrade --self — self-update before upgrade (DONE)

- Extracted `_upgrade_pull_repos()` from inline pull logic in `cmd_upgrade()`
  - Checks framework + config repos for uncommitted changes
  - Pulls both repos via `git pull --ff-only`
  - Re-sources constants, reports version changes
- Added `--self` flag to `cmd_upgrade()` argument parser
  - When set: calls `_upgrade_pull_repos()` and exits (no hooks, no resleeve)
  - Enables composable workflow: `molt upgrade --self && molt upgrade && molt maintain`
- Full upgrade path now calls `_upgrade_pull_repos()` instead of inline code (DRY)
- Updated help text in `bin/molt`
- 83 tests passing, 19 liberators
- Commit: `dca5bb8` — pushed to upstream + local

## 011: Doom migration, upgrade scripts, hostname in prompt (DONE)

- Added `molt maintain` command -- system maintenance separate from config sync
  - `molt maintain` runs all `_maintain()` hooks on enabled liberators
  - `molt maintain brew` -- targeted maintenance for specific liberators
  - `molt maintain --dry-run` -- preview what would happen
- New brew liberator (macOS) -- brew update/upgrade/cleanup/doctor + npm global update
- Added `editors_maintain()` -- runs `doom upgrade --force` (framework upgrade)
- Starship prompt now shows `{user}@hostname` with per-host colors
  - Converted starship.toml to .tmpl template with `MOLT_PROMPT_HOST_COLOR`
  - rhadamanth: purple (#9A348E), gyges: teal (#2E86AB), kovacs: green (#44803F)
- Fixed `molt_render()` to only substitute `MOLT_*` variables via envsubst filter
- Fixed `zsh_check()` to detect missing/dangling starship config
- Doom migration on rhadamanth: removed legacy `~/.emacs.d` and stale `~/.doom.d`
- Removed `share_history` from zshrc (each terminal now has own history)
- 83 tests passing (19 liberators)

## 010: molt git + centralised git operations (DONE)

- Added `molt git <cmd>` -- runs git across framework, config, and liberator repos
- Per-liberator convention functions: `{name}_repo()`, `{name}_repo_git_commands()`
- Auto-detect remote for pull/fetch/push
- 77 tests passing (28 new in git.bats)

## 009: gyges resleeve + symbolic directory vocabulary (DONE)

## 008: Cmd key proper fix + per-app keybindings (DONE)

## 007: Phase 5 -- Upgrade, Emacs Keys, Tiling, VS Code (DONE)

## 006: Rhadamanth resleeve + chezmoi migration (DONE)

## 005: Make Molt Sleeveable (DONE)

## 004: Split terminal liberator into per-emulator liberators (DONE)

## 003: Bats test suite and CLI commands (DONE)

## 002: MOLT framework scaffolding (WP-05, DONE)
