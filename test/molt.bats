#!/usr/bin/env bats
# molt.bats — CLI and framework tests

load "test_helper.bash"

# --- Help ---

@test "molt help shows usage" {
    run_molt help
    assert_success
    assert_output_contains "Usage: molt <command>"
}

@test "molt with no args shows help" {
    run_molt
    assert_success
    assert_output_contains "Usage: molt <command>"
}

# --- Status ---

@test "molt status shows sleeve info" {
    run_molt status
    assert_success
    assert_output_contains "Platform:"
    assert_output_contains "Distro:"
    assert_output_contains "Arch:"
    assert_output_contains "Stack:"
}

# --- Version ---

@test "molt version shows version string" {
    run_molt version
    assert_success
    assert_output_contains "MOLT v"
}

# --- List ---

@test "molt list lists liberators" {
    run_molt list
    assert_success
    assert_output_contains "zsh"
    assert_output_contains "git"
}

# --- Doctor ---

@test "molt doctor runs without crashing" {
    run_molt doctor
    assert_success
    assert_output_contains "Checking"
}

# --- Unknown command ---

@test "unknown command returns error" {
    run_molt bogus_command
    assert_failure
    assert_output_contains "Unknown command"
}

# --- Help lists all commands ---

@test "molt help lists doctor command" {
    run_molt help
    assert_success
    assert_output_contains "doctor"
}

@test "molt help lists test command" {
    run_molt help
    assert_success
    assert_output_contains "test"
}

@test "molt help lists list command" {
    run_molt help
    assert_success
    assert_output_contains "list"
}

@test "molt help lists version command" {
    run_molt help
    assert_success
    assert_output_contains "version"
}

# --- Foreign home-path detection (doctor check 10) ---

@test "molt_foreign_home_paths flags another user's home path (incl JSON-escaped)" {
    load_molt_libs
    local me; me="$(whoami)"
    local d="$BATS_TEST_TMPDIR/cfg"; mkdir -p "$d/iterm2" "$d/zsh"
    # JSON-escaped foreign path — the iTerm2/VS Code export case
    printf '{"Working Directory":"\\/Users\\/someoneelse"}\n' > "$d/iterm2/profile.json"
    # current user's own path must NOT be flagged
    echo "export P=/Users/$me/bin" > "$d/zsh/zshenv"

    run molt_foreign_home_paths "$d"
    assert_success
    assert_output_contains "iterm2/profile.json"
    refute_output_contains "zsh/zshenv"
}

@test "molt_foreign_home_paths clean when only current user's paths" {
    load_molt_libs
    local me; me="$(whoami)"
    local d="$BATS_TEST_TMPDIR/cfg2"; mkdir -p "$d"
    echo "a = /Users/$me/x" > "$d/a.conf"
    echo "b = /home/$me/y" > "$d/b.conf"

    run molt_foreign_home_paths "$d"
    assert_success
    [ -z "$output" ]
}

# --- Symlink state helpers ---

@test "molt_link_fault distinguishes all four states" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/faults"
    mkdir -p "$d"
    : > "$d/real"
    ln -s "$d/real" "$d/good"
    ln -s "$d/NOPE" "$d/dangling"
    : > "$d/regular"

    run molt_link_fault "$d/good"
    assert_output_contains "resolves"
    run molt_link_fault "$d/dangling"
    assert_output_contains "is a broken symlink"
    run molt_link_fault "$d/regular"
    assert_output_contains "is not a symlink"
    run molt_link_fault "$d/absent"
    assert_output_contains "is missing"
}

@test "molt_link_fault does not report a fault for a healthy link" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/healthy"
    mkdir -p "$d"
    : > "$d/real"
    ln -s "$d/real" "$d/good"
    run molt_link_fault "$d/good"
    # Assert positively. A bare refute passes when the function is not loaded
    # at all and the output is "command not found" -- a false green of exactly
    # the kind these helpers exist to prevent.
    assert_success
    [ "$output" = "resolves" ]
}

@test "molt_link_points_to rejects a healthy link to the wrong target" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/points"
    mkdir -p "$d"
    : > "$d/wanted"
    : > "$d/other"
    ln -s "$d/other" "$d/link"

    run molt_link_healthy "$d/link"
    [ "$status" -eq 0 ]

    run molt_link_points_to "$d/link" "$d/wanted"
    [ "$status" -ne 0 ]

    ln -sfn "$d/wanted" "$d/link"
    run molt_link_points_to "$d/link" "$d/wanted"
    [ "$status" -eq 0 ]
}
