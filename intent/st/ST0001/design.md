# Design - ST0001: Bootstrap

## Approach

Bootstrap follows a two-phase approach:

### Phase 1: Manual Resleeve (COMPLETE)

Hand-configure a new sleeve (kovacs) by installing packages, writing configs, and validating everything works. This establishes what the automated MOLT process will eventually need to handle. All config is captured in molt-matts/config/ as the single source of truth.

### Phase 2: Gaps and Foundation

Close remaining gaps from Phase 1 (Cmd key, SSH, fonts), then begin laying groundwork for MOLT automation by documenting what was done manually and identifying what can be templated/scripted.

## Design Decisions

### Two-repo split (molt + molt-matts)

- **molt**: Framework code, templates, tooling — shared, reusable
- **molt-matts**: Personal config + per-instance data — Matt-specific
- Rationale: Config is the soul (portable); binaries/compiled artifacts are per-instance. Other users would have their own molt-{userid} repo.

### Config as symlinks

- All dotfiles live in molt-matts/config/ and are symlinked into ~
- Rationale: Single source of truth (Highlander Rule), easy to diff/commit/push

### Per-instance overrides

- molt-matts/instances/{hostname}/ holds machine-specific config
- Rationale: Some things genuinely differ per machine (display scaling, hardware-specific keyd config, etc.)

### keyd for key remapping

- Built from source, runs as systemd service
- Maps Cmd (leftmeta) to a custom layer for CUA-style shortcuts
- Rationale: Works at evdev level, compositor-agnostic, survives Wayland

## Architecture

```
molt (framework repo)
├── templates/          # Config templates with variable substitution
├── scripts/            # Bootstrap and management scripts
└── docs/               # Framework documentation

molt-matts (personal repo)
├── config/             # Platform-agnostic dotfiles ("the soul")
│   ├── zsh/
│   ├── git/
│   ├── tmux/
│   ├── doom/
│   ├── alacritty/
│   ├── starship/
│   └── claude/
├── instances/
│   └── kovacs/         # Per-instance overrides and metadata
└── intent/             # Intent project artifacts
```

## Alternatives Considered

### GNU Stow

- Considered for symlink management
- Decided to defer — manual symlinks are fine for now, can adopt Stow later if complexity grows

### Nix / Home Manager

- Too heavy for current needs
- MOLT should be simpler and more opinionated than Nix
