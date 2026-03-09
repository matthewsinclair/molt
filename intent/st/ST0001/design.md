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

## Architecture (As-Built)

```
molt (framework repo)
├── bin/
│   └── molt            # CLI entry point — thin coordinator
├── lib/
│   ├── constants.sh    # All configurable paths (Highlander Rule)
│   ├── molt.sh         # Core: logging, platform, symlinks, commands
│   └── liberator.sh    # Liberator lifecycle: load/check/install/verify
├── liberators/         # 12 liberator modules (one per concern)
├── test/
│   ├── test_helper.bash  # Shared BATS infrastructure
│   ├── molt.bats         # CLI tests
│   ├── constants.bats    # Constants tests
│   ├── liberator.bats    # Framework tests
│   ├── manifest.bats     # Manifest parsing tests
│   └── liberators/
│       └── zsh.bats      # Exemplar liberator test
├── templates/          # Config templates (molt.toml.example)
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

### External dependencies: PATH-based, not package-manager-bound

Molt must never mandate a specific package manager or dev environment tool. No hard dependency on Homebrew, mise, asdf, nix, or any other provider.

**Principle**: Molt depends on _commands on PATH_, not on how they got there.

- When Molt needs a tool (eg `bats`, `prettier`, `jq`), it checks `command -v` on PATH
- If the tool is missing, Molt fails gracefully with a clear message telling the user what's needed
- It's the user's choice how to satisfy that dependency — brew, apt, mise, asdf, nix, cargo, manual install, whatever
- Liberators that install tools should be opinionated about _what_ to install, not _how_ — platform-appropriate package managers (apt on Ubuntu, etc.) are a sensible default, but the user can always disable the liberator and manage their own tooling
- Dev environment version managers (mise, asdf, nvm, rbenv, etc.) are user preference — Molt should be resilient to whichever one is in play, or none at all

**Rationale**: Devs are particular about their toolchain. Mandating brew (or anything) would be a deal-breaker for adoption. PATH is the universal interface.

### Secrets management: explicitly out of scope

MOLT manages config, not secrets. Secrets are per-instance by design.

- SSH keys are generated per-sleeve by the `ssh` liberator. The user manually adds the pubkey to GitHub/remotes. This is intentional — keys should be unique per machine.
- API tokens, credentials, `.env` files are unmanaged. Users bring their own secrets tooling.
- No 1Password, Bitwarden, `pass`, or other secrets provider integration in the framework.
- If this becomes a pain point, a provider-agnostic hooks approach (Option B) can be added as a `secrets` liberator without breaking anything.
- Users who want a secrets tool on their sleeve can write a personal liberator for it in their `molt-{user}` repo.

**Rationale**: Secrets are "reflexes you develop in each body," not memories you carry. A resleeve gives you your config (identity), but secrets are correctly local. The manual steps after resleeve (add pubkey, copy creds) are infrequent and intentionally human-gated.

## Alternatives Considered

### GNU Stow

- Considered for symlink management
- Decided to defer — manual symlinks are fine for now, can adopt Stow later if complexity grows

### Nix / Home Manager

- Too heavy for current needs
- MOLT should be simpler and more opinionated than Nix
