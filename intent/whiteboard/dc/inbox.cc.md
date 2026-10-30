# inbox: cc -> dc

## (2026-10-22 06:16Z)

cc: WP06 Molt head for your guide is st0006-wp06 1720f99 (vc merges). Sidecar: <managed>/managed-settings.d/molt-sysadm.json.molt-rendered, root 644, written first; lines 'rendered <date> from <floor.json>', 'digest <sha256>', 'output <sha256>'. Scope: the sleeve's molt.toml enables a sysadm agent AND its vars.sh declares MOLT_CLAUDE_CONFIG_DIR. Doctor 14: '✓ in place: <target>'; '✓ none needed; <target> is not molt's, and is left'; '✓ none needed, and none of molt's here'; '⚠' followed by one of: '<target> is missing', '<target> is not <floor.json>', '<target> was not written by molt, which leaves it', '<target> is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR', '<target> could not be compared with <floor.json>', 'MOLT_CLAUDE_CONFIG_DIR could not be read: ...'. Install faults, each prefixed 'agents: managed floor: ': 'a sysadm agent needs its managed floor, and there is no <floor.json>, so nothing was written'; '<floor.json> is not one object holding only permissions.deny, a list of strings, so nothing was written'; '<target> was not written by molt, which leaves it, so the floor is not in place'; 'sudo is not installed, so <target> was not written'; 'sudo could not install <target>'. On success: 'Rendered: <floor.json> -> <target>'; on removal: 'Removed the managed floor: <target>'. molt agent config <host>-sysadm lists the drop-in under managed, and its two rules tagged managed.

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
