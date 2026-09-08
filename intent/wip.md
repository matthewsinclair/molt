---
verblock: "08 Sep 2026:v0.18: Matthew Sinclair - ST0001 closed after six months; honest-instrument sweep; ST0003 opened"
---

# Work In Progress

## Current Focus

**Nothing in flight.**

The 8 Sep session was a sweep for one defect class: **an instrument that reports success while the condition it names is false.** Six instances, five closed:

- `molt doctor` check 6 printed a green tick for every ratio, so `0/16` rendered byte-identical to `16/16`, and it discarded the reason its own check function had already printed. Now warns, names the liberators, prints the reason. It immediately surfaced a `15/16` that had been invisible.
- `intent_verify` passed on exactly the mismatched link `intent_check` warns about -- it asked whether the link resolved, never whether it resolved to what the liberator installs.
- The `intent` liberator found the Intent repo by probing for `bin/intent`, so Intent's pending v2-script deletion would have made Molt tell you to clone a repo sitting on disk. It now identifies a repo by being one.
- Nothing asserted that the font a config names is one the machine can resolve; fontconfig falls back silently, so the terminal opens fine minus its glyphs. New doctor check 13. It deliberately does not use `fc-match`, which returns Verdana for a font that does not exist and therefore cannot express absence at all.
- `e` in Molt-matts had discarded its filename argument since it was written, because an alias appends arguments after a body ending in `&`.

The sixth is open and escalated: **`backup_verify` returns PASS having asserted nothing** when away from home or when the share is unmounted, and the backup liberator has **zero tests** across 477 lines and 17 functions. Those are one finding, not two.

Everything from this session is on `upstream/main` and the Dropbox mirror.

kovacs now has its own clones on local ext4 with conventional names (`Molt`, `Molt-matts`, `Utilz`); nothing of rhadamanth's tree reaches it except `~/mac`, browse-only. All three sleeves report doctor green (11 checks) and resleeve is idempotent on kovacs across three consecutive runs.

**What the decoupling was worth.** Running one sleeve on a case-sensitive filesystem found three defects that APFS case folding and a shared working tree had both hidden, all the same shape -- _a check that passes because it asks a question that stopped matching reality_:

- Link checks tested `[[ -L ]]`, which a dangling symlink satisfies, so a sleeve with no `.zshrc`, no git identity and no Doom config reported "Sleeve ready. Welcome back." (`568e620`)
- Rendered configs were compared by mtime, which git restamps and which differs across filesystems, so template changes never reached the machine (`9f28dce`)
- `doctor` could not see a stack running out of another machine's checkout, because the coupling is structural rather than textual (check 11)

Worth keeping one sleeve on a case-sensitive filesystem permanently for exactly this reason.

## Active Steel Threads

- **ST0001: Bootstrap -- COMPLETED 2026-09-08**, six months after it opened. 15/15 work packages, 7/7 acceptance criteria. Both "open" packages turned out to be largely already built, which is the thing worth remembering: a `Not Started` status records what someone last typed, not what exists.
  - WP-07 was HALF met. `molt upgrade` exists, runs identically on the kovacs VM sleeve and both Macs, and is idempotent across consecutive dry-runs. But there is no VM build spec, no one-command build, and the v0.1.1 release carries zero assets. Closing it whole would have been false, so it was split: the self-upgrading half is AC002-004 here with evidence; the VM-build half is now **ST0003**, at Triage with its own unsatisfied 3-row contract.
  - WP-04's deliverable existed since 16 June and was three months stale -- it asserted alacritty was a symlink at JetBrainsMono 14pt when it is a rendered template at MesloLGS 11. Brought current, and it now names the 12 of 23 liberators it does NOT cover rather than implying completeness.
- ST0003: Reproducible VM build and release artifact -- Triage. Carries what WP-07 never delivered.
- ST0002: Proper per-instance config of per-instance variables -- Completed 2026-03-23.

## Upcoming Work

Opened by this session, all verified on at least one sleeve:

- **Sidecars record a case-folded path.** Every `.molt-rendered` names its template as `.../molt-matts/...` lowercase, the path molt resolved through case folding. Informational while the digest recomputes the path from its `source` argument, but it is on-disk state that survives a rename and would then resolve only on a case-insensitive filesystem.
- **The `intent` liberator's model breaks when Intent arrives via brew.** Intent is 3.0.0 on rhadamanth and 2.6.0 on gyges and kovacs; the v2 -> v3 upgrade there is deliberately deferred and will come from brew rather than a source build. The liberator assumes a source checkout: it finds `${MOLT_INTENT_HOME}/bin/intent` and symlinks it into `~/bin`. A brew install lands at `/opt/homebrew/bin/intent`, which sits at PATH position 2 and therefore wins over both `~/.local/bin` (18) and `~/bin` (20). The liberator needs rewriting rather than patching -- its whole model is "find a checkout, link its dispatcher", and a brew-installed tool has no checkout to find. Not scheduled; hv's call, and explicitly not now. `intent_check` no longer _reports ok_ about this (see below), but reporting honestly is not the same as fixing it. When it happens, `~/bin/intent` should go so there is one source of truth.
- **Decide whether `desktop` should own more of GNOME than it does.** It now manages the GTK stylesheet (3.0 and 4.0) and dock favourites. What it still hardcodes is its gsettings block; the same instance-scoped-file argument applies there if it grows.

