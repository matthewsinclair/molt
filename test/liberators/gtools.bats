#!/usr/bin/env bats
# gtools.bats — gtools liberator: Gtools from Homebrew's private tap, tapped
# over ssh, and a verdict that names the gtools that actually runs (issue 0057)
#
# brew is the shared stub (fake_brew_formula). Nothing here reaches the real
# Homebrew or the tap.

load "../test_helper.bash"

TAP="matthewsinclair/gtools"
TAP_URL="git@github.com:matthewsinclair/homebrew-gtools.git"
FORMULA="matthewsinclair/gtools/gtools"

# Homebrew's Gtools installed from its tap, linked and first on PATH. Each test
# then breaks one thing.
_fake_brew_gtools() {
    fake_brew_formula gtools 9.9.9 gtools
    echo "$TAP" > "$FAKE_PREFIX/taps"
}

# Gtools not installed, and its tap not tapped.
_fake_brew_no_gtools() {
    _fake_brew_gtools
    rm "$FAKE_PREFIX/.installed"
    : > "$FAKE_PREFIX/taps"
}

@test "gtools_check passes when Homebrew's gtools is what PATH runs" {
    _fake_brew_gtools
    load_liberator gtools
    run gtools_check
    assert_success
    assert_output_contains "gtools:9.9.9"
    run gtools_verify
    assert_success
}

@test "gtools_check FAILS, naming brew install, when Gtools is not installed" {
    _fake_brew_gtools
    rm "$FAKE_PREFIX/.installed"
    load_liberator gtools
    run gtools_check
    assert_failure
    assert_output_contains "run: brew install $FORMULA"
    run gtools_verify
    assert_failure
}

@test "gtools_check FAILS, naming the ssh tap command, when the tap is missing" {
    _fake_brew_no_gtools
    load_liberator gtools
    run gtools_check
    assert_failure
    assert_output_contains "run: brew tap $TAP $TAP_URL, then brew install $FORMULA"
}

@test "gtools_install taps the private tap over ssh, then installs" {
    _fake_brew_no_gtools
    load_liberator gtools
    run gtools_install
    assert_success
    [ "$(cat "$FAKE_LOG")" = "brew tap $TAP $TAP_URL
brew install $FORMULA" ]
}

@test "gtools_install does not tap again when the tap is there" {
    _fake_brew_gtools
    rm "$FAKE_PREFIX/.installed"
    load_liberator gtools
    run gtools_install
    assert_success
    [ "$(cat "$FAKE_LOG")" = "brew install $FORMULA" ]
}

@test "gtools_install FAILS, showing brew's reason, when the tap fails" {
    _fake_brew_no_gtools
    touch "$FAKE_PREFIX/.tap-fails"
    load_liberator gtools
    run gtools_install
    assert_failure
    assert_output_contains "Permission denied (publickey)"
    assert_output_contains "brew tap $TAP $TAP_URL failed"
    [ "$(cat "$FAKE_LOG")" = "brew tap $TAP $TAP_URL" ]
}

@test "gtools_check FAILS, naming it, when PATH runs another gtools" {
    _fake_brew_gtools
    mkdir -p "$BATS_TEST_TMPDIR/dev"
    printf '#!/bin/bash\necho "gtools 0.1.0 (dev)"\n' > "$BATS_TEST_TMPDIR/dev/gtools"
    chmod +x "$BATS_TEST_TMPDIR/dev/gtools"
    export PATH="$BATS_TEST_TMPDIR/dev:$PATH"
    load_liberator gtools
    run gtools_check
    assert_failure
    assert_output_contains "PATH runs $BATS_TEST_TMPDIR/dev/gtools (gtools 0.1.0 (dev))"
    run gtools_verify
    assert_failure
}

# --- source = "switch": dev, opt and brew all held, gtools use chooses (0073) ---

# The liberator loaded against a sleeve whose gtools entry carries the line $1.
_gtools_sleeve() {
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    mkdir -p "$repo/config"
    printf '[[liberator]]\nname = "gtools"\nenabled = true\n%s\n' "$1" > "$repo/molt.toml"
    load_liberator gtools
    MOLT_USER_REPO_SEARCH_PATHS=("$repo")
}

# A gtools for the tree $1 first on PATH, printing the version line A3 gives it.
_gtools_tree_first() {
    mkdir -p "$BATS_TEST_TMPDIR/$1"
    printf '#!/bin/bash\necho "gtools 0.8.2 (%s, 72d289f9a2f8)"\n' "$1" > "$BATS_TEST_TMPDIR/$1/gtools"
    chmod +x "$BATS_TEST_TMPDIR/$1/gtools"
    export PATH="$BATS_TEST_TMPDIR/$1:$PATH"
}

@test "under switch, a dev or an opt gtools first on PATH passes, named by its version line" {
    local tree
    _fake_brew_gtools
    _gtools_sleeve 'source = "switch"'
    # Each tree is put first on PATH in turn, ahead of the one before it.
    for tree in dev opt; do
        _gtools_tree_first "$tree"
        run gtools_check
        assert_success
        assert_output_contains "gtools: gtools 0.8.2 ($tree, 72d289f9a2f8) is what PATH runs"
        run gtools_verify
        assert_success
        assert_output_contains "Verified: gtools 0.8.2 ($tree, 72d289f9a2f8) is what PATH runs"
    done
}

@test "under switch, Homebrew's gtools first on PATH passes too" {
    _fake_brew_gtools
    _gtools_sleeve 'source = "switch"'
    run gtools_check
    assert_success
    assert_output_contains "gtools: gtools:9.9.9 is what PATH runs"
}

@test "under switch, a PATH that runs no gtools fails" {
    _fake_brew_gtools
    _gtools_sleeve 'source = "switch"'
    export PATH="$BATS_TEST_TMPDIR/stub:/usr/bin:/bin"
    run gtools_check
    assert_failure
    assert_output_contains "PATH runs no gtools; gtools use dev, opt or brew chooses the tree that does"
    run gtools_verify
    assert_failure
}

@test "under switch, a missing formula still fails, naming brew install, and install taps and installs" {
    _fake_brew_no_gtools
    _gtools_tree_first dev
    _gtools_sleeve 'source = "switch"'
    run gtools_check
    assert_failure
    assert_output_contains "run: brew tap $TAP $TAP_URL, then brew install $FORMULA"
    run gtools_install
    assert_success
    [ "$(cat "$FAKE_LOG")" = "brew tap $TAP $TAP_URL
brew install $FORMULA" ]
}

@test "a source that is neither brew nor switch fails check and installs nothing" {
    _fake_brew_no_gtools
    _gtools_sleeve 'source = "checkout"'
    run gtools_check
    assert_failure
    assert_output_contains 'source = "checkout" on its molt.toml entry is neither brew nor switch'
    run gtools_install
    assert_failure
    assert_output_contains "nothing installed"
    [ ! -s "$FAKE_LOG" ]
}
