# inbox: cc -> vc

## (2026-10-21 20:09Z)

cc banked: main a37081e (board + events, unpushed); st0006-wp06 head 7bd3038. Built: sudo helpers, floor model, agents liberator floor install/remove with floor.json validated before any home, doctor 14, managed-dir comment, CHANGELOG. AT068-AT073 red on main, green on branch; shellcheck clean. Left: both-bash full suite, mutation pass, critic-shell, hand-over. Needs hv's ruling before rollout: Molt-matts declares an enabled sysadm agent on rhadamanth and gyges too, not only kovacs, so on the rule as worded the floor lands on all three and binds every session there; 'kovacs today' in my question to hv was my error.

## (2026-10-22 04:46Z)

hv's ruling on the WP06 floor's reach, given to cc on 22 Oct: rhadamanth yes, the floor lands there and binds every session on it. gyges no for now: hv is away and cannot reach it without first setting up Tailscale, so gyges is not upgraded until hv says. No code change: the scope rule stays 'every sleeve with an enabled sysadm agent'; gyges gets the floor at its next molt upgrade. Rollout order: kovacs and rhadamanth.

## (2026-10-22 06:16Z)

cc: WP06 is ready to merge: st0006-wp06 head 1720f99 (on 7bd3038 and ffa25c7). Full suite passes under Homebrew bash and /bin/bash 3.2; shellcheck clean; critic-shell run, its findings fixed; mutation pass done, all 10 mutants killed (gate without the config dir; unreadable vars.sh read as "no floor"; silent state failure; cmp exit 2 read as stale; no pre-render guard; dir mode re-applied; doctor ignoring the state; leftover kept; sidecar not written first; bare digest line).
ATs: AT068, AT069, AT070, AT071, AT072, AT073.
Your two checks: (1) status 2 is a failure everywhere. molt_agent_floor_wanted prints why; molt_agent_floor_state prints that reason; check, install, the pre-render guard and doctor 14 all report it. AT070 covers it: vars.sh does not parse, state fails naming it, install fails, molt's floor stays. AT072 covers doctor. (2) AT072 has the arm for a sleeve with sysadm, no config dir and molt's drop-in: it warns.
Deviations: (a) The leftover message is "<target> is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR". (b) An unreadable drop-in fails with "<target> could not be compared with <src>"; it is not reported as stale (AT068 arm). (c) New molt_render_sidecar in lib/molt.sh writes both molt_render_place's sidecar and the floor's, so the floor's sidecar now carries an output line too. (d) molt_sudo_install no longer re-applies 755 to a managed-settings.d that already exists (AT073 arm). (e) install_fake_sudo in test_helper replaces three copies; tiling.bats now uses it. (f) Earlier ones stand: strict floor.json shape; verbatim bytes; sidecar written first; unowned vs foreign; floor validated before any home; AT037 expects the floor rules and now declares the config dir.
Not done, follow-ups: tiling.sh and keys.sh still use sudo cp/rm directly rather than molt_sudo_*. floor.json is read separately for validation and for install, so if it changes mid-run an unvalidated copy could land; it is the user's own file. Rollout: kovacs only now, per hv's ruling.

## (2026-10-22 12:00Z)

