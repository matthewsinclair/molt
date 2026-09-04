---
verblock: "04 Sep 2026:v0.15: Matthew Sinclair - kovacs decoupled and published; nothing in flight"
---

# Work In Progress

## Current Focus

**Nothing in flight.** The kovacs decoupling is complete and everything from this session is on `upstream/main` (Molt `6f94807`, Molt-matts `d7d1e66`).

kovacs now has its own clones on local ext4 with conventional names (`Molt`, `Molt-matts`, `Utilz`); nothing of rhadamanth's tree reaches it except `~/mac`, browse-only. All three sleeves report doctor green (11 checks) and resleeve is idempotent on kovacs across three consecutive runs.

**What the decoupling was worth.** Running one sleeve on a case-sensitive filesystem found three defects that APFS case folding and a shared working tree had both hidden, all the same shape -- _a check that passes because it asks a question that stopped matching reality_:

- Link checks tested `[[ -L ]]`, which a dangling symlink satisfies, so a sleeve with no `.zshrc`, no git identity and no Doom config reported "Sleeve ready. Welcome back." (`568e620`)
- Rendered configs were compared by mtime, which git restamps and which differs across filesystems, so template changes never reached the machine (`9f28dce`)
- `doctor` could not see a stack running out of another machine's checkout, because the coupling is structural rather than textual (check 11)

Worth keeping one sleeve on a case-sensitive filesystem permanently for exactly this reason.

## Active Steel Threads

- ST0001: Bootstrap -- WIP. WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are open; the other eleven are done.
- ST0002: Proper per-instance config of per-instance variables -- Completed 2026-03-23.

## Upcoming Work

Opened by this session, all verified on at least one sleeve:

- **`molt new-user` scaffolds against the wrong case convention.** `constants.sh` now searches `Molt-$(whoami)` first with a lowercase fallback, all three live instances declare `user_repo = "Molt-matts"`, and every sibling project directory is capitalised (`Molt-flynn`, `Pplr`, `Utilz`). But `lib/newuser.sh:125` still creates `${MOLT_PRJ_DIR}/molt-${user}` and `templates/molt-user/instances/__MOLT_HOSTNAME__/molt.toml` still writes `user_repo = "molt-__MOLT_USER__"`, both lowercase. A repo scaffolded today resolves only through the lowercase fallback -- it works, but by luck, which is the shape of every bug this session found. Note `user_repo` in `molt.toml` is never actually read by anything; it is documentary, and either it should be consumed or it should go.
- **Sidecars record a case-folded path.** Every `.molt-rendered` names its template as `.../molt-matts/...` lowercase, the path molt resolved through case folding. Informational while the digest recomputes the path from its `source` argument, but it is on-disk state that survives a rename and would then resolve only on a case-insensitive filesystem.
- **Remote naming is inconsistent across sleeves.** rhadamanth has `local` + `upstream` and no `origin`; gyges has `origin` only; `lib/newuser.sh:139` scaffolds new user repos with `origin`. `molt upgrade` resolves via `@{upstream}` so all three work, but assuming `origin` exists silently returns a false "0 behind" -- which cost kovacs a wrong answer this morning. Pick one and make `newuser.sh` agree.
- **The `intent` liberator's model breaks when Intent arrives via brew.** Intent is 3.0.0 on rhadamanth and 2.6.0 on gyges and kovacs; the v2 -> v3 upgrade there is deliberately deferred and will come from brew rather than a source build. The liberator assumes a source checkout: it finds `${MOLT_INTENT_HOME}/bin/intent` and symlinks it into `~/bin`. A brew install lands at `/opt/homebrew/bin/intent`, which sits at PATH position 2 and therefore wins over both `~/.local/bin` (18) and `~/bin` (20) — so brew's binary would silently take over while the liberator carried on managing a symlink into a source tree. The liberator needs rewriting rather than patching — its whole model is "find a checkout, link its dispatcher", and a brew-installed tool has no checkout to find. Not scheduled; hv's call, and explicitly not now. When it happens, `~/bin/intent` should go so there is one source of truth.
- **rhadamanth already shows that drift.** `~/bin/intent` points at `Intent/native/rust/target/release/intent`, which is not what `intent_install` creates (`$repo/bin/intent`, still present and still linked on gyges), and PATH resolves via `~/.local/bin/intent` regardless. Both are 3.0.0 so nothing misbehaves, and the liberator reports ok — about a thing it is not actually governing. Same shape as the render staleness: the check passes because it asks a question that stopped matching reality.
- **Decide who owns `~/.claude/keybindings.json`.** It lives in `config/claude/keybindings.json` in the user repo and was hand-linked on kovacs — no liberator creates it. Removing it during the dangling-link repair meant nothing recreated it, and on a fresh sleeve it would simply never exist. Either a liberator owns it or it stops living in the repo; a config that is version-controlled but unmanaged is the worst of both.
- **Decide whether `desktop` should manage `~/.config/gtk-4.0/gtk.css`.** It links gtk-3.0 only. kovacs had a gtk-4.0 link that molt never created and therefore never repaired. Not a bug in the liberator, but GTK4 apps are now the common case.
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
