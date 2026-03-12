# CI/CD Workflows

## Workflows

### tests.yml — Main Test Workflow

Runs on push to `main` and all PRs targeting `main`.

| Job          | Runner        | What it does                                     |
| ------------ | ------------- | ------------------------------------------------ |
| test-linux   | ubuntu-latest | Install bats from source, run all `.bats` tests  |
| test-macos   | macos-latest  | Install bats via brew, run all `.bats` tests     |
| shellcheck   | ubuntu-latest | Non-blocking ShellCheck on all shell scripts     |
| test-summary | ubuntu-latest | Aggregate results, fail if either platform fails |

### pr-checks.yml — PR Validation

Runs on PR opened, synchronize, or reopened.

| Job                  | What it does                                 |
| -------------------- | -------------------------------------------- |
| check-documentation  | Warn if scripts changed without docs updates |
| commit-message-check | Validate commit message length               |
| pr-size-check        | Warn on large PRs (>500 lines)               |

## Badge

```markdown
[![Molt Tests](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml)
```

## Running Tests Locally

```bash
molt test                    # All tests
molt test zsh                # Single liberator
bats test/*.bats             # Direct bats invocation
```

## Troubleshooting

- **bats not found**: Install via `brew install bats-core` (macOS) or from source (Linux)
- **ShellCheck issues**: Non-blocking in CI. Fix locally with `shellcheck bin/molt lib/*.sh`
- **Test failures on one platform only**: Check platform-specific code paths in liberators
