#!/usr/bin/env bats
# cldr.bats — Tests for the cldr liberator: cldr from Homebrew, and its config
# directory linked whole from the user repo (issue 0080).
#
# brew is the shared stub (fake_brew_formula), and HOME and the user repo are in
# the test directory. Nothing here reaches the real Homebrew or ~/.config.

load "../test_helper.bash"

# Homebrew's cldr installed, linked and first on PATH, and a user repo with
# config/cldr. Each test then breaks one thing.
_cldr_env() {
    fake_brew_formula cldr 9.9.9 cldr
    load_liberator cldr
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    unset XDG_CONFIG_HOME
    CLDR_REPO="$root/repo"
    mkdir -p "$HOME" "$CLDR_REPO/config/cldr"
    printf '[journal]\n' > "$CLDR_REPO/config/cldr/config.toml"
    MOLT_USER_REPO_SEARCH_PATHS=("$CLDR_REPO")
}

@test "cldr_check flags ~/.config/cldr before install" {
    _cldr_env
    run cldr_check
    assert_failure
    assert_output_contains "cldr: ~/.config/cldr is missing"
}

@test "cldr_install links the directory, then check and verify pass" {
    _cldr_env
    run cldr_install
    assert_success
    [ "$(readlink "$HOME/.config/cldr")" = "$CLDR_REPO/config/cldr" ]
    run cldr_check
    assert_success
    assert_output_contains "cldr:9.9.9"
    run cldr_verify
    assert_success
}

@test "cldr_install installs the formula by its full name when it is missing" {
    _cldr_env
    rm "$FAKE_PREFIX/.installed"
    run cldr_check
    assert_failure
    assert_output_contains "not installed; run: brew install $MOLT_CLDR_FORMULA"
    run cldr_install
    assert_success
    grep -qx "brew install $MOLT_CLDR_FORMULA" "$FAKE_LOG"
}

@test "cldr_install trusts a cldr installed before the trust gate" {
    _cldr_env
    touch "$FAKE_PREFIX/.gate"
    run cldr_check
    assert_failure
    assert_output_contains "run: brew trust --formula $MOLT_CLDR_FORMULA"
    run cldr_install
    assert_success
    grep -qx "brew trust --formula $MOLT_CLDR_FORMULA" "$FAKE_LOG"
    run cldr_verify
    assert_success
}

@test "cldr links under an absolute XDG_CONFIG_HOME" {
    _cldr_env
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
    run cldr_install
    assert_success
    [ "$(readlink "$XDG_CONFIG_HOME/cldr")" = "$CLDR_REPO/config/cldr" ]
    [ ! -e "$HOME/.config/cldr" ]
}

@test "cldr ignores a relative XDG_CONFIG_HOME" {
    _cldr_env
    export XDG_CONFIG_HOME="relative/xdg"
    run cldr_install
    assert_success
    [ "$(readlink "$HOME/.config/cldr")" = "$CLDR_REPO/config/cldr" ]
}

# An editor that saves by writing a new file and renaming it over the old one.
@test "a config replaced on save after install stays in the repo" {
    _cldr_env
    cldr_install
    printf '[journal]\nroot = "x"\n' > "$HOME/.config/cldr/config.toml.tmp"
    mv "$HOME/.config/cldr/config.toml.tmp" "$HOME/.config/cldr/config.toml"
    grep -qx 'root = "x"' "$CLDR_REPO/config/cldr/config.toml"
}

@test "cldr_install backs up a plain ~/.config/cldr with its config" {
    _cldr_env
    mkdir -p "$HOME/.config/cldr"
    printf 'old\n' > "$HOME/.config/cldr/config.toml"
    run cldr_install
    assert_success
    [ -L "$HOME/.config/cldr" ]
    [ "$(cat "$HOME"/.config/cldr.molt-backup.*/config.toml)" = "old" ]
}

@test "cldr links nothing for a repo without its config" {
    _cldr_env
    rm -r "$CLDR_REPO/config/cldr"
    run cldr_check
    assert_success
    run cldr_install
    assert_success
    [ ! -e "$HOME/.config/cldr" ]
}
