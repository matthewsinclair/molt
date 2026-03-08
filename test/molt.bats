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
