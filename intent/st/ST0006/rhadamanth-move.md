# ST0006 WP04: moving rhadamanth, step by step

Written 22 Oct 2026, 19:31Z, by vc for hv to run at the keyboard with no Claude open. It is the rhadamanth pass of the WP04 runbook (`intent/st/ST0006/WP/04/info.md`) written out whole, with Mac paths, so nothing has to be read as a delta from the kovacs section. Where the two disagree, the runbook is canon and this file is wrong.

## What is left in ST0006

WP04 is the only open work package. Its acceptance criteria all pass (21 of 21). What remains is this move and, after it, the close-out: `intent wp done 6/04`, `intent st done 6` with gyges carried on vc's board as todo 5, and the globalfold. vc does the close-out on its first session after the move.

## State before you start

- B1 is done: `instances/rhadamanth/vars.sh` in Molt-matts declares `MOLT_CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"` (Molt-matts f182813, pushed).
- B2 is skipped: that commit was made in rhadamanth's own Molt-matts checkout, the one molt reads.
- The three agent homes are rendered: `~/Devel/agt/rhadamanth-sysadm`, `rhadamanth-ops`, `rhadamanth-docs`.
- Claude Code's state is still in `~/.claude` (about 9G) and `~/.claude.json`; `~/.config/claude` does not exist; `CLAUDE_CONFIG_DIR` is unset in every shell. That is the expected before-state.
- Both checkouts are clean and level with upstream: Molt main 5d1d5d0, Molt-matts main f182813.

## Step 1. Quit every Claude on this machine (B4)

Quit every Claude Code session, each from its own terminal: molt-vc, molt-cc, molt-dc, molt-ac; the four intent sessions; the four gtools sessions; the three zeop sessions; prodinfra-cc; geodica-estate; any other. kovacs-sysadm runs on the kovacs VM, not here, and stays up.

Quit Chrome: with the Claude extension installed, its native host (`~/.local/bin/claude --chrome-native-host`) is a `claude` process and the move refuses on it. Quit the Claude desktop app if it is open.

## Step 2. Preflight, in a plain terminal

```bash
pgrep -afl '^([^ ]*/)?claude( |$)|@anthropic-ai/claude-code'
cd ~/Devel/prj/Molt && git status --short
cd ~/Devel/cfg/Molt-matts && git status --short
```

The first must print nothing. If it names a process, quit it and run it again. The two `git status` lines must print nothing: a dirty checkout stops `molt upgrade` before anything runs (runbook P4). If a late heartbeat left a board file modified in Molt, run `git stash` there and tell vc on the bounce; vc sorts it out.

## Step 3. Run the move (B5)

```bash
molt upgrade
```

Among molt's other lines, Claude's part prints these, in this order:

```
Zen: claude: Claude Code's state is still in ~/.claude and ~/.claude.json, and this sleeve's config dir is ~/.config/claude: quit every Claude Code, then run molt resleeve to move it
Zen: Running liberator: claude (install)
Zen: claude: moved Claude Code's state into ~/.config/claude; the copies taken first are in ~/.config/claude.molt-backup.<stamp>
Zen [warning]: claude: CLAUDE_CONFIG_DIR is not ~/.config/claude in this shell. Start Claude Code only from a new shell that sources ~/.config/molt/env.sh, and log out and in for apps started from the GUI
Zen [warning]: Backing up existing file: /Users/matts/.config/claude/settings.json -> /Users/matts/.config/claude/settings.json.molt-backup.<stamp>
Zen: claude: home-launch hook written into ~/.config/claude/settings.json
Zen: Liberator complete: claude
  claude: ✓ installed
```

The first line is the check reporting the pending move just before the install carries it out. The first warning is expected: this shell started before `env.sh` existed. Write down the backup path from the `moved` line; a rollback starts from it. The copy is an APFS clone and costs next to no space.

This run also installs WP06's managed floor, so `sudo` asks for your password part way through. The agents liberator reports `Zen: Rendered: /Users/matts/Devel/cfg/Molt-matts/config/agents/roles/sysadm/floor.json -> /Library/Application Support/ClaudeCode/managed-settings.d/molt-sysadm.json`. If sudo is refused, the run reports `Zen [error]: agents: managed floor: <why>` and `Zen [error]: Liberator failed: agents`; the floor is not in place, and `molt upgrade` again, answering the prompt, installs it.

The run should end `Zen: Sleeve ready. Welcome back.`

If the claude liberator refuses, nothing is moved. The refusal ends with `Zen [error]: claude: CLAUDE_CONFIG_DIR was not published` and `Zen [error]: Liberator failed: claude`. Read the first error line:

