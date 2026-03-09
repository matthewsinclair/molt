---
verblock: "09 Mar 2026:v0.1: matts - Initial version"
wp_id: WP-08
title: "Template system implementation"
scope: Medium
status: Done
---

# WP-08: Template system implementation

## Objective

Implement the template rendering system designed in `intent/st/ST0001/design-templates.md`. This fills the gap between static symlinks (identical across sleeves) and full instance overrides (completely different per machine) for config files that are mostly the same but need a few per-instance values.

## Design Reference

See `intent/st/ST0001/design-templates.md` for full design. Key points:

- `envsubst` with `.tmpl` files — bash-native, no external deps
- Variables from `instances/{hostname}/vars.sh`
- `molt_render` renders template to target file
- `molt_install_config` auto-picks symlink vs render
- SSH config is the first template candidate (concatenation approach with `config.d/` fragments)

## Deliverables

1. `molt_render` function in `lib/molt.sh`
2. `molt_install_config` helper in `lib/molt.sh`
3. Bats tests for template rendering
4. `instances/kovacs/vars.sh` and `instances/rhadamanth/vars.sh` in molt-matts
5. SSH config converted to `.tmpl` + ssh liberator updated
6. `molt doctor` awareness of rendered files (`.molt-rendered` markers)
7. `molt doctor` diagnostic checks for secrets presence (SSH key, GitHub auth)

## Acceptance Criteria

- [ ] `molt_render` renders templates with envsubst, sources vars.sh
- [ ] `molt_install_config` picks symlink for static files, render for `.tmpl` files
- [ ] SSH config renders correctly on both kovacs and rhadamanth
- [ ] SSH liberator uses concatenation approach (template + config.d fragments)
- [ ] Bats tests cover: basic render, missing template, missing vars.sh fallback, idempotent re-render
- [ ] `molt doctor` reports rendered files and secrets presence
- [ ] Existing liberators and tests unaffected (no regressions)

## Dependencies

- WP-05 (Framework scaffolding) — framework must exist
- WP-06 (Highlander audit) — design follows audit principles

## Notes

- Font config templates (alacritty.toml, doom config.el) are a second-wave candidate after SSH proves the pattern
- Secrets boundary decision: MOLT manages config, not secrets (Option A) — doctor checks are diagnostic only
