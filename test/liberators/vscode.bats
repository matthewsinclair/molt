#!/usr/bin/env bats
# vscode.bats — vscode liberator: the macOS 'code' CLI link (issue 0048)

load "../test_helper.bash"

# A macOS sleeve whose VS Code app is a fake, with 'code' not on PATH, and
# MOLT_LOCAL_BIN somewhere other than ~/bin.
_vscode_env() {
    load_liberator vscode
    molt_platform() { echo macos; }
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_LOCAL_BIN="$BATS_TEST_TMPDIR/local-bin"
    APP_BIN="$BATS_TEST_TMPDIR/app/bin/code"
    mkdir -p "${APP_BIN%/*}" "$BATS_TEST_TMPDIR/repo/config"
    printf '#!/bin/sh\nexit 0\n' > "$APP_BIN"
    chmod +x "$APP_BIN"
    _vscode_app_bin() { echo "$APP_BIN"; }
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/repo")
    export PATH="/bin:/usr/bin"
    if command -v code &>/dev/null; then
        skip "a 'code' in /bin or /usr/bin is on PATH, so install links nothing"
    fi
}

@test "install links the app's code CLI into MOLT_LOCAL_BIN, not ~/bin" {
    _vscode_env
    run vscode_install
    assert_success
    [ "$(readlink "$BATS_TEST_TMPDIR/local-bin/code")" = "$APP_BIN" ]
    [ ! -e "$BATS_TEST_TMPDIR/home/bin/code" ]
}

@test "install fails, naming the directory, when the link cannot be made" {
    _vscode_env
    : > "$BATS_TEST_TMPDIR/local-bin"
    run vscode_install
    assert_failure
    assert_output_contains "vscode: could not link 'code' into $BATS_TEST_TMPDIR/local-bin"
    refute_output_contains "Liberator complete"
}