Resolved 8 Sep, listed so they are not re-opened:

- ~~Decide what to do with `MOLT_FONT_FAMILY` / `MOLT_FONT_SIZE`.~~ Wired, not deleted. `alacritty.toml` is now a template and the font comes from the instance's `vars.sh`, so the declared value is the effective one. Values corrected to what each sleeve actually runs -- and kovacs turned out to have them declared TWICE and already diverged (`vars.sh` said JetBrainsMono 14, the config said MesloLGS 11, and the config was right). The render is byte-identical to what kovacs ran before.
- ~~Decide whether molt should manage fonts at all.~~ A check, not an installer. `molt doctor` check 13 asserts the declared font is one fontconfig can resolve, which turns a silent fallback into a named failure without touching font licensing or redistribution. Build the installer later if provisioning frequency justifies it.
- ~~Decide whether gyges should have key access to rhadamanth.~~ **It already had it.** `26ff1ef` closed this on 4 Sep and the note was never retired. Verified live: `gyges -> rhadamanth` returns `KEY_AUTH_OK`, and gyges's `personalid`, rhadamanth's `personalid` and the key in rhadamanth's `authorized_keys` are one and the same ed25519 key. Nothing was written to `authorized_keys`.
- ~~gyges has a branch awaiting review.~~ **Merged**, at `048d06f`. Also never retired.
- ~~ProxyJump to kovacs from gyges.~~ Not a key problem and correctly deferred. kovacs, `kovacs.lan` and `kovacs.local` resolve from nowhere, `10.211.55.3` answers neither ping nor 22, and the Parallels ARP entry has now gone entirely. Molt-matts' `instances/gyges/ssh/config.d/lan-hosts.conf` documents this and says a ProxyJump block is right once kovacs is reachable. Adding one now is what that comment warns against.

**Three of the six carried decisions were already resolved and the list did not know it.** They were overtaken during 04-07 Sep, the same week nobody was folding the whiteboard. A carried-decision list is not self-cleaning: verify each against as-built before ruling on it.

Resolved 4 Sep, listed so they are not re-opened:

- ~~Normalise repo directory case.~~ `constants.sh`, all three live instance manifests and every project directory are on the capitalised convention. `molt new-user` now scaffolds `Molt-{user}` to match. The GitHub repo name stays lowercase (`matthewsinclair/molt-matts`) -- the two conventions differ deliberately and `newuser.sh` carries a comment saying so.
- ~~`user_repo` is dead documentation.~~ It cannot be consumed -- you must already know the repo to find the manifest inside it -- so doctor check 4 now asserts it matches the real directory name instead.
- ~~Remote naming is inconsistent across sleeves.~~ Not a defect: `molt upgrade` resolves via `@{upstream}` and warns when there is none; nothing in the codebase assumes `origin` exists. rhadamanth's `local`/`upstream` and gyges's `origin` both work. `newuser.sh` prints `origin` in its next-steps text, which is correct for a fresh repo.
- ~~`~/.claude/keybindings.json` has no owner.~~ New `claude` liberator owns it, enabled on all three sleeves. It manages that file only -- the rest of `~/.claude` is machine-local state and must not be linked into a shared repo.
- ~~`desktop` links gtk-3.0 only.~~ Links both, and `desktop_verify` now checks them, which it never did.
- ~~`molt doctor` should warn on `core.ignorecase`.~~ Check 12.
- ~~`intent_check` reports ok about a link it does not govern.~~ `molt_link_points_to` distinguishes "resolves" from "resolves to what we installed"; the check now warns on the drift and on a PATH shadow, without repairing a link something else placed.

Carried, not this project's to fix:

- Devbin's `README.md:60` snippet still carries both defects fixed in `a4e6cb2`; the `dvb` body now lives in three places and has diverged; `devbin doctor` reports surviving retired aliases but nothing reports a MISSING replacement. All three are devbin-vc's pen.
- `molt-matts` is an Intent project with zero steel threads, and work keeps landing there untracked. Opening its first thread is hv's call.

Carried from March, unverified from this sleeve -- confirm before acting:

- Tune iTerm2 SSH background colors after seeing them in practice
- Check rhadamanth's actual default background color (reset currently uses 000000)
- Persist GNOME Terminal Super bindings in the gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth

## Notes

Three sleeves: rhadamanth and gyges on macOS, kovacs on Ubuntu in Parallels. `molt upgrade` = fast config sync (daily); `molt maintain` = heavy system maintenance (weekly/monthly). `envsubst` only substitutes `MOLT_*` variables. `VERSION` is the single source of truth for the version number.

Configs are re-rendered when a content digest of (template + `instances/<host>/vars.sh`) no longer matches the one recorded in the `.molt-rendered` sidecar. It is not an mtime comparison: git restamps files whose content never changed, and across two filesystems mtime produces false negatives, which is the silent direction. Installs predating `9f28dce` carry no digest, so every rendered config re-renders once on first resleeve -- four of them on gyges, including the launch agent plist, whose re-render reloads `com.matts.backup-mount`.

The `backup` liberator never touches the disk image. SuperDuper creates, attaches and detaches its own sparsebundle; anything that competes for the image can permanently break the job's destination binding. The liberator's only job is the SMB share.
