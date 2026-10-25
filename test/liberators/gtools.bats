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
