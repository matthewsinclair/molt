#!/usr/bin/env bats
# dev-tools.bats — Tests for the dev-tools liberator: jq, tree, rg, fzf and curl
# on PATH, and no mise needed since mise became its own liberator (issue 0082).
#
# PATH is built from stubs alone, so what the machine has installed, mise
# included, cannot decide a result.

load "../test_helper.bash"

# A directory of stubs, one for each of $@, for a test to run with as its PATH.
_dt_stubs() {
    local cmd
    DT_PATH="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$DT_PATH"
    for cmd in "$@"; do
        printf '#!/bin/sh\nexit 0\n' > "$DT_PATH/$cmd"
        chmod +x "$DT_PATH/$cmd"
    done
}

@test "dev-tools passes with its five tools and no mise" {
    load_liberator dev-tools
    _dt_stubs jq tree rg fzf curl
    PATH="$DT_PATH" run dev-tools_check
    assert_success
    refute_output_contains "mise"
    PATH="$DT_PATH" run dev-tools_install
    assert_success
    refute_output_contains "mise"
    PATH="$DT_PATH" run dev-tools_verify
    assert_success
    refute_output_contains "mise"
}

@test "dev-tools fails naming a tool PATH does not have" {
    load_liberator dev-tools
    _dt_stubs jq tree fzf curl
    PATH="$DT_PATH" run dev-tools_check
    assert_failure
    assert_output_contains "dev-tools: rg not installed"
    PATH="$DT_PATH" run dev-tools_install
    assert_failure
    assert_output_contains "Missing CLI tools: rg"
    PATH="$DT_PATH" run dev-tools_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: rg not installed"
}
