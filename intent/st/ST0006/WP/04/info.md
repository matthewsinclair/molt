---
wp_id: WP-04
title: Move kovacs-sysadm into its home; then rhadamanth, then gyges
scope: S
status: Not Started
---

# WP-04: Move kovacs-sysadm into its home; then rhadamanth, then gyges

## Objective

Move each sleeve, kovacs first, then rhadamanth, then gyges on hv's date, so that Claude Code's state sits in the sleeve's declared config dir with none of it left in `$HOME`, and its sysadm agent runs from its own home with its memory there, following the runbook below, which hv executes at the keyboard.

## How this runs

Owner: kovacs-sysadm plans and verifies kovacs; hv executes each move at the keyboard; molt-vc reviews. molt-ac wrote these steps down on 21 Oct from three sources: kovacs-sysadm's plan, whose phase A and C specifics vc relayed; the merged claude liberator, `liberators/claude.sh` and `templates/claude/` (main at c815d23); and dc's guide, `docs/guides/sleeve-agents.md`, on branch `st0006-wp05` until it merges. The guide explains the mechanism, and this runbook names its sections rather than repeating them. vc checked every quoted molt line against the code.

No agent can move its own state: `mv ~/.claude` under a running session moves its transcript, credentials and state out from under it. So each sleeve moves in three phases. In A, the sleeve's agent, still live, copies what it keeps into its new home. In B, hv, at a plain terminal with no Claude running, declares the config dir and runs the move. In C, the agent, in a new session started in its home, verifies and cleans up. Until C3, the first deletion, everything can be rolled back from the backup the move takes (see Rollback).

kovacs-sysadm's plan and verify script start on kovacs at `~/work/ST0006-WP04-move-plan.md` and `~/work/verify-wp04.sh`, and A2 copies them into the home. Their dry run on 21 Oct gave AC008 FAIL, as expected before the move, with `molt doctor` already green. H4, H5 and H6 below are the plan's labels.

How molt's output is quoted here: molt prefixes its lines `Zen:`, its warnings `Zen [warning]:` and its errors `Zen [error]:`. `<stamp>` is `YYYYmmddHHMMSS` in local time, the declared config dir is `~/.config/claude`, and `/home/matts` is kovacs' home directory. In kovacs' steps, `h` is kovacs-sysadm's home: `h=~/Devel/agt/kovacs-sysadm`.

## Before any sleeve

**P1. The code is merged and pushed.** WP02 in Molt: the agents liberator, `molt agent list` and `molt agent config`, and the guard's refusal below a home (AC014). WP03 in Molt-matts: the roles, kovacs' sysadm overlay and the `[[agent]]` entries (branch `st0006-wp03`, at 769c2e6 when this was written). The `[[agent]]` entries reach a sleeve only once WP02's parser is on it.

**P2. Intent follows the move.** From 3.2.4 (issue 0604), Intent reads `CLAUDE_CONFIG_DIR`: `intent claude skills` and `subagents`, the prompt gate and `/in-session` look where it points, so the skills under `~/.claude/skills/` move with the state and are found there. kovacs runs Intent 3.2.4 from Homebrew. The move does not touch Intent itself, which on rhadamanth is off limits.

**P3. The time is hv's.** hv picks when each sleeve moves, once vc has reviewed this runbook.

**P4. A dirty checkout stops `molt upgrade`.** Every `molt upgrade` in this runbook, `--self` included, first checks the sleeve's Molt and Molt-matts checkouts, and refuses while either has staged or unstaged changes to tracked files: `Zen [error]: Framework repo has uncommitted changes. Commit or stash before upgrading.`, or the same with `User config`. Nothing has run: commit or stash, then run the step again. Untracked files and unpushed commits only warn.

**P5. After a pull that changes Molt's code, upgrade in a fresh command.** `molt` sources its library when it starts, and an upgrade that pulls re-sources only its constants, so the liberators it has just pulled can call library functions the running process never loaded (issue 0023). The first `molt upgrade` after pulling WP02 ends `Liberator failed: claude`, `Liberator failed: agents` and `Zen [error]: 2 liberator(s) failed. Review errors above.`, and renders no home; a second run works. So pull with `molt upgrade --self`, then run `molt upgrade` as a second command. B2 then B5 in one sitting already does this.

