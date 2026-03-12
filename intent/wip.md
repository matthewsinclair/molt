---
verblock: "12 Mar 2026:v0.11: matts - docs, CI/CD, versioning, changelog, iTerm2 SSH colors"
---

# Work In Progress

## Current Focus

**013: Docs, CI/CD, versioning, and iTerm2 SSH colors (DONE)**

- VERSION file as single source of truth; `constants.sh` reads it with fallback
- CHANGELOG.md in Keep a Changelog format
- GitHub Actions: tests (Linux + macOS), ShellCheck, PR checks
- README: CI badge, upgrade --self, maintain, new liberators, lifecycle hooks, three sleeves
- getting-started.md: self-update, maintain, recommended workflow
- iTerm2 SSH background color wrapper (molt-matts): tints per host on SSH
- Tagged v0.1.0, fixed CI (git identity for test runners)
- 83 tests passing (19 liberators)

**012: molt upgrade --self (DONE)**

**011: Doom migration, upgrade scripts, hostname in prompt (DONE)**

**010: molt git + centralised git operations (DONE)**

**009: gyges resleeve + symbolic directory vocabulary (DONE)**

**008: Cmd key proper fix + per-app keybindings (DONE)**

**007: Phase 5 -- Upgrade, Emacs Keys, Tiling, VS Code (DONE)**

**006: Rhadamanth resleeve + chezmoi migration (DONE)**

**005: Make Molt Sleeveable (DONE)**

**004: Split terminal liberator into per-emulator liberators (DONE)**

**003: Bats test suite and CLI commands (DONE)**

**002: MOLT framework scaffolding (WP-05, DONE)**

## Active Steel Threads

- ST0001: Bootstrap -- Phase 1-6 COMPLETE

## Upcoming Work

- Verify CI passes on GitHub (just pushed, should be running now)
- Deploy starship template to gyges (pull + molt resleeve)
- Deploy starship template to kovacs (pull + molt resleeve)
- Fix git remote/tracking config on gyges (remotes named "upstream", missing fetch refspecs)
- Tune iTerm2 SSH background colors after seeing them in practice
- Check rhadamanth's actual default background color (reset currently uses 000000)
- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Run `molt resleeve` on kovacs (needs MOLT_PRJ_DIR in .zshenv)
- Reproducible VM build (WP-07, future)

## Notes

19 liberators (brew added), 83 tests passing. Three sleeves operational (kovacs, rhadamanth, gyges). `molt upgrade` = fast config sync (daily). `molt maintain` = heavy system maintenance (weekly/monthly). envsubst only substitutes `MOLT_*` variables. VERSION file is single source of truth for version number. CI/CD running on GitHub Actions. Tagged v0.1.0.
