---
wp_id: WP-01
title: Harness state leaves $HOME: claude liberator honours CLAUDE_CONFIG_DIR, renders it, moves once, refuses $HOME launches
scope: S
status: Done
---

# WP-01: Harness state leaves $HOME: claude liberator honours CLAUDE_CONFIG_DIR, renders it, moves once, refuses $HOME launches

## Objective

Claude Code's state leaves $HOME on a sleeve that declares MOLT_CLAUDE_CONFIG_DIR: the claude liberator honours CLAUDE_CONFIG_DIR, renders env.sh, the GUI file and the home-launch guard, moves ~/.claude and ~/.claude.json once with a clone backup, publishes the variable only once the state is in place, links the user-scope CLAUDE.md and AGENTS.md, and reports through doctor; merged to main at 695e961 on 21 Oct.


Owner: molt-cc. Branch `st0006-wp01` in a git worktree; molt-vc reviews and merges.

## Contract

1. **One accessor for the config dir.** `molt_claude_config_dir` in `lib/molt.sh` answers `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`; every `$HOME/.claude` in `liberators/claude.sh` (five today) goes through it. WP02's agents liberator uses the same accessor.
2. **One value, rendered twice, and it is the switch.** The sleeve's `instances/<host>/vars.sh` carries `MOLT_CLAUDE_CONFIG_DIR` (the value hv declares in WP04 is `${XDG_CONFIG_HOME:-$HOME/.config}/claude`). Everything this package adds (the move, the env file, the GUI file, the `$HOME` hook) runs only on a sleeve that declares it; an undeclared sleeve keeps today's behaviour plus the accessor and the 4a links. So merging WP01 changes no sleeve, and declaring the variable in a sleeve's vars.sh is how hv arms the move there, in WP04 (molt-cc's reading 1; on rhadamanth Chrome's native host keeps a `claude` process alive at all times, so an ungated move would refuse on every upgrade). The move targets the declared value, since under 3a `CLAUDE_CONFIG_DIR` cannot be set before it; once the state is in the declared dir, `claude_install` exports `CLAUDE_CONFIG_DIR` for the rest of the run so its links, statusLine and hook, and WP02's homes in the same resleeve, land there. Molt renders it into an env file the shell sources (`~/.config/molt/env.sh`, the pattern the iTerm2 ssh wrapper already uses) and into the GUI environment path: a LaunchAgent plist running `launchctl setenv CLAUDE_CONFIG_DIR` on macOS, `~/.config/environment.d/claude.conf` on Linux. Both carry `.molt-rendered` digest sidecars. `~/.zshenv` is a symlink into Molt-matts, not a render, so the value never appears in it as a literal; the zshenv line that sources the env file is Molt-matts work (WP03). On GNOME, `environment.d` reaches every GUI and terminal child; zshenv matters for ssh and TTY logins.
3. **The move, once.** When `$HOME/.claude` is a real directory and the config dir does not exist, `claude_install` backs up and moves `~/.claude` and `~/.claude.json` into place. It refuses, naming the processes, when any Claude Code is running (`pgrep -f`, never `pgrep -x`: board watchout 6), because a live session cannot survive its own state moving. It refuses a non-empty config dir, naming its contents, and never merges the two. `claude_install`'s `mkdir -p "$HOME/.claude"` (line 141 today) is the most dangerous of the five hardcoded sites: with the variable set it would recreate exactly what doctor faults.
3a. **The variable is published only once the state is where it points.** The env file and the GUI file are written only when the config dir holds the state (the move succeeded in this run, or `~/.claude` is already absent and the config dir present). When the move is refused for any reason, nothing is written in that run, in either dir: no env file, GUI file, link, statusLine or hook; the refusal says the variable was not published and `claude_install` returns 1, while resleeve carries on to the other liberators so an agent home still renders. Anything at all at `~/.claude` (file, dir or link) also refuses publication. The backup before the `mv` is a clone beside the target (`cp -cR` on APFS, `cp -a --reflink=auto` on Linux), never in `$HOME`. Otherwise the next Claude starts empty in the new dir (new login, new `.claude.json`) and the later move meets a non-empty target: split brain (kovacs-sysadm H1).
4. **Refuse `$HOME` launches.** A `UserPromptSubmit` hook, merged into the user `settings.json` the way the statusLine already is (generalise `_claude_statusline_install` into one merge-a-key function; Highlander), runs a script Molt renders into `~/.config/molt/`. The script reads the hook's JSON on stdin, and when `cwd` is `$HOME` exits 2 with "launch from an agent home: molt agent list". Any other cwd passes. The hook must not depend on `molt` being on PATH at prompt time.
4a. **User-scope rules, linked.** `_claude_links` gains `config/claude/CLAUDE.md` and `config/claude/AGENTS.md`, linked to `$(molt_claude_config_dir)/CLAUDE.md` and `AGENTS.md` when the user repo has them, as `keybindings.json` is today (hv, 21 Oct). An existing regular file there is backed up before the link, as `molt_link_all` already does; rhadamanth's current `~/.claude/CLAUDE.md` is hv's richest copy and WP03 seeds the repo files from it, so the link must never land before the repo has the content (check reports the pending link; install makes it).
4b. **No checkout paths in anything rendered.** The hook script, env file and GUI file name only paths under `~/.config/molt/`, the config dir and `$HOME`; never `$MOLT_PRJ_DIR/Molt/...`. A brew-installed Molt (coming; hv) must produce byte-identical renders. The `.molt-rendered` sidecar's provenance line names the template path, as every sidecar does today; that is metadata nothing executes, and is allowed. The GUI file takes effect at the next login; Molt does not call `launchctl` or `systemctl`.
5. **Doctor.** `claude_check` reports: `CLAUDE_CONFIG_DIR` unset in the environment molt runs in; `~/.claude` or `~/.claude.json` present (file, dir or link) while the config dir is elsewhere, as the sign a launch path missed the variable; the env file, GUI file or hook missing or stale.

## Tests (bats, both bash 5 and `/bin/bash` 3.2)

Fake `$HOME` and fake config dir; a `pgrep` stub for the running-Claude refusal; a non-empty target refused and nothing merged; env and GUI files absent after any refusal and present after a successful move; the hook script run with CLAUDE_PROJECT_DIR at `$HOME` (exit 2, message), elsewhere (exit 0), and unset (exit 1, blocks nothing); it reads no JSON and needs only sh; the merge function leaving every other settings key byte-identical (`jq -S` compare). No test may touch the real `~/.claude`.

## Out of scope

Codex. The compat symlink (hv: none). Moving any real sleeve (WP04).

## Acceptance

Acceptance Criteria for this work package are RENDERED into `ST0006/acceptance.md`, under the `WP-01` heading. THAT FILE IS A GENERATED VIEW -- a row authored there is discarded by the next sync. The contract is canon in the thread's model, and the verbs write it: `intent ac new` and `intent at new` mint a row, `intent ac edit` and `intent at edit` reword or re-cite one, and `intent ac satisfy|unsatisfy|descope|rescope|withdraw|reinstate` and `intent at green|red|na` move its state. This cover never restates them.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