## kovacs

### Phase A: kovacs-sysadm, live, copies only

Nothing in A declares the variable or touches `~/.claude`, so kovacs-sysadm's session stays whole. kovacs-sysadm runs its plan's phase A; these are its steps.

**A1. Render the homes.** kovacs-sysadm or hv runs, on kovacs, as two commands (P5):

```bash
molt upgrade --self
molt upgrade
```

With `MOLT_CLAUDE_CONFIG_DIR` not declared, the claude liberator moves nothing, and the agents liberator renders `~/Devel/agt/kovacs-sysadm`, `kovacs-ops` and `kovacs-docs`. The claude liberator also links the user-scope `CLAUDE.md` and `AGENTS.md` from Molt-matts' `config/claude/` (660a118, which kovacs has not pulled yet), backing up kovacs' own `~/.claude/CLAUDE.md` as `.molt-backup.<stamp>`, so a backup line in this run's output is expected. The run should end:

```
Zen: Sleeve ready. Welcome back.
```

Then check the home:

```bash
h=~/Devel/agt/kovacs-sysadm
molt agent list
ls -d "$h/AGENTS.md" "$h/CLAUDE.md" "$h/.claude/settings.json" "$h/memory" "$h/work"
jq -r .autoMemoryDirectory "$h/.claude/settings.json"
```

`molt agent list` shows kovacs-sysadm with STATE `current` and HOME `~/Devel/agt/kovacs-sysadm` (guide: "Listing and inspecting agents"); `ls` finds all five; `jq` prints `/home/matts/Devel/agt/kovacs-sysadm/memory`.

If it refuses, a dirty checkout is P4's case, and two `Liberator failed` lines with no home rendered are P5's: run `molt upgrade` again. An `agents:` report is a row of the guide's "What molt doctor reports" and is WP02's or WP03's to fix: stop and tell vc.

**A2. Copy into the home**, leaving every original in place until C3. kovacs-sysadm's commands, verbatim:

```bash
cp -a ~/.claude/projects/-home-matts/memory/. "$h/memory/"
rsync -a --exclude=/tmp/ ~/work/ "$h/work/"
cp -a ~/prov "$h/work/prov"
mkdir -p "$h/work/archive/projects"
cp -a ~/.claude/projects/-home-matts-work-o7h-proj ~/.claude/projects/-home-matts-setup "$h/work/archive/projects/"
```

