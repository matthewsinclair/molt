#!/usr/bin/env bats
# utilz.bats — utilz liberator: Utilz from a checkout or from Homebrew, as each
# sleeve declares, and a verdict that names the utilz that actually runs
#
# brew is a stub (fake_brew_formula), HOME is a sandbox and molt.toml is a test
# repo's, so nothing here reaches the real Homebrew, ~/bin or manifest.

load "../test_helper.bash"

# A sleeve whose molt.toml has a utilz entry carrying the line $1 (eg
# 'source = "brew"', or none), with the liberator loaded against it.
_utilz_sleeve() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_LOCAL_BIN="$HOME/bin"
    export UTILZ_HOME="$BATS_TEST_TMPDIR/Utilz"
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    mkdir -p "$HOME/bin" "$repo/config"
    printf '[[liberator]]\nname = "utilz"\nenabled = true\n%s\n' "${1:-}" > "$repo/molt.toml"
    load_liberator utilz
    MOLT_USER_REPO_SEARCH_PATHS=("$repo")
}

# A Utilz checkout at UTILZ_HOME, its dispatcher and one utility linked into
# ~/bin and first on PATH, the way a checkout install leaves them.
_utilz_checkout() {
    mkdir -p "$UTILZ_HOME/bin"
    printf '#!/bin/bash\n[[ "$1" == --version ]] && echo "utilz:dev"\n' > "$UTILZ_HOME/bin/utilz"
    chmod +x "$UTILZ_HOME/bin/utilz"
    ln -s utilz "$UTILZ_HOME/bin/cleanz"
    ln -s "$UTILZ_HOME/bin/utilz" "$HOME/bin/utilz"
    ln -s "$UTILZ_HOME/bin/cleanz" "$HOME/bin/cleanz"
    export PATH="$HOME/bin:$PATH"
}

@test "utilz takes its source from molt.toml: none is checkout, and an unknown one is refused by name" {
    # AT001 (ST0005 AC001).
    _utilz_sleeve
    run _utilz_source
    assert_success
    [ "$output" = "checkout" ]

    _utilz_sleeve 'source = "tarball"'
    run utilz_check
    assert_failure
    assert_output_contains 'source = "tarball"'
    run utilz_install
    assert_failure
    assert_output_contains "nothing installed"
}

@test "brew: utilz_check passes when Homebrew's utilz runs, and names a command that runs from elsewhere" {
    # AT002 (ST0005 AC002). kovacs, 20 Oct 2026: brew-only by hv's ruling, and the
    # check said "repo not found" over a working Homebrew install.
    _utilz_sleeve 'source = "brew"'
    fake_brew_formula utilz 9.9.9 utilz cleanz
    run utilz_check
    assert_success
    assert_output_contains "utilz:9.9.9 is what PATH runs"

    mkdir -p "$BATS_TEST_TMPDIR/shadow"
    printf '#!/bin/bash\n' > "$BATS_TEST_TMPDIR/shadow/cleanz"
    chmod +x "$BATS_TEST_TMPDIR/shadow/cleanz"
    export PATH="$BATS_TEST_TMPDIR/shadow:$PATH"
    run utilz_check
    assert_failure
    assert_output_contains "other than Homebrew's install, or not at all: cleanz"
    run utilz_verify
    assert_failure
}

@test "brew: utilz_install installs by full name and links nothing, and upgrade leaves it to brew" {
    # AT003 (ST0005 AC002).
    _utilz_sleeve 'source = "brew"'
    fake_brew_formula utilz 9.9.9 utilz cleanz
    rm "$FAKE_PREFIX/.installed"
    printf '#!/bin/bash\necho "git $*" >> "$FAKE_LOG"\n' > "$BATS_TEST_TMPDIR/stub/git"
    chmod +x "$BATS_TEST_TMPDIR/stub/git"
    run utilz_install
    assert_success
    grep -qx "brew install matthewsinclair/utilz/utilz" "$FAKE_LOG"
    [ ! -e "$HOME/bin/utilz" ] && [ ! -e "$HOME/bin/cleanz" ]
    run utilz_upgrade
    assert_success
    assert_output_contains "brew upgrade"
    run grep -q "^git" "$FAKE_LOG"
    assert_failure
}

@test "checkout: utilz_check passes when the checkout's utilz runs, and names Homebrew's when it runs instead" {
    # AT004 (ST0005 AC003). rhadamanth, 20 Oct 2026: Homebrew's utilz ran ahead of
    # the checkout's links, and the check said healthy because it asked only
    # whether its link resolved.
    _utilz_sleeve 'source = "checkout"'
    _utilz_checkout
    run utilz_check
    assert_success
    assert_output_contains "utilz:dev is what PATH runs"

    fake_brew_formula utilz 9.9.9 utilz cleanz
    run utilz_check
    assert_failure
    assert_output_contains "PATH runs $FAKE_PREFIX/bin/utilz (utilz:9.9.9), not the checkout's $UTILZ_HOME/bin/utilz"
    assert_output_contains "other than the checkout, or not at all: cleanz"
}

@test "a formula Homebrew does not trust is reported, and install trusts exactly that formula" {
    # AT005 (ST0005 AC004). Homebrew 7.0.10 leaves an installed formula from an
    # untrusted tap out of a plain brew upgrade, with a warning and exit 0.
    _utilz_sleeve 'source = "brew"'
    fake_brew_formula utilz 9.9.9 utilz cleanz
    touch "$FAKE_PREFIX/.gate"
    run utilz_check
    assert_failure
    assert_output_contains "does not trust matthewsinclair/utilz/utilz"
    run utilz_install
    assert_success
    grep -qx "brew trust --formula matthewsinclair/utilz/utilz" "$FAKE_LOG"
    run grep -q "^brew install" "$FAKE_LOG"
    assert_failure
    run utilz_check
    assert_success
}
