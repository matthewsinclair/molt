---
verblock: "04 Sep 2026:v0.17: Matthew Sinclair - fragment staleness closed; font + fonts + authorized_keys decisions open"
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

- **Sidecars record a case-folded path.** Every `.molt-rendered` names its template as `.../molt-matts/...` lowercase, the path molt resolved through case folding. Informational while the digest recomputes the path from its `source` argument, but it is on-disk state that survives a rename and would then resolve only on a case-insensitive filesystem.
- **The `intent` liberator's model breaks when Intent arrives via brew.** Intent is 3.0.0 on rhadamanth and 2.6.0 on gyges and kovacs; the v2 -> v3 upgrade there is deliberately deferred and will come from brew rather than a source build. The liberator assumes a source checkout: it finds `${MOLT_INTENT_HOME}/bin/intent` and symlinks it into `~/bin`. A brew install lands at `/opt/homebrew/bin/intent`, which sits at PATH position 2 and therefore wins over both `~/.local/bin` (18) and `~/bin` (20). The liberator needs rewriting rather than patching -- its whole model is "find a checkout, link its dispatcher", and a brew-installed tool has no checkout to find. Not scheduled; hv's call, and explicitly not now. `intent_check` no longer _reports ok_ about this (see below), but reporting honestly is not the same as fixing it. When it happens, `~/bin/intent` should go so there is one source of truth.
- **Decide whether `desktop` should own more of GNOME than it does.** It now manages the GTK stylesheet (3.0 and 4.0) and dock favourites. What it still hardcodes is its gsettings block; the same instance-scoped-file argument applies there if it grows.

- **Decide what to do with `MOLT_FONT_FAMILY` / `MOLT_FONT_SIZE`.** Declared in all three instances' `vars.sh` and in the new-user scaffold; consumed by nothing (verified by grep across both repos -- every hit is docs, tests or changelog). They are also wrong: the scaffold documents the var as "a Nerd Font; the prompt glyphs need one" and both Macs set it to `Menlo`, which is not one. Nothing is broken today because iTerm2 carries its own real Nerd Font (`HackNFM-Regular 12`) set in its own prefs, and kovacs's alacritty reads the static file. The danger is prospective: the first template that interpolates the var silently breaks glyph rendering on both Macs, and it will look like a font bug rather than a stale var. Two honest options -- wire it to the iTerm2 profile so the declared value is the effective one, or delete it so nothing can later trust a value nobody maintains. gyges leans to deleting, on the grounds that an unused var that is wrong reads as authoritative; I agree. Fleet-wide `vars.sh` change, so hv's call.
- **Decide whether molt should manage fonts at all.** Nothing does. `config/alacritty/alacritty.toml` names a font family; on kovacs the JetBrainsMono and Meslo Nerd Font files sit loose in `~/.local/share/fonts`, hand-installed and owned by nothing. A fresh sleeve gets the config naming the font and none of the font. The failure is silent -- fontconfig falls back and the terminal opens fine, just without powerline or devicon glyphs and with no error anywhere. Same class as the dangling symlink: everything reports success, the result is wrong. Shape and licensing both need deciding before building a `fonts` liberator.
- **Decide whether gyges should have key access to rhadamanth.** gyges reaches `rhadamanth.lan` and its `personalid` is offered and rejected -- not in rhadamanth's `authorized_keys` -- so only password auth remains. This also blocks `ProxyJump` to kovacs from gyges. Granting it is a security decision about machine-to-machine access, not a config tidy-up, so it stays hv's.
- **gyges has a branch awaiting review.** `c137146` on `gyges-ssh-lan-hosts` in Molt-matts: an instance `ssh/config.d` fragment for the LAN hosts, deliberately off main.

Resolved this session, listed so they are not re-opened:

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
