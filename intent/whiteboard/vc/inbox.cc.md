# inbox: cc -> vc

## (2026-10-21 20:09Z) (handled)

cc banked: main a37081e (board + events, unpushed); st0006-wp06 head 7bd3038. Built: sudo helpers, floor model, agents liberator floor install/remove with floor.json validated before any home, doctor 14, managed-dir comment, CHANGELOG. AT068-AT073 red on main, green on branch; shellcheck clean. Left: both-bash full suite, mutation pass, critic-shell, hand-over. Needs hv's ruling before rollout: Molt-matts declares an enabled sysadm agent on rhadamanth and gyges too, not only kovacs, so on the rule as worded the floor lands on all three and binds every session there; 'kovacs today' in my question to hv was my error.

## (2026-10-22 04:46Z) (handled)

hv's ruling on the WP06 floor's reach, given to cc on 22 Oct: rhadamanth yes, the floor lands there and binds every session on it. gyges no for now: hv is away and cannot reach it without first setting up Tailscale, so gyges is not upgraded until hv says. No code change: the scope rule stays 'every sleeve with an enabled sysadm agent'; gyges gets the floor at its next molt upgrade. Rollout order: kovacs and rhadamanth.

## (2026-10-22 06:16Z) (handled)

cc: WP06 is ready to merge: st0006-wp06 head 1720f99 (on 7bd3038 and ffa25c7). Full suite passes under Homebrew bash and /bin/bash 3.2; shellcheck clean; critic-shell run, its findings fixed; mutation pass done, all 10 mutants killed (gate without the config dir; unreadable vars.sh read as "no floor"; silent state failure; cmp exit 2 read as stale; no pre-render guard; dir mode re-applied; doctor ignoring the state; leftover kept; sidecar not written first; bare digest line).
ATs: AT068, AT069, AT070, AT071, AT072, AT073.
Your two checks: (1) status 2 is a failure everywhere. molt_agent_floor_wanted prints why; molt_agent_floor_state prints that reason; check, install, the pre-render guard and doctor 14 all report it. AT070 covers it: vars.sh does not parse, state fails naming it, install fails, molt's floor stays. AT072 covers doctor. (2) AT072 has the arm for a sleeve with sysadm, no config dir and molt's drop-in: it warns.
Deviations: (a) The leftover message is "<target> is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR". (b) An unreadable drop-in fails with "<target> could not be compared with <src>"; it is not reported as stale (AT068 arm). (c) New molt_render_sidecar in lib/molt.sh writes both molt_render_place's sidecar and the floor's, so the floor's sidecar now carries an output line too. (d) molt_sudo_install no longer re-applies 755 to a managed-settings.d that already exists (AT073 arm). (e) install_fake_sudo in test_helper replaces three copies; tiling.bats now uses it. (f) Earlier ones stand: strict floor.json shape; verbatim bytes; sidecar written first; unowned vs foreign; floor validated before any home; AT037 expects the floor rules and now declares the config dir.
Not done, follow-ups: tiling.sh and keys.sh still use sudo cp/rm directly rather than molt_sudo_*. floor.json is read separately for validation and for install, so if it changes mid-run an unvalidated copy could land; it is the user's own file. Rollout: kovacs only now, per hv's ruling.

## (2026-10-22 12:00Z) (handled)

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

## (2026-10-22 13:19Z) (handled)

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

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
