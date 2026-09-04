---
verblock: "04 Sep 2026:v0.14: Matthew Sinclair - kovacs decoupling in flight; digest-based staleness landed"
---

# Work In Progress

## Current Focus

**kovacs decoupling -- IN FLIGHT, blocked on push.** kovacs has no stack of its own: `~/Devel/prj` is a symlink to `/media/psf/Home/Devel/prj`, so it has been reading and writing rhadamanth's working tree over the Parallels mount -- same device and inode, one index and one HEAD shared between two machines and two agents. `molt doctor` reported 10/10 green throughout. The migration onto local clones is planned, reviewed and ACKed by both other sleeves; it does not start until the six commits below are on GitHub, because a stage cloned from a published state is the entire point and staging from rhadamanth's tree would pin the migration to the machine it is decoupling from.

**Six commits await push.** `1c980c6`, `53b75fc`, `7d1508b`, `9f28dce` (molt); `0e57e83`, `7ebf26f` (molt-{user}). Four of them can only be validated on kovacs: check 11 needs a sleeve that can actually fail it, the digest work and the marker fix need configs that are genuinely stale, and the `doom sync -u` fix needs an install that has already tripped the short-circuit.

## Active Steel Threads

- ST0001: Bootstrap -- WIP. WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are open; the other eleven are done.
- ST0002: Proper per-instance config of per-instance variables -- Completed 2026-03-23.

## Upcoming Work

Opened by this session, all verified on at least one sleeve:

- **Normalise repo directory case.** `constants.sh` searches `${MOLT_PRJ_DIR}/molt-$(whoami)` and every `molt.toml` declares `user_repo = "molt-matts"`, both lowercase, while the directory on both Macs is `Molt-matts`. It resolves only because APFS folds case; ext4 will not. `MOLT_PPLR_HOME` has the mirror-image fault -- `constants.sh` wants `Pplr`, gyges has `pplr` -- and the pplr liberator reports ok there for the same reason. Rename after kovacs lands, not during: it would invalidate the paths kovacs is cloning against.
- **Sidecars record a case-folded path.** Every `.molt-rendered` names its template as `.../molt-matts/...` lowercase, the path molt resolved through case folding. Informational while the digest recomputes the path from its `source` argument, but it is on-disk state that survives a rename and would then resolve only on a case-insensitive filesystem.
- **Remote naming is inconsistent across sleeves.** rhadamanth has `local` + `upstream` and no `origin`; gyges has `origin` only; `lib/newuser.sh:139` scaffolds new user repos with `origin`. `molt upgrade` resolves via `@{upstream}` so all three work, but assuming `origin` exists silently returns a false "0 behind" -- which cost kovacs a wrong answer this morning. Pick one and make `newuser.sh` agree.
- **The `intent` liberator's model breaks when Intent arrives via brew.** Intent is 3.0.0 on rhadamanth and 2.6.0 on gyges and kovacs; the v2 -> v3 upgrade there is deliberately deferred and will come from brew rather than a source build. The liberator assumes a source checkout: it finds `${MOLT_INTENT_HOME}/bin/intent` and symlinks it into `~/bin`. A brew install lands at `/opt/homebrew/bin/intent`, which sits at PATH position 2 and therefore wins over both `~/.local/bin` (18) and `~/bin` (20) — so brew's binary would silently take over while the liberator carried on managing a symlink into a source tree. The liberator needs rewriting rather than patching — its whole model is "find a checkout, link its dispatcher", and a brew-installed tool has no checkout to find. Not scheduled; hv's call, and explicitly not now. When it happens, `~/bin/intent` should go so there is one source of truth.
- **rhadamanth already shows that drift.** `~/bin/intent` points at `Intent/native/rust/target/release/intent`, which is not what `intent_install` creates (`$repo/bin/intent`, still present and still linked on gyges), and PATH resolves via `~/.local/bin/intent` regardless. Both are 3.0.0 so nothing misbehaves, and the liberator reports ok — about a thing it is not actually governing. Same shape as the render staleness: the check passes because it asks a question that stopped matching reality.
- **Decide whether `molt doctor` should warn on `core.ignorecase=true`.** Both Macs carry it; it is harmless while the authoritative copy is on APFS and a hazard the moment a case-sensitive host is authoritative.

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
