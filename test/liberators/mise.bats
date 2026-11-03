#!/usr/bin/env bats
# mise.bats — Tests for the mise liberator: mise on PATH, checked for and never
# installed, and off on every sleeve (issue 0082).
#
# PATH is built from stubs alone, so whether the machine has mise cannot decide
# a result.

load "../test_helper.bash"

# The mise liberator, and an empty directory of stubs to run with as PATH.
_mise_env() {
    load_liberator mise
    MISE_PATH="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$MISE_PATH"
}

@test "mise's check, install and verify fail without mise" {
    _mise_env
    PATH="$MISE_PATH" run mise_check
    assert_failure
    assert_output_contains "mise: not installed"
    PATH="$MISE_PATH" run mise_install
    assert_failure
    assert_output_contains "mise not found. Install it (https://mise.run) then re-run."
    PATH="$MISE_PATH" run mise_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: mise not installed"
}

@test "mise's check, install and verify pass with mise on PATH" {
    _mise_env
    printf '#!/bin/sh\nexit 0\n' > "$MISE_PATH/mise"
    chmod +x "$MISE_PATH/mise"
    PATH="$MISE_PATH" run mise_check
    assert_success
    PATH="$MISE_PATH" run mise_install
    assert_success
    assert_output_contains "Liberator complete: mise"
    PATH="$MISE_PATH" run mise_verify
    assert_success
}
