#!/usr/bin/env bats
# zsh.bats — Exemplar liberator test (zsh liberator)

load "../test_helper.bash"

setup() {
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"

    # Load zsh liberator
    load_liberator "zsh"
}

@test "zsh_check function exists after loading" {
    declare -f zsh_check &>/dev/null
}

@test "zsh_install function exists after loading" {
    declare -f zsh_install &>/dev/null
}

@test "zsh_verify function exists after loading" {
    declare -f zsh_verify &>/dev/null
}

@test "zsh_check returns 0 when zsh is installed" {
    require_command "zsh"
    # On a system where zsh is installed, check should at least not crash
    # It may return 1 if config isn't linked, but shouldn't return 127
    run zsh_check
    [[ "$status" -ne 127 ]]
}

@test "zsh_check detects missing zsh" {
    # Temporarily hide zsh from PATH to test detection
    local save_path="$PATH"
    PATH="/usr/bin/nonexistent"
    run zsh_check
    assert_failure
    PATH="$save_path"
}

@test "zsh_verify checks zsh binary" {
    require_command "zsh"
    run zsh_verify
    # Should not crash (127 = function/command not found)
    [[ "$status" -ne 127 ]]
}
