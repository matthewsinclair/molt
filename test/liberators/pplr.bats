#!/usr/bin/env bats
# pplr.bats — Tests for the pplr liberator: pplr from Homebrew, a tree of
# pplr's own that pplr use chose named and left as it is, and Molt's old link
# to a checkout's bin/pplr removed (issue 0086).
#
# brew is the shared stub (fake_brew_formula), and HOME, MOLT_LOCAL_BIN and the
# checkout are in the test directory. Nothing here reaches the real Homebrew or
# ~/.local/bin.

load "../test_helper.bash"

# The formula's full name, written here rather than read from the liberator,
# which is the code under test.
PPLR_FORMULA="matthewsinclair/pplr/pplr"

# Homebrew's pplr installed and linked, MOLT_LOCAL_BIN first on PATH as
# ~/.local/bin is on a sleeve, with no pplr in it, and a Pplr checkout of pplr
# 2.x, which has no bin/pplr. Each test then changes one thing.
_pplr_env() {
    fake_brew_formula pplr 9.9.9 pplr
    load_liberator pplr
    export MOLT_LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$MOLT_LOCAL_BIN"
    export PATH="$MOLT_LOCAL_BIN:$PATH"
    PPLR_CHECKOUT="$BATS_TEST_TMPDIR/Pplr"
    mkdir -p "$PPLR_CHECKOUT/.git"
}

# A pplr at $1 whose --version prints $2, as a build of one of its trees does.
_pplr_build() {
    mkdir -p "${1%/*}"
    printf '#!/bin/bash\n[[ "$1" == --version ]] && echo "%s"\n' "$2" > "$1"
    chmod +x "$1"
}

@test "pplr_check and pplr_verify pass when Homebrew's pplr is what PATH runs" {
    _pplr_env
    run pplr_check
    assert_success
    assert_output_contains "pplr: Homebrew's pplr:9.9.9 is what PATH runs"
    run pplr_verify
    assert_success
}

@test "pplr_install installs the formula by its full name when it is missing" {
    _pplr_env
    rm "$FAKE_PREFIX/.installed"
    run pplr_check
    assert_failure
    assert_output_contains "not installed; run: brew install $PPLR_FORMULA"
    run pplr_install
    assert_success
    grep -qx "brew install $PPLR_FORMULA" "$FAKE_LOG"
}

@test "pplr_install trusts a pplr installed before the trust gate" {
    _pplr_env
    touch "$FAKE_PREFIX/.gate"
    run pplr_check
    assert_failure
    assert_output_contains "run: brew trust --formula $PPLR_FORMULA"
    run pplr_install
    assert_success
    grep -qx "brew trust --formula $PPLR_FORMULA" "$FAKE_LOG"
    run pplr_verify
    assert_success
}

@test "Molt's old link to a 2.x checkout's bin/pplr, which is gone, is named, and pplr_install removes it" {
    _pplr_env
    ln -s "$PPLR_CHECKOUT/bin/pplr" "$MOLT_LOCAL_BIN/pplr"
    run pplr_check
    assert_failure
    assert_output_contains "pplr: ~/.local/bin/pplr is Molt's old link to a checkout's $PPLR_CHECKOUT/bin/pplr; install removes it"
    run pplr_install
    assert_success
    [ ! -L "$MOLT_LOCAL_BIN/pplr" ]
    run pplr_check
    assert_success
}

@test "Molt's old link to a 1.x checkout, which runs ahead of Homebrew's, is named, and pplr_install removes the link alone" {
    _pplr_env
    _pplr_build "$PPLR_CHECKOUT/bin/pplr" "1.0.1"
    ln -s "$PPLR_CHECKOUT/bin/pplr" "$MOLT_LOCAL_BIN/pplr"
    run pplr_check
    assert_failure
    assert_output_contains "PATH runs $MOLT_LOCAL_BIN/pplr (1.0.1), not Homebrew's"
    assert_output_contains "is Molt's old link to a checkout's $PPLR_CHECKOUT/bin/pplr"
    run pplr_install
    assert_success
    [ ! -L "$MOLT_LOCAL_BIN/pplr" ]
    [ -x "$PPLR_CHECKOUT/bin/pplr" ]
    run pplr_check
    assert_success
}

@test "a dev tree pplr use chose is named, not a fault, and pplr_install leaves its link" {
    _pplr_env
    _pplr_build "$PPLR_CHECKOUT/target/release/pplr" "pplr 9.9.9 (dev, 000000000000)"
    ln -s "$PPLR_CHECKOUT/target/release/pplr" "$MOLT_LOCAL_BIN/pplr"
    run pplr_check
    assert_success
    assert_output_contains "pplr: pplr 9.9.9 (dev, 000000000000) is what PATH runs"
    run pplr_verify
    assert_success
    run pplr_install
    assert_success
    [ "$(readlink "$MOLT_LOCAL_BIN/pplr")" = "$PPLR_CHECKOUT/target/release/pplr" ]
}

@test "an opt tree pplr use chose is named, not a fault, and never taken for the old link" {
    _pplr_env
    local opt="$BATS_TEST_TMPDIR/opt/pplr"
    _pplr_build "$opt/bin/pplr" "pplr 9.9.9 (opt, 000000000000)"
    ln -s "$opt/bin/pplr" "$MOLT_LOCAL_BIN/pplr"
    run pplr_check
    assert_success
    assert_output_contains "pplr: pplr 9.9.9 (opt, 000000000000) is what PATH runs"
    run pplr_install
    assert_success
    [ "$(readlink "$MOLT_LOCAL_BIN/pplr")" = "$opt/bin/pplr" ]
}

@test "with a tree of pplr's own on PATH, a Homebrew pplr not installed is still a fault" {
    _pplr_env
    _pplr_build "$PPLR_CHECKOUT/target/release/pplr" "pplr 9.9.9 (dev, 000000000000)"
    ln -s "$PPLR_CHECKOUT/target/release/pplr" "$MOLT_LOCAL_BIN/pplr"
    rm "$FAKE_PREFIX/.installed"
    run pplr_check
    assert_failure
    assert_output_contains "not installed; run: brew install $PPLR_FORMULA"
}

@test "a pplr ahead of Homebrew's that is none of pplr's own trees is a fault" {
    _pplr_env
    _pplr_build "$MOLT_LOCAL_BIN/pplr" "pplr 1.0.0"
    run pplr_check
    assert_failure
    assert_output_contains "PATH runs $MOLT_LOCAL_BIN/pplr (pplr 1.0.0), not Homebrew's"
}

@test "pplr has no upgrade hook and no repo, so molt upgrade and molt git leave a Pplr checkout alone" {
    load_liberator pplr
    [ -z "$(type -t pplr_upgrade)" ]
    [ -z "$(type -t pplr_repo)" ]
}