So the memory lands in `$h/memory/`, which the home's settings name as `autoMemoryDirectory`. `~/work`'s contents land in `$h/work/`: the FOLD note, `intent-vc/`, `devbin-vc/`, the empty `utilz-vc/`, `order2.sh`, `order2.log`, and the plan and verify script, at `$h/work/ST0006-WP04-move-plan.md` and `$h/work/verify-wp04.sh`. `intent-vc/` and `devbin-vc/` are not checkouts: they hold order scripts, logs and `.rc` files from 14-17 Oct. `~/prov` lands in `$h/work/prov/`, and the two slugs, `-home-matts-work-o7h-proj` (three transcripts and its memory) and `-home-matts-setup` (one `MEMORY.md` from 2026-03-10, stale Phase 1 notes, whose two live facts Molt-matts' user-scope `AGENTS.md` already carries), under `$h/work/archive/projects/`. `~/work/tmp/` is left out: it holds hv's `doom-rebuild.log`, which hv does not need kept, so it goes with `~/work` at C3.

**A3. Point the memory at the home.** Two lines in `$h/memory/kovacs-sysadm-role.md` name `~/work`, and they are the only ones in the memory; find them by their text, since line numbers drift if the memory changes before A2. In the line reading "Read ~/work/FOLD-kovacs-sysadm.md first", the path becomes `$h/work/FOLD-kovacs-sysadm.md`. The bullet quoting the allow rule hv dropped is reworded. Left alone, the verify script fails with "memory still names ~/work".

**A4. Compare each copy with its source** before folding:

```bash
diff -r ~/.claude/projects/-home-matts/memory "$h/memory"
diff -r ~/work "$h/work"
diff -r ~/prov "$h/work/prov"
diff -r ~/.claude/projects/-home-matts-work-o7h-proj "$h/work/archive/projects/-home-matts-work-o7h-proj"
diff -r ~/.claude/projects/-home-matts-setup "$h/work/archive/projects/-home-matts-setup"
```

The only differences expected are A3's two lines, `tmp` only in `~/work`, and `prov` and `archive` only in `$h/work`, the other copies.

**A5. Fold and quit.** kovacs-sysadm's fold writes `$h/work/FOLD-kovacs-sysadm.md`; the originals in `~/work` are not edited after A2. Then it quits. From here no Claude Code runs on kovacs until B9.

### Phase B: hv, at a plain terminal, with no Claude running

**B1. Declare the config dir.** In Molt-matts on main, add to `instances/kovacs/vars.sh`:

```bash
export MOLT_CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
```

Commit, ending the message `(C) hello@matthewsinclair.com`, and push. `XDG_CONFIG_HOME` is unset on kovacs, so the value is `/home/matts/.config/claude`; B3 shows what molt reads. This arms the move: the next `molt upgrade` or `molt resleeve` on kovacs runs it.

**B2. Pull on kovacs**, without resleeving (P4 applies):

```bash
molt upgrade --self
```

**B3. Check the declaration arrived:**

```bash
molt doctor
```

Its enabled-liberators step must report the pending move. Doctor puts the liberator's name before each report, so `claude:` appears twice:

```
         not installed: claude
         claude: Zen: claude: Claude Code's state is still in ~/.claude and ~/.claude.json, and this sleeve's config dir is ~/.config/claude: quit every Claude Code, then run molt resleeve to move it
```

`not installed` may name other liberators as well. Anything else in claude's report means stop; nothing has changed yet:

- a line naming `MOLT_CLAUDE_CONFIG_DIR`, eg `MOLT_CLAUDE_CONFIG_DIR is not a canonical path, with no trailing slash, // or . or .. component: <path>`: fix B1's line, push, and repeat from B2;
- `~/.claude and ~/.claude.json are present while the config dir is ~/.config/claude: a launch path missed CLAUDE_CONFIG_DIR, or a move did not finish`: `~/.config/claude` already holds something, which the move will not merge with; tell vc and kovacs-sysadm;
- no claude report at all: the declaration did not arrive; check that B2 pulled Molt-matts.

**B4. Quit every Claude Code on kovacs**: every terminal session, kovacs-sysadm's included, and any started from the GUI. The move checks for itself and names any it finds. To look first:

```bash
pgrep -fa '^([^ ]*/)?claude( |$)|@anthropic-ai/claude-code'
```

On a Mac the same pattern goes to `pgrep -afl`, since macOS's `pgrep` leaves out its own ancestors without `-a`.

**B5. Run the move:**

```bash
molt upgrade
```

Claude's part of the resleeve prints these lines in this order, among molt's other lines:

```
Zen: claude: Claude Code's state is still in ~/.claude and ~/.claude.json, and this sleeve's config dir is ~/.config/claude: quit every Claude Code, then run molt resleeve to move it
Zen: Running liberator: claude (install)
Zen: claude: moved Claude Code's state into ~/.config/claude; the copies taken first are in ~/.config/claude.molt-backup.<stamp>
Zen [warning]: claude: CLAUDE_CONFIG_DIR is not ~/.config/claude in this shell. Start Claude Code only from a new shell that sources ~/.config/molt/env.sh, and log out and in for apps started from the GUI
Zen [warning]: Backing up existing file: /home/matts/.config/claude/settings.json -> /home/matts/.config/claude/settings.json.molt-backup.<stamp>
Zen: claude: home-launch hook written into ~/.config/claude/settings.json
Zen: Liberator complete: claude
  claude: ✓ installed
```

The run should end `Zen: Sleeve ready. Welcome back.` The first line is the check reporting the pending move, just before the install carries it out. The first warning is expected, because this shell started before `env.sh` existed. A Claude Code started from a shell that predates this run has no `CLAUDE_CONFIG_DIR` and rebuilds `~/.claude` in `$HOME` as a fresh install, login included; nothing moved is harmed, but the stray copies have to be removed by hand before C1 passes. If the statusLine changed too, a second backup line and `Zen: claude: statusLine written into ~/.config/claude/settings.json` come before the hook's. Note the backup's path: the rollback starts from it.

If it refuses, the refusal ends with a `Zen [error]: claude: CLAUDE_CONFIG_DIR was not published` line and `Zen [error]: Liberator failed: claude`, and the run ends `Zen [error]: 1 liberator(s) failed. Review errors above.` The other liberators still run, the agent homes among them. By the first error line:

- `Zen [error]: claude: Claude Code is running, and a live session cannot survive its own state moving:`, then one `Zen [error]:   <pid> <command>` line per process, then `Zen [error]: claude: quit every Claude Code on this machine, then run molt resleeve from a plain terminal`: nothing moved. Quit each process named and run B5 again; `molt resleeve`, which the line names, runs the same move.
- `Zen [error]: claude: pgrep could not list processes, so whether Claude Code is running is unknown`: nothing moved. Run B5 again, and if it repeats, stop and tell vc.
- a line containing `already holds`, `is a symlink to`, `both exist`, `holds nothing, and CLAUDE_CONFIG_DIR named` or `is not a`, with the not-published line ending `and nothing else was changed`: nothing moved. Stop and tell vc and kovacs-sysadm, and change nothing by hand until they have looked; the guide's "What the move does, and when it refuses" says what each means.
- a line naming the copies, `the copies are in ~/.config/claude.molt-backup.<stamp>`, with the not-published line ending `no env.sh or GUI file was written`: the move failed after the copying began. If the line says `nothing was moved`, the state is still in `$HOME`: deal with the cause it names, then run B5 again. If it says the state `is split`, start no Claude: either move `~/.claude.json` to `~/.config/claude/.claude.json` by hand, as the line says, or roll back. Tell vc either way.
- P4's dirty-checkout line, with no claude line after it: nothing ran, and P4 says what to do.

**B6. Check from a new shell.** Open a new terminal:

```bash
echo "$CLAUDE_CONFIG_DIR"
ls -d ~/.claude ~/.claude.json
ls -A ~/.config/claude.molt-backup.<stamp>
```

The first prints `/home/matts/.config/claude`; the second finds neither; the third lists `.claude` and `.claude.json`, the copies a rollback needs.

**B7. Log out of GNOME and back in**, so every GUI and terminal child gets the variable from `~/.config/environment.d/claude.conf` (plan H6). Molt does not call `systemctl`; the file takes effect at login.

**B8. Check the sleeve:**

```bash
molt doctor
```

The enabled-liberators step should name no claude report. A `claude:` line there is a row of the guide's "What molt doctor reports", which says what to do.

**B9. Launch kovacs-sysadm from its home**, by name, so peers and `ListAgents` see it. In the B6 terminal, or any shell opened after B7, never one opened before B5:

```bash
echo "$CLAUDE_CONFIG_DIR"
```

It must print `/home/matts/.config/claude`; if it prints nothing, this shell predates the move: close it and open another. Then:

```bash
cd ~/Devel/agt/kovacs-sysadm && claude --name kovacs-sysadm
```

Accept the workspace trust dialog: the home's allow rules, its hooks and its `autoMemoryDirectory` wait for it (guide: "Starting an agent"). If Claude Code asks you to log in, log in. The first prompt passes the home-launch guard, because the session started in a home.

### Phase C: kovacs-sysadm, in its new session

**C1. Verify.** kovacs-sysadm runs, from its home:

```bash
work/verify-wp04.sh c1
```

AC008 should now pass: kovacs-sysadm runs from `~/Devel/agt/kovacs-sysadm` with its memory in the home, and `~/.claude` and `~/.claude.json` are gone from `$HOME`. At `c1` the script reports C3's items as INFO; it reads `AGENT` from the environment, defaulting to kovacs-sysadm. Then the session states its role memory without reading a file: the proof that `autoMemoryDirectory` and the trust dialog took effect, not only that the files exist. The new session has a new session id, so its bridge address has changed: kovacs-sysadm sends the new one to molt-vc, intent-vc and devbin-vc. If anything fails, stop here, while the rollback is still whole.

**C2. hv's word.** kovacs-sysadm removes nothing until hv says so. From C3 on, a rollback still puts Claude Code's state back from the backup, but `~/work` and `~/prov` come back only from their copies in the home.

**C3. Remove, on hv's word:**

- `~/work` and `~/prov`, both copied into the home in A2; `~/work/tmp/doom-rebuild.log`, which A2 left out, goes with them (hv: not needed);
- the whole `~/.config/claude/projects/-home-matts` slug, kovacs-sysadm's old transcripts and its `memory/`, a stale second copy of the home's memory after A2 (hv: remove the whole folder);
- the orphan slugs A2 archived, `-home-matts-work-o7h-proj` and `-home-matts-setup` (per kovacs-sysadm's plan, relayed by vc), from `~/.config/claude/projects/`, where the move put them;
- the two user-scope allow rules hv dropped, `Bash(bash /home/matts/work/intent-vc/*)` and `Bash(bash /home/matts/work/devbin-vc/*)` (verbatim from kovacs-sysadm, relayed by vc), from `~/.config/claude/settings.json` (plan H4); both point into the `~/work` this step removes;
- the npm-era leftovers `~/.cache/claude-cli-nodejs` and `~/.npm` (hv: kill).

The user-scope `CLAUDE.md` and `AGENTS.md` in `~/.config/claude` are by now links into Molt-matts' `config/claude/` (plan H5) and need nothing.

**C4. Verify again:** `work/verify-wp04.sh c4`, which requires C3's items gone, then `molt doctor`, which should name no claude or agents report.

**C5. Fold.** kovacs-sysadm folds.

Left alone throughout: `~/tmp`, which is root-owned and holds hv's handover note; and the native installer's own paths, `~/.local/bin/claude`, `~/.local/share/claude`, `~/.local/state/claude` and `~/.cache/claude`, which `CLAUDE_CONFIG_DIR` does not move and which are not clutter. Molt never removes the backup.

## Rollback

From the backup the move took, for anything before C3, or for a move that stopped part way. Quit every Claude first, as in B4.

**R1. Disarm.** Take the `MOLT_CLAUDE_CONFIG_DIR` line out of `instances/<host>/vars.sh`, commit and push, then on the sleeve run `molt upgrade --self`. While the line stands, the next `molt upgrade` tries the move again.

**R2. Unpublish.** Once a sleeve declares nothing, molt leaves these files as they are, and `env.sh` would go on exporting the variable to every zsh. On kovacs:

```bash
rm ~/.config/molt/env.sh ~/.config/molt/env.sh.molt-rendered
rm ~/.config/molt/claude-home-guard.sh ~/.config/molt/claude-home-guard.sh.molt-rendered
rm ~/.config/environment.d/claude.conf ~/.config/environment.d/claude.conf.molt-rendered
```

On a Mac, `~/Library/LaunchAgents/com.molt.claude-config-dir.plist` and its `.molt-rendered` take the place of the `environment.d` pair.

**R3. Put the state back** from the backup B5 named. Set the moved dir aside rather than deleting it, since it holds whatever ran after the move:

```bash
b=~/.config/claude.molt-backup.<stamp>
mv ~/.config/claude ~/.config/claude.rolled-back
cp -a --reflink=auto "$b/.claude" "$b/.claude.json" ~/
```

On a Mac the copy is `cp -cRp "$b/.claude" "$b/.claude.json" ~/`, an APFS clone. A move that stopped part way may have left `~/.claude` or `~/.claude.json` in `$HOME`: set it aside the same way before the copy. The backup's `settings.json` predates the hook, so the restored user settings carry none.

**R4. Log out and back in**, so no GUI app keeps the variable. Then, in a new shell, `echo "${CLAUDE_CONFIG_DIR-unset}"` prints `unset`.

**R5. Check and report.** `molt doctor` should name no claude report about a config dir, since the sleeve declares none. Tell vc. The set-aside dir stays until hv decides what becomes of it. The home and the copies in it stay too, and `molt agent list` still shows kovacs-sysadm `current`, with a home nobody launches from.

## rhadamanth

After kovacs has passed C4, the same three phases, with these differences:

- A: the first upgrade after WP02 and WP03 is two commands, as in A1 (P5), and renders `~/Devel/agt/rhadamanth-sysadm`, `rhadamanth-ops` and `rhadamanth-docs`. Then hv copies the memory of the sessions launched in `$HOME`, which are sysadm memories, into rhadamanth-sysadm's home, and confirms the destination: `cp -Rp ~/.claude/projects/-Users-matts/memory/. ~/Devel/agt/rhadamanth-sysadm/memory/`. vc's inventory on 21 Oct found `MEMORY.md` and four notes there (doom-emacs-version-profile-miss, emacs-plus31-dylib-crash, launchd-agents-tcc-network-volumes, nas-smb-share-wedges-emfile), so `ls ~/Devel/agt/rhadamanth-sysadm/memory/` should list those. The slug's one session transcript stays where it is, and moves with the state.
- B1: the line goes in `instances/rhadamanth/vars.sh`, with the same value, which here is `/Users/matts/.config/claude`.
- B2: skip it when B1's commit is made in rhadamanth's own Molt-matts checkout, the one molt reads. B5: P4's refusal is the likely one here, because the shared Molt checkout usually has uncommitted board files. Every session's fold commits its own board before B4, so that `git status` in both checkouts shows no modified or staged file when B5 runs.
- B4 quits every Claude Code on the machine, which on rhadamanth is every session hv runs: molt-vc, molt-cc, molt-dc and molt-ac, and every other project's, such as geodica-vc. Each folds first. Quit Chrome as well: while it runs with the extension, its native host (`~/.local/bin/claude --chrome-native-host`) is a `claude` process, and B5 refuses on it. Quit the Claude desktop app if it is open.
- B5: the lines are kovacs' with `/Users/matts` for `/home/matts`. `~/.claude` is about 9G, and the backup is an APFS clone (`cp -cRp`), so it costs next to no space.
- B7: the GUI file is `~/Library/LaunchAgents/com.molt.claude-config-dir.plist`, which runs `/bin/launchctl setenv CLAUDE_CONFIG_DIR` at login, so this step is a macOS log out and in.
- B9 and C: as on kovacs, each Claude starts from a shell opened after B7, where `echo "$CLAUDE_CONFIG_DIR"` prints `/Users/matts/.config/claude`. Each agent starts from its home, and each project session from its project, with the transcripts and memory that moved with the state. What C removes on rhadamanth is the inventory's to say.

## gyges

Later, on a date hv sets, and through gyges-infra, whose sleeve agent becomes `gyges-sysadm` when WP04 reaches it. gyges is a Mac, so rhadamanth's differences apply, and gyges-infra inventories its phase A.

## Not decided here

WP06's deny floor for sysadm, which is hv's; gyges' date; and when each backup and each set-aside dir is removed. Until hv says, each stays. That includes three Molt backups A1 left in kovacs' `~/.claude`, which B5 carries into `~/.config/claude` and C3 does not remove: `AGENTS.md.molt-backup.20261021183245` and `CLAUDE.md.molt-backup.20261021183245`, made when A1 linked the user-scope files over kovacs' own, and `settings.json.molt-backup.20261020230015`, from 20 Oct.

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0006/acceptance.md`, under the `WP-04` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