- `Claude Code is running, and a live session cannot survive its own state moving:` then one `<pid> <command>` line per process. Quit each one named and run `molt upgrade` again.
- `pgrep could not list processes`. Run it again; if it repeats, stop and tell vc on the bounce.
- A line containing `already holds`, `is a symlink to`, `both exist`, `holds nothing, and CLAUDE_CONFIG_DIR named` or `is not a`, with the not-published line ending `and nothing else was changed`. Stop, change nothing by hand, and relaunch vc to look (it is safe to relaunch: nothing moved, so the state is where it was).
- A line naming the copies, `the copies are in ~/.config/claude.molt-backup.<stamp>`, with the not-published line ending `no env.sh or GUI file was written`: the move failed after copying began. If it says `nothing was moved`, the state is still in `$HOME`: deal with the cause it names and run again. If it says the state `is split`, start no Claude: follow the line (it says which file to move where) or roll back, then relaunch vc from a fresh shell to check.

The full refusal table is the runbook's B5.

## Step 4. Check from a new terminal (B6)

Open a new terminal window. Shells opened before step 3 do not have the variable.

```bash
echo "$CLAUDE_CONFIG_DIR"
ls -d ~/.claude ~/.claude.json
ls -A ~/.config/claude.molt-backup.<stamp>
```

The first prints `/Users/matts/.config/claude`. The second finds neither (two "No such file or directory" lines). The third lists `.claude` and `.claude.json`, the copies a rollback needs.

## Step 5. Log out of macOS and back in (B7)

The GUI gets the variable from `~/Library/LaunchAgents/com.molt.claude-config-dir.plist`, which runs `launchctl setenv CLAUDE_CONFIG_DIR` at login. Nothing else does it. Log out and in.

## Step 6. Check the sleeve (B8)

In a terminal opened after the login:

```bash
echo "$CLAUDE_CONFIG_DIR"
molt doctor
```

The echo prints `/Users/matts/.config/claude`. Doctor's check 14 reads `Checking managed floor... ✓ in place: /Library/Application Support/ClaudeCode/managed-settings.d/molt-sysadm.json`, and the enabled-liberators step names no `claude:` report. Any other line there is a row of the sleeve-agents guide's "What molt doctor reports" (`docs/guides/sleeve-agents.md`).

## Step 7. Copy the sysadm memory into its home

The sessions launched from `$HOME` were sysadm work, and their memory moved with the state. Copy it into rhadamanth-sysadm's home, which is where that agent reads it from:

```bash
cp -Rp ~/.config/claude/projects/-Users-matts/memory/. ~/Devel/agt/rhadamanth-sysadm/memory/
ls ~/Devel/agt/rhadamanth-sysadm/memory/
```

The listing should show `MEMORY.md` and the notes beside it (nine on 22 Oct, doom-emacs-version-profile-miss through volumes-numbered-mountpoints).

## Step 8. Relaunch (B9)

Every Claude starts from a shell opened after the login. In each one, `echo "$CLAUDE_CONFIG_DIR"` must print `/Users/matts/.config/claude` first; if it prints nothing, close that shell and open another.

- rhadamanth-sysadm, from its home, by name: `cd ~/Devel/agt/rhadamanth-sysadm && claude --name rhadamanth-sysadm`. Accept the workspace trust dialog; log in if asked. The first prompt passes the home-launch guard because the session started in a home. A launch from `$HOME` itself is refused by that guard with "launch from an agent home: molt agent list".
- Each project session from its project directory, as before: `cd ~/Devel/prj/Molt && claude --name molt-vc`, and so on. Launch order does not matter; every board already carries the new whiteboard shape.

From here the floor binds every session on this machine, project sessions included: `Read(~/.ssh/id_*)` and `Read(~/.aws/credentials)` are refused. That is by design.

## Step 9. What vc does on the bounce

Tell it the move ran, and anything that looked wrong. It verifies steps 4 and 6 itself, then closes WP04 and ST0006 with gyges carried, folds the project docs, commits and pushes. If the move did not run, WP04 stays open and the decision is yours.

## Rollback

The runbook's Rollback section (R1 to R5) applies, with the Mac notes in its rhadamanth section: the GUI file is the LaunchAgents plist, the copy back is `cp -cRp "$b/.claude" "$b/.claude.json" ~/` from the backup step 3 named, and once R1 has disarmed the move the next `molt upgrade` removes the floor through sudo. Quit every Claude first, as in step 1.
