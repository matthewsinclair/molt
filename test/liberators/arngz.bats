#!/usr/bin/env bats
# arngz.bats — Tests for the arngz liberator: ~/.config/arngz linked whole, so
# desks arngz discover saves land in the repo, on macOS only (issue 0074).

load "../test_helper.bash"

_arngz_env() {
    load_liberator arngz
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    ARNGZ_REPO="$root/repo"
    mkdir -p "$HOME" "$ARNGZ_REPO/config/arngz/desks"
    printf 'name: rhad\n' > "$ARNGZ_REPO/config/arngz/desks/rhad.yaml"
    MOLT_USER_REPO_SEARCH_PATHS=("$ARNGZ_REPO")
    molt_platform() { echo "macos"; }
}

@test "arngz_check flags ~/.config/arngz before install" {
    _arngz_env
    run arngz_check
    assert_failure
    assert_output_contains "arngz: ~/.config/arngz is missing"
}

@test "arngz_install links the directory, then check and verify pass" {
    _arngz_env
    run arngz_install
    assert_success
    [ "$(readlink "$HOME/.config/arngz")" = "$ARNGZ_REPO/config/arngz" ]
    run arngz_check
    assert_success
    run arngz_verify
    assert_success
}

@test "a desk saved after install lands in the repo" {
    _arngz_env
    arngz_install
    printf 'name: new\n' > "$HOME/.config/arngz/desks/new.yaml"
    [ "$(cat "$ARNGZ_REPO/config/arngz/desks/new.yaml")" = "name: new" ]
}

@test "arngz_install backs up a plain ~/.config/arngz with its desks" {
    _arngz_env
    mkdir -p "$HOME/.config/arngz/desks"
    printf 'old\n' > "$HOME/.config/arngz/desks/old.yaml"
    run arngz_install
    assert_success
    [ -L "$HOME/.config/arngz" ]
    [ "$(cat "$HOME"/.config/arngz.molt-backup.*/desks/old.yaml)" = "old" ]
}

@test "arngz_verify fails when the link points elsewhere" {
    _arngz_env
    mkdir -p "$BATS_TEST_TMPDIR/other" "$HOME/.config"
    ln -s "$BATS_TEST_TMPDIR/other" "$HOME/.config/arngz"
    run arngz_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.config/arngz points at $BATS_TEST_TMPDIR/other"
}

@test "arngz links nothing for a repo without its config" {
    _arngz_env
    rm -r "$ARNGZ_REPO/config/arngz"
    run arngz_check
    assert_success
    run arngz_install
    assert_success
    [ ! -e "$HOME/.config/arngz" ]
}

@test "arngz does nothing on Linux" {
    _arngz_env
    molt_platform() { echo "linux"; }
    run arngz_check
    assert_success
    run arngz_install
    assert_success
    [ ! -e "$HOME/.config/arngz" ]
}
