#!/usr/bin/env bats
# hammerspoon.bats — Tests for the hammerspoon liberator: ~/.hammerspoon/init.lua
# linked as a file, Spoons/ left alone, on macOS only (issue 0074).

load "../test_helper.bash"

_hs_env() {
    load_liberator hammerspoon
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    HS_REPO="$root/repo"
    mkdir -p "$HOME" "$HS_REPO/config/hammerspoon"
    printf 'hs.ipc.cliInstall()\n' > "$HS_REPO/config/hammerspoon/init.lua"
    MOLT_USER_REPO_SEARCH_PATHS=("$HS_REPO")
    molt_platform() { echo "macos"; }
}

@test "hammerspoon_check flags init.lua before install" {
    _hs_env
    run hammerspoon_check
    assert_failure
    assert_output_contains "hammerspoon: ~/.hammerspoon/init.lua is missing"
}

@test "hammerspoon_install links init.lua as a file, then check and verify pass" {
    _hs_env
    run hammerspoon_install
    assert_success
    [ "$(readlink "$HOME/.hammerspoon/init.lua")" = "$HS_REPO/config/hammerspoon/init.lua" ]
    [ ! -L "$HOME/.hammerspoon" ]
    run hammerspoon_check
    assert_success
    run hammerspoon_verify
    assert_success
}

@test "hammerspoon_install backs up a plain init.lua and leaves Spoons alone" {
    _hs_env
    mkdir -p "$HOME/.hammerspoon/Spoons/Some.spoon"
    printf 'old\n' > "$HOME/.hammerspoon/init.lua"
    run hammerspoon_install
    assert_success
    [ -L "$HOME/.hammerspoon/init.lua" ]
    [ "$(cat "$HOME"/.hammerspoon/init.lua.molt-backup.*)" = "old" ]
    [ -d "$HOME/.hammerspoon/Spoons/Some.spoon" ]
}

@test "hammerspoon_verify fails when init.lua is a plain file" {
    _hs_env
    mkdir -p "$HOME/.hammerspoon"
    printf 'plain\n' > "$HOME/.hammerspoon/init.lua"
    run hammerspoon_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.hammerspoon/init.lua is not a symlink"
}

@test "hammerspoon links nothing for a repo without its config" {
    _hs_env
    rm -r "$HS_REPO/config/hammerspoon"
    run hammerspoon_check
    assert_success
    run hammerspoon_install
    assert_success
    [ ! -e "$HOME/.hammerspoon" ]
}

@test "hammerspoon does nothing on Linux" {
    _hs_env
    molt_platform() { echo "linux"; }
    run hammerspoon_check
    assert_success
    run hammerspoon_install
    assert_success
    [ ! -e "$HOME/.hammerspoon" ]
}
