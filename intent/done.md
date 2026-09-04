# Done

## 016: NAS backup migration, and four silent-success bugs in the framework (DONE)

- **SuperDuper moved off hand-made `.asif` images onto its own sparsebundles.** rhadamanth's daily backup had failed every run since 4 Sep 02:59 with `resolve — missingField("disk7s1 belongs to a disk image; bind the image file instead")`, after succeeding for two weeks. The job's destination was anchored to the APFS volume _inside_ a hand-created image; that binding is enriched in the daemon's memory and survives only until the image detaches. A share drop at 22:12 on 3 Sep detached it, and `enrichBinding` could never rebuild it: `attach-heal: ... appeared but enrichment still failed — leaving unenriched`. The fix is to select the SMB **share** as the destination and take SuperDuper's "Use an Image..." button, which creates and owns `<host>.sparsebundle` at the share root with a `.sd4claim` lock. Both Macs migrated. Written up in full at `/Volumes/backup/_notes/supersuper4-synology-nas-backup-post-mortem.md`.
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
- Commits: `1c980c6`, `53b75fc`, `7d1508b`, `9f28dce` (molt); `0e57e83`, `4a64ca1`, `79299dc`, `ca77942`, `cd319fd`, `7ebf26f` (molt-{user})

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
- Commits: `131642d` (molt); `a4e6cb2` (molt-{user})

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
- Commits: `c38a284`, `37ff0bc` (molt); `57e00c5` (molt-{user})

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