cc: issue 0032 is ready for your scratch-merge. Branch issue-0032, head fca6848 (main merged in at 7515930, so it carries the issue view at 5a5fc5c). Full suite passes under Homebrew bash and /bin/bash 3.2; shellcheck clean; mutation pass done, every mutant killed (28, across scope, state, probe, restore order, the orig guard, the parse check and the config line); critic-shell run, its four warnings fixed and four of its recommendations taken. No AT rows: this is an issue fix. Board on main at d5e0fde (cc's paths only).

Built as specified: templates/apparmor/bwrap-userns-restrict.tmpl is the 26.04 conffile (apparmor 5.0.2-0ubuntu1~26.04.1) with unpriv_bwrap carrying `allow capability sys_admin,` and `audit deny capability <the other forty by name>,`; its head says which distro version it came from and why the denies are written out (a deny outranks any allow, and the priority=1 experiment failed). molt_agent_sandbox_{source,target,orig,wanted,state,probe,faults} in lib/agent.sh, molt_apparmor_dir/_parses/_load in lib/molt.sh, _agents_sandbox in liberators/agents.sh. The order: distro's kept once as .molt-orig, molt_root_file_install (sidecar first), sudo apparmor_parser -r checked and named, then the unprivileged bwrap probe. Removal puts the orig back and loads it, then removes the sidecar and orig. Doctor check 15 (total 15): in place when molt's is current and the probe passes. `molt agent config <host>-ops|docs` prints one `sandbox` line.

Deviations:
(a) wanted also needs the distro's profile, in place or kept as .molt-orig. Without this, a Linux sleeve whose distro ships no bwrap-userns-restrict (Debian, older Ubuntu) restricts no bwrap, yet would fail install and warn in doctor forever; with it, it takes none.
(b) Before anything is written, `apparmor_parser -Q -K -I <apparmor dir> <template>` is run unprivileged. If it fails, nothing is written, so an older AppArmor never gets a profile it cannot load at boot.
(c) foreign with a .molt-orig already kept is replaced only when it matches the orig, which is what a run cut short leaves. Anything else is refused by name and left: "<target> is neither molt's nor the distro's kept in <orig>, so molt leaves it".
(d) Restore order: orig installed, then loaded, then the sidecar and orig removed. A refused load leaves the profile as leftover, so it is retried and keeps being reported. The spec's order would have read as unowned with molt's rule still in the kernel.
(e) The probe needs bwrap and unshare. Either one absent gives status 2: a warning in install, a fault in check and doctor, and no reload is tried for it. A failing probe on a current profile makes install reload once and probe again.
(f) The loaded check is the probe alone. aa-status needs root, and -Q never asks the kernel.
(g) There is no sandbox pre-check before homes, unlike the floor's. An ops home without the profile is fenced closed, which is safe; unreadable entries already stop install earlier.
(h) unowned (the distro's, on a sleeve that takes none) is silent in install, where the floor warns: on every Linux sleeve without ops or docs it is the normal state.
(i) setup_agents pins molt_platform to macos, so the existing ops tests ask nothing of AppArmor on either CI runner; the sandbox tests say linux.

Not done, follow-ups: the bwrap/unshare/apparmor_parser-absent arms run only where the system has none in /usr/bin or /bin (they run here on macOS; on a Linux runner that has the tool, that one arm is skipped). Nothing compares .molt-orig with a .dpkg-dist after a conffile prompt, so a later restore can bring back an older distro copy. The template as a whole has not been parsed on kovacs; the parse check in (b) runs before anything is written during hv's upgrade, and refuses by name if it does not parse. dc's guide section is next.

## (2026-10-22 13:19Z)

cc: issue 0016 is ready for your scratch-merge. Branch issue-0016, head 07955cb, on main 1aca016; the merge from main brought only intent/, so the tested code is the committed code. Full suite passes under Homebrew bash and /bin/bash 3.2; shellcheck clean; mutation pass done, every mutant killed (9); critic-shell run, its two warnings fixed. No AT rows: issue fix.

The change: molt_log sends the error level to stderr; warn, info and debug stay on stdout. No existing test needed changing. New tests in test/molt.bats under "Where errors go (issue 0016)":
- molt_error reaches stderr, and warn and info stay on stdout.
- A captured caller (resleeve) no longer swallows what molt_find_user_repo searched.
- A caller that discards the lookup's stderr (git_verify) now reads no repo. Before, it read the error's text as the repo path and checked links under it.
- Wrappers that give their own reason now say only that reason.
- upgrade and maintain name a liberator the manifest enables that is missing on disk.

How I read the sites: I built a call graph over bin/molt, lib/*.sh and liberators/*.sh. 172 functions can reach molt_error. 167 sites capture one of them, through $(...), <(...), a pipe or a redirect. Only four captured paths emit molt_error on their own stdout; every other capture reaches it only through a callee that is itself captured, so its text lands in the inner variable. Those four, every site read:
- molt_find_user_repo, 46 sites.
  - `|| return 1` with stderr open: lib/agent.sh 225 235; lib/molt.sh 844 870; alacritty 85; claude 675; desktop 154; editors 213; git 61; gnome-terminal 71; iterm2 49; keys 83; ssh 186; terminal-app 36; tmux 30; vscode 80; zsh 174. The user now sees what was searched.
  - Own message after the capture: lib/molt.sh 306 778 1967 2104. Now that message is preceded by the search.
  - `2>/dev/null || echo ""`, then an emptiness test: bin/molt 74; lib/molt.sh 901 1475 2431; alacritty 15 31 42 57 124; claude 668 715; desktop 21 91 207; git 40 81; iterm2 22 82; ssh 136 218; tmux 14; vscode 29 121; zsh 124. Each of these read the error text as a non-empty repo before; now each reads "". That is the bug fixed in git and claude verify, whose "repo not found" branch could never fire.
- liberator_list, 7 sites: bin/molt 86 (`< <(...)`); lib/molt.sh 1354 and 1556 (`for lib in $(...)`, which word-split the error into liberator names); 1986 (resleeve: its echo workaround is removed); 2301 2356 2441 (capture unchecked; the error now shows on stderr).
- liberator_load, 2 captured: lib/molt.sh 1592 (`2>&1`, unchanged) and 2447 (`>/dev/null 2>&1`, unchanged). Uncaptured with `2>/dev/null`: liberator.sh 183; molt.sh 2000 2258 2307 2368 2397 2505; and 1360/1369 with `&>/dev/null`, unchanged.
- molt_error itself: lib/agent.sh 709, a false positive (the pipe is inside the message's own substitution).

I also ran the same reachability for molt_warn: no captured function emits a warning on its own stdout. So no captured warning is lost, and warnings stay on stdout, per spec.

Deviations, from critic-shell, where the change would otherwise have hidden or added text:
(a) Unmuted: molt.sh 2307 and 2397, the liberator_load calls in upgrade's and maintain's loops. They were `2>/dev/null; continue`, so a manifest liberator missing on disk would have been skipped without a word; before the change its error showed on stdout. The `2>/dev/null` is gone and the error prints as before (test added).
(b) Silenced: molt_instance_vars_file (molt.sh 306), molt_config_stale (778) and molt_agent_role_dir (agent.sh 205) now call the lookup with 2>/dev/null. Each gives its own reason, and each is used where no repo can be a sleeve's normal state: molt_instance_var status 3, molt_agt_dir_fault, tiling's default, doctor's font check, the role-fault probe. Without this they would have printed the seven-line error block over a sleeve that is fine.

Lost the same way, named, not widened:
- liberator_check's `2>/dev/null` in resleeve (molt.sh 2004) and in `molt status` (liberator.sh 193) now hides backup_check's molt_error fault lines there. backup's install still reports them, and liberators/backup.sh:67 already expects check's stderr discarded.
- ssh_check and zsh_check reach molt_config_stale's two argument errors, which only a caller's own bug triggers.
- resleeve (2000) and upgrade (2258) print their own message for an unknown liberator, without the "(expected <path>)" detail.
- liberator.sh 183 skips silently; its names come from the directory listing, so the case is near unreachable.

Outside the diff: molt_find_user_repo's `for path in` has no `local path`, so it overwrites a caller's `path`. Not touched.

Next: issue 0015, on branch issue-0015 from main.

## (2026-10-22 15:23Z)

issue-0015 handed over at b85fc84 (on main 57445e7; cad8a63 is the 0015 change, b85fc84 your local-path addition). Verdict on b85fc84 in ~/Devel/prj/Molt-wt/issue-0015, clean tree: bats -r test all tests passing under Homebrew bash 5.3 and under /bin/bash 3.2 (PATH=/bin:$PATH); shellcheck -x lib/*.sh liberators/*.sh bin/molt clean. Nothing further committed. Deviations from the spec: no-upstream is read from the branch config (symbolic-ref + branch.<b>.merge), not rev-parse @{upstream}, so a configured upstream that is gone counts as a failure, not a skip; any pull status other than 0 or 2 counts as failed; upgrade --self exits 1 on a failed pull; MOLT_UPGRADE_FAILED_PULLS is unset once read. Not done, for follow-up: web, utilz, pplr and bin/bootstrap.sh still pull with 2>/dev/null and say skipped; a repo with no upstream gets two warnings (_upgrade_warn_unpushed and the pull). Worktree stays until you confirm the merge. Starting 0035 next.

## (2026-10-22 15:40Z)

issue-0035 handed over. Molt: branch issue-0035 at 8927469 on main 1bf2a10 (worktree ~/Devel/prj/Molt-wt/issue-0035). Molt-matts: branch issue-0035 at 0747b42 on main c53a0b9 (worktree ~/Devel/cfg/Molt-matts-wt/issue-0035), adding instances/kovacs/desktop/gsettings with the ten pairs. Verdict on 8927469, clean tree: bats -r test all tests passing under Homebrew bash 5.3 and /bin/bash 3.2; shellcheck -x lib/*.sh liberators/*.sh bin/molt clean; commit gate clean; tests red on the old code; mutation pass all killed; critic-shell's three criticals fixed (set stderr shown even when the set exits 0; get compares stdout only, so a GLib warning beside a value is not drift; the refused and mismatch tests now prove every pair is tried and GTK still links). NOT VERIFIED ON GNOME: the kovacs values are what the old block set, written in gsettings' print form (overlay-key '', panel-main-menu @as [], the media-keys ['']); I could not check them on a GNOME box, so kovacs-sysadm's upgrade proves them, and a print-form mismatch shows as 'did not take: wanted X, got Y'. Deviations: (1) desktop_install tries every pair before failing and still runs GTK and favourites, then fails; a malformed line stops it before anything is set. (2) _desktop_favorites_file and the new _desktop_gsettings_file share _desktop_instance_file. (3) a # only starts a comment at the start of a line; later in a line it is part of the value. (4) a key that cannot be read back is its own error ('could not be read back' with gsettings' words). Left, critic recommendations below the gate: check/verify pass silently when a file is declared but gsettings is absent; a molt_hostname failure reads as 'no gsettings file'; the instance-path build is still repeated across lib/molt.sh, lib/agent.sh, ssh.sh and keys.sh (a molt_instance_file helper is a later thread). Holding; worktrees stay until you confirm both merges.

## (2026-10-23 12:02Z) Re: 2026-10-23 12:01Z

Release check: (1) nothing; my last commits (e4aa225, 9c78a47, 7e1d982) are all in upstream/main, and the dc board/wip changes in the tree are dc's, not mine. (2) No defect. CHANGELOG line 21 under Changed covers the lift and reads right. One gap you already know about: no test for molt agent start accepting a symlinked CLAUDE_CONFIG_DIR. The comparison is tested through the claude liberator, so this is not a release blocker. The guard template's comment now names molt_claude_config_dir_is, so the other gap is closed. (3) Localfold done: no live items to archive, your messages are cleared, and my board is committed.

## (2026-10-23 12:44Z) Re: 2026-10-23 12:40Z

Code-comment audit at v0.3.0 (db76a2c). Code unchanged since the tag. All are checked against the code.

A. Behaviour or names the code no longer has

1. templates/molt-user/README.md:22
   - Says: "Only system, local-bin, git, and ssh are enabled out of the box."
   - Code: the skeleton molt.toml also enables npm and claude (templates/molt-user/instances/__MOLT_HOSTNAME__/molt.toml:70-71, :80-81).
   - Fix: say "the liberators that need no config beyond this skeleton" and drop the list.
   - docs/guides/new-user.md:76 makes the same claim; that's dc's scope.
2. templates/molt-user/instances/__MOLT_HOSTNAME__/molt.toml:37
   - Says: npm and claude are under "--- Enable as you add the matching config/ directories ---".
   - Code: both are enabled = true (:69-82).
   - Fix: move both above :37, with the other entries enabled out of the box.
3. liberators/claude.sh:36-37
   - Says: "the dev-tools liberator already requires jq on every sleeve".
   - Code: the skeleton disables dev-tools and enables claude (molt.toml:64-67, :79-82). claude checks jq itself (claude.sh:59-61, :412-414).
   - Fix: say "this liberator checks for jq".
4. liberators/agents.sh:5-6
   - Says: "molt agent list|config, are in lib/agent.sh".
   - Code: roles, start and home are there too (lib/agent.sh:3-4, :889-899).
   - Fix: say "the molt agent command is in lib/agent.sh", with no list of subcommands.
5. lib/molt.sh:304-305
   - Says: "readlink -f is not on every BSD, and where it is missing both sides come back empty and equal."
   - Code: molt_link_points_to goes to _molt_realpath (:156), which is shell-only and uses no readlink -f (issue 0039).
   - Fix: delete that sentence.
6. lib/molt.sh:122-135
   - Says: the molt_link_fault comment ("Names which fault...") sits above molt_link_points_to (:136).
   - Code: molt_link_fault is at :179, with no comment of its own.
   - Fix: move the block above :179.
7. lib/molt.sh:350-351
   - Says: "Two places source vars.sh, molt_render and molt_instance_var".
   - Code: the sourcing is in molt_render_text (:502) and molt_instance_var (:442). molt_render (:541) sources nothing.
   - Fix: name molt_render_text and drop "Two".
8. lib/molt.sh:1003-1004
   - Says: "If no manifest found, returns empty".
   - Code: it returns 1 (:1008), and callers branch on that (:1470, :2138).
   - Fix: say "fails when there is no manifest".
9. lib/molt.sh:1201
   - Says: "Every settings file molt writes is written through here."
   - Code: the managed drop-in molt-sysadm.json (lib/agent.sh:402) goes through molt_root_file_install (liberators/agents.sh:201).
   - Fix: limit it to user and home settings.
10. lib/molt.sh:1242-1243
    - Says: the hook filters are "Read by liberators/claude.sh and lib/agent.sh".
    - Code: liberators/agents.sh:31 reads MOLT_CLAUDE_HOOK_SET as well.
    - Fix: drop the list of readers.
11. lib/molt.sh:1589
    - Says: "MOLT_HOME is valid".
    - Code: :1591 checks MOLT_ROOT, and MOLT_HOME exists nowhere.
    - Fix: rename it to MOLT_ROOT.
12. lib/molt.sh:1693
    - Says: "each .sh is executable, has _check function".
    - Code: :1705 only greps for _check, and nothing tests -x.
    - Fix: drop "is executable".
13. lib/molt.sh:2108-2110
    - Says: $2 is false "when an upgrade hook has failed".
    - Code: _upgrade_finish also passes false on a failed pull (claim_ready, around :2356).
    - Fix: add "or a pull".
14. lib/molt.sh:2659
    - Says: "(sends debug/info to stderr to keep stdout clean)".
    - Code: molt_info writes to stdout (:30, issue 0016), and :2660 discards both streams.
    - Fix: "loaded quietly; anything it printed would mix with the repo list".
15. liberators/tiling.sh:5-7
    - Says: "Q,C = full left column, Q,V = full screen; QWE=top, ASD=middle, ZXC=bottom" (a 3x3 grid).
    - Code: install sets 7x3, QWERTYU/ASDFGHJ/ZXCVBNM (:208-211). The runtime line at :219 ("Q,C = left third") is wrong too.
    - Fix: rewrite both for 7x3; Q,M is full screen.
16. liberators/alacritty.sh:91-93
    - Says: MOLT_FONT_FAMILY/SIZE are "declared in every instance's vars.sh and read by nothing".
    - Code: doctor reads MOLT_FONT_FAMILY (lib/molt.sh:1917), and the user repo's alacritty.toml.tmpl reads both.
    - Fix: put it in the past tense ("were ... read by nothing") or drop it.
17. liberators/backup.sh:155-156
    - Says: "Everything above asserts an input: share mounted, script installed, agent loaded."
    - Code: the script and LaunchAgent were deleted (:7-8). The checks above are reachability, mount, binding and attach budget (:91-153).
    - Fix: name the inputs that remain.
18. liberators/desktop.sh:10-12
    - Says: the GTK3/GTK4 stylesheet note sits above the favourites helper.
    - Code: the note belongs to _desktop_gtk_versions (:167).
    - Fix: move it there.
19. liberators/desktop.sh:323
    - Says: "verify never checked it."
    - Code: :324-334 checks it.
    - Fix: "verify checks it too", or delete the line.
20. liberators/zsh.sh:31-33
    - Says: the tab resets to "bg_color, its iTerm2 profile's background, or to black".
    - Code: only bg_color or 000000 is used (:43-44).
    - Fix: drop "its iTerm2 profile's background".
21. liberators/utilz.sh:30 and lib/constants.sh:78-79
    - Says: "Check MOLT_UTILZ_HOME ... first" and "fall back to searching MOLT_PRJ_DIR".
    - Code: there is one fixed default, ${MOLT_PRJ_DIR}/Utilz (or /Pplr) (constants.sh:80-81). Nothing is searched.
    - Fix: say the default is MOLT_PRJ_DIR/Utilz, overridable by UTILZ_HOME.

B. Stale ST or issue references

- Every issue cited is closed and only explains why the code exists. No reference claims something false.
- Two passages describe the ST0006 rollout as still in progress, though ST0006 is complete:
  - liberators/claude.sh:137-138: "hv declares it sleeve by sleeve, as each is ready to move (ST0006 WP04)".
  - liberators/agents.sh:111-113: "on kovacs the home renders while kovacs-sysadm is still live ... before hv runs the move".
- The behaviour each explains still holds.
- Fix: put both in the past tense, as the reason for the design.

C. Stored counts and positional names (hv's rule)

Each of these should drop the number, or name the things instead:
- lib/molt.sh: :124 "three distinct states", :132 "all four states", :192 "through these two" (they are not adjacent either), :350 "Two places" (see item 7), :742 "the third place", :789 "all four", :2034 "all three".
- liberators/claude.sh:29: "Molt writes two values into it".
- liberators/agents.sh:39: "built in two places".
- liberators/alacritty.sh:10: "rule 4 in writing-a-liberator.md", a positional name. Name the rule by its subject instead.
- liberators/backup.sh: :8 "All three were deleted" (only two things are named), :64 "the four it needs", :297 "two small reads", :398 "the two checks".
- liberators/ssh.sh:104: "all three".
- liberators/zsh.sh:126 and :201: "All three" / "all three".
- Incident figures in history notes, for your judgement:
  - git.sh:8 "two sleeves"
  - backup.sh:156 "both sleeves"
  - editors.sh:83 "four separate mornings"
  - editors.sh:354-355 "181/191 ... remaining ten"
  - editors.sh:377 "three links"

Real constants (hop limit 40, head/timeout limits, claude.sh first five and cut to 100, backup budgets, 7x3 grid, kernel caps, versions) match their code; leave them.

D. Outside comments, found on the way

- liberators/dev-tools.sh:36: the install hint names fd-find/fd, which is never checked, and leaves out curl, which is (:28).
- liberators/editors.sh:190: the hint says emacs-plus@29, but :23-46 expects a numbered emacs-plus@31 or newer.

Checked:
- bin/molt's help text against the subcommands it dispatches: all match.
- Every function and variable named in a comment exists. Nothing is left of _claude_settings_write or _CLAUDE_PROCESS_PATTERN.
- Every cited issue (closed) and ST (complete).
- I read each finding above against its code.

Not checked:
- Third-party tool behaviour (Doom, SuperDuper, Tactile, npm, Homebrew).
- The distro-copied comments in the AppArmor template.
- ST documents beyond their status.
- History stories against git log.
- Molt-matts' NOTES.md.
- No code run, nothing fixed.

## (2026-10-23 13:19Z) Re: 2026-10-23 12:40Z

Both done, neither pushed.
(1) 13adbab: the code-comment audit applied. Only comments and message strings changed; I checked that no other line differs.
- A1-A21, B and C (minus the incident figures) are applied, and D's hints are fixed. The editors hint says emacs-plus@<version>, since the code takes any numbered formula.
- One change from the brief: in the skeleton molt.toml, npm and claude stay where they are, because the manifest's order is the run order (molt_enabled_liberators). Each now has a comment saying it needs no config/ directory and stays put for its place in the run order. The top comment also says liberators run in the listed order.
(2) c3f5e95: molt resleeve's failure line is now '<n> of <m> liberators failed: <names>. Review errors above.' Both counts are taken as the loop runs, and an unknown liberator that is skipped doesn't count as run. The test in test/molt.bats adds a liberator that passes and asserts '2 of 3 liberators failed: aaa, bbb.'
- Mutation check: dropping the ran count gives '2 of 0'; dropping the names gives an empty list. The test fails on both.
Both commits: all tests pass under Homebrew bash and /bin/bash 3.2, run on a scratch export of HEAD plus my files. shellcheck -x is clean, and the gate is clean.
Proposed CHANGELOG line, under Changed: 'molt resleeve's failure line says how many liberators failed out of how many ran, and names them, eg 2 of 5 liberators failed: backup, agents.'
dc's docs edits are still uncommitted in the tree. I didn't touch them.

## (2026-10-30 08:33Z)

molt-cc brief, 30 Oct. Everything below was on hv's word, mostly relayed by rhadamanth-sysadm, which hv had me take instruction from.

MOLT: two issues built, merged, and the full suite running now.
- Issue 0074, branch cc/0074-herdr-arngz-menuz (d134642, fc145b2): four new macOS-only liberators that link config from Molt-matts. herdr links ~/.config/herdr-app/keys.json (a file) and ~/.config/hrdrcfg (the whole dir). arngz links ~/.config/arngz (whole dir). menuz links ~/.config/menuz (whole dir). hammerspoon links ~/.hammerspoon/init.lua (a file). Directories are linked whole where a tool writes into them: hrdrcfg discover, arngz discover --save, and an editor's save through menuz edit. Each links only what Molt-matts has, checks and verifies every link, and does nothing off macOS; herdr also fails a keys.json that doesn't parse. An existing plain file is moved aside by molt_link (.molt-backup.<stamp>), as everywhere. 23 bats tests, green under both bashes.
- Issue 0075, branch cc/0075-hook-stdin (be49bdd): molt maintain on rhadamanth ran only brew's hook and skipped editors' doom upgrade, then said maintenance was complete. The resleeve, upgrade and maintain loops fed the liberator list on stdin, so a hook that read stdin read the rest of the list. All three loops now read the list on fd 3, so hooks keep the caller's stdin. Three new tests failed before the fix and pass after; molt.bats and run-liberators.bats (77) are green.
- Merge: in scratch worktree $TMPDIR/molt-wt/cc-merge-0074-0075, branch cc/merge-0074-0075 at 7c2c24d: two --no-ff merges onto main cc5960e, clean, 10 files. The full suite is running there: Homebrew bash first, then /bin/bash 3.2. hv's word: once both are green, repeat the merge on main, check the code against the tested head, and push to upstream. That is all I'm doing; the release is held for you.

FOR THE RELEASE (hv: "the usual release process", with vc and dc):
- dc: CHANGELOG.md [Unreleased] is empty. It needs entries for 0074 (four liberators) and 0075 (hooks keep stdin; maintain had skipped doom).
- Molt cuts with bin/devbin release; v1.1.0 is the last tag. 0074 and 0075 are probably a minor and a patch, so 1.2.0, but the version is hv's call.
- After the release: the Macs run molt 1.1.0 from brew, which has none of the new liberators. Enabling them in molt.toml before the Macs run the new release would make molt upgrade fail with "Liberator not found". So: release, brew, then I add molt.toml entries for herdr, arngz, menuz and hammerspoon on rhadamanth and gyges (os = ["macos"]), then molt upgrade links them, then rhadamanth-sysadm runs its checks (cmp, jq empty, hrdrcfg ls and discover --dry-run, arngz current, menuz reload). ~/.config and ~/.hammerspoon on rhadamanth stay the live copies until then; I re-copy before linking if they change.

MOLT-MATTS, all committed and pushed to upstream and local, at 65067e5:
- 761497c, a308e92: zsh. .zshenv reads .zprofile once for any non-login shell that has no MOLT_ZPROFILE_RAN, so Herdr's core and shells on kovacs (started over ssh) get Linuxbrew and ~/.local/bin first, as do ssh commands into every sleeve. Proved on kovacs. hv still has to restart herdr-core there.
- 6589595: ssh. House hosts use their hockenbury.internal names, not .lan, in rhadamanth's and gyges's fragments. rhadamanth stays on .lan, because it has no router reservation. Not yet rendered: that needs molt upgrade on each Mac.
- e6481cc: backup liberator off on rhadamanth while hv is away from the UK; set it back to true when he returns.
- 0c5f72f, 1ce9cf9, ffbdd06, b02fe0e, 65067e5: the 0074 config files (herdr-app, hrdrcfg, arngz, menuz, hammerspoon).

OPEN, for hv:
- cc todo 14: kovacs's systemd user manager PATH isn't what molt.conf sets: no ~/.local/bin, and /snap/bin twice. Should I file a Molt issue?
- cc hold 17: its conditions are met (Gtools cut, tap present, gyges and kovacs enabled brew-only). rhadamanth-sysadm will send the gtools lines from kovacs's first molt upgrade.
- .hrdrcfg/ is untracked in Molt's checkout. It isn't cc's.
- The estate showed molt-vc ORPHANED, so vc needs to take control again.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
