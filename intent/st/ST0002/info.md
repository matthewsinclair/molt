---
verblock: "23 Mar 2026:v0.1: matts - Initial version"
intent_version: 2.4.0
status: WIP
slug: proper-per-instance-config-of-per-instance
created: 20260323
completed:
---

# ST0002: Proper per-instance config of per-instance variables

## Objective

Extract hardcoded host-specific configuration from shared liberator config files into instance-level configuration. Establish a general-purpose pattern for cross-instance aggregation so that any liberator can read data from all instances at resleeve time.

## Context

The file `Molt-matts/config/zsh/iterm2-ssh-colors.sh` has hardcoded hostnames and hex color mappings in a bash `case` statement. This is instance-specific data (each host's terminal background color) that was incorrectly placed in a shared zsh config file. Adding a new host requires editing a shared script rather than adding instance config.

The core challenge is that SSH colors are a _cross-instance_ concern: one machine needs a lookup table of ALL other machines' colors when SSH-ing to them. This differs from `vars.sh` (per-instance, build-time template substitution) and requires a new aggregation mechanism.

### Approach

1. **Data model**: Add `[terminal]` section to `instance.toml` with `ssh_bg_color` field
2. **Framework primitive**: Add `molt_instances_field()` to `lib/molt.sh` for cross-instance TOML field reads
3. **Generation**: zsh liberator generates `iterm2-ssh-colors.sh` at resleeve time from aggregated instance data
4. **Output**: Generated file goes to `~/.config/molt/iterm2-ssh-colors.sh`
5. **Stub instances**: Non-Molt hosts (shrike, yggdrasil) get minimal instance directories

### Key Design Decisions

- `instance.toml` over `vars.sh` for color data (machine identity metadata, not template variables)
- `~/.config/molt/` for generated runtime config (clean separation from source-controlled files)
- Framework owns the aggregation primitive (reusable for future cross-instance needs)
- `.lan` and `.local` hostname variants are auto-generated (convention, not per-host config)

## Related Steel Threads

- ST0001: Bootstrap (provides the framework, liberator system, and instance config infrastructure this builds on)
