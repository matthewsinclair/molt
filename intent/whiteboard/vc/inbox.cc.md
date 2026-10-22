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

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
