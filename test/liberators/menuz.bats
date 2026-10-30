#!/usr/bin/env bats
# menuz.bats — Tests for the menuz liberator: ~/.config/menuz linked whole, so
# a menu an editor replaces on save stays in the repo, on macOS only (issue
# 0074).

load "../test_helper.bash"

_menuz_env() {
    load_liberator menuz
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    MENUZ_REPO="$root/repo"
    mkdir -p "$HOME" "$MENUZ_REPO/config/menuz/bin"
    printf 'items: []\n' > "$MENUZ_REPO/config/menuz/menuz.yaml"
    MOLT_USER_REPO_SEARCH_PATHS=("$MENUZ_REPO")
    molt_platform() { echo "macos"; }
}

@test "menuz_check flags ~/.config/menuz before install" {
    _menuz_env
    run menuz_check
    assert_failure
    assert_output_contains "menuz: ~/.config/menuz is missing"
}

@test "menuz_install links the directory, then check and verify pass" {
    _menuz_env
    run menuz_install
    assert_success
    [ "$(readlink "$HOME/.config/menuz")" = "$MENUZ_REPO/config/menuz" ]
    [ -d "$HOME/.config/menuz/bin" ]
    run menuz_check
    assert_success
    run menuz_verify
    assert_success
}

# An editor that saves by writing a new file and renaming it over the old one.
@test "a menu replaced on save after install stays in the repo" {
    _menuz_env
    menuz_install
    printf 'items: [new]\n' > "$HOME/.config/menuz/menuz.yaml.tmp"
    mv "$HOME/.config/menuz/menuz.yaml.tmp" "$HOME/.config/menuz/menuz.yaml"
    [ "$(cat "$MENUZ_REPO/config/menuz/menuz.yaml")" = "items: [new]" ]
}

@test "menuz_install backs up a plain ~/.config/menuz with its menu" {
    _menuz_env
    mkdir -p "$HOME/.config/menuz"
    printf 'old\n' > "$HOME/.config/menuz/menuz.yaml"
    run menuz_install
    assert_success
    [ -L "$HOME/.config/menuz" ]
    [ "$(cat "$HOME"/.config/menuz.molt-backup.*/menuz.yaml)" = "old" ]
}

@test "menuz does nothing on Linux" {
    _menuz_env
    molt_platform() { echo "linux"; }
    run menuz_check
    assert_success
    run menuz_install
    assert_success
    [ ! -e "$HOME/.config/menuz" ]
}
