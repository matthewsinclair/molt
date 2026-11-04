# CI Workflows

## Workflows

### tests.yml: the test workflow

Runs on a push to `main` or to a release candidate (`candidate/**`, which devbin's release core pushes before it tags), a release tag (`v[0-9]*` or `[0-9]*`), a pull request to `main`, and on demand (`gh workflow run tests.yml --ref main`). A push that changes only `intent/whiteboard/` and `intent/.canon/` starts no run, and a newer run for the same event and ref cancels an older one.

| Job          | Runner        | Runs                            | What it does                                                                                         |
| ------------ | ------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------- |
| test-linux   | ubuntu-latest | every run                       | Installs bats-core 1.12.0 from source, and zsh, then runs `bats test/*.bats test/liberators/*.bats`  |
| test-macos   | macos-latest  | on a candidate, a tag or demand | Installs bats-core with Homebrew, then runs the same suite                                           |
| shellcheck   | ubuntu-latest | every run                       | Runs `shellcheck -x` over `bin/molt`, `lib/*.sh` and `liberators/*.sh`; any finding fails the job    |
| test-summary | ubuntu-latest | unless the run is cancelled     | Fails unless test-linux passed, and test-macos passed where the run required it or skipped where not |

### pr-checks.yml: pull request checks

Runs when a pull request is opened, synchronised or reopened. Every job only prints warnings.

| Job                  | What it does                                                             |
| -------------------- | ------------------------------------------------------------------------ |
| check-documentation  | Warns when `bin/`, `lib/` or `liberators/` changed and no `.md` file did |
| commit-message-check | Warns on a commit subject shorter than 10 or longer than 72 characters   |
| pr-size-check        | Notes a pull request over 500 changed lines, and warns over 1000         |

## Badge

```markdown
[![Molt Tests](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml)
```

## Running Tests Locally

From the dev checkout:

```bash
bin/molt test                             # ShellCheck, then every test
bin/molt test zsh                         # ShellCheck, then one liberator's tests
PATH=/bin:$PATH bin/molt test             # the same under macOS's /bin/bash 3.2
bin/devbin test all                       # both, as every release's gates run them
bats test/*.bats test/liberators/*.bats   # bats directly, without ShellCheck
```

## Troubleshooting

- **bats not found**: `brew install bats-core` on macOS, or install it from source on Linux.
- **ShellCheck findings**: the shellcheck job fails on any, and `molt test` runs no tests until ShellCheck is clean. `shellcheck -x bin/molt lib/*.sh liberators/*.sh` lists them.
- **A failure on one platform only**: check the liberator's platform-specific code, and run the suite under `/bin/bash` 3.2 as well, since CI's macOS leg runs only on a release candidate or tag, or on demand.
