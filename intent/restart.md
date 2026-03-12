# Session Restart Context

## Last Session: 12 Mar 2026

### What Was Done

- VERSION file + CHANGELOG.md + constants.sh reads from VERSION
- GitHub Actions CI/CD: tests.yml (Linux + macOS + ShellCheck), pr-checks.yml
- Fixed CI: git identity config needed for git.bats test runners
- README.md: CI badge, full CLI reference, liberator lifecycle with upgrade/maintain hooks, 4 new liberators, three sleeves
- getting-started.md: self-update, maintain, recommended workflow
- iTerm2 SSH background color wrapper in molt-matts (per-host tinting)
- Tagged v0.1.0, pushed both repos

### What's Next

- Verify CI passes (just pushed, should be running)
- Deploy starship template to gyges and kovacs (pull + resleeve)
- Fix gyges git remotes: named "upstream" with missing fetch refspecs
  - Fix: `git config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'`
- Tune iTerm2 SSH background colors after seeing them in practice
- Check rhadamanth's default bg color (reset currently uses 000000)
- Persist GNOME Terminal Super bindings in gnome-terminal liberator

### Key Context

- VERSION file at project root is single source of truth for version
- CI runs bats on both Linux and macOS; ShellCheck is non-blocking
- git.bats tests need git user identity (configured in CI workflow)
- iTerm2 SSH colors live in molt-matts (user config), not framework
- `molt upgrade` = config sync (fast, daily). `molt maintain` = system maintenance (slow, weekly)
- envsubst only substitutes `MOLT_*` variables -- safe for templates with app $vars
- doom upgrade uses --force to bypass Emacs y-or-n-p
- Starship template has powerline chars (U+E0B0, U+E0B6) -- don't use Write tool (strips them)
- 19 liberators, 83 tests, three sleeves (kovacs, rhadamanth, gyges)
