#!/usr/bin/env bats
# system.bats — system liberator: sudo, the sudo or wheel group on Linux, and
# Homebrew on macOS (issue 0085)

load "../test_helper.bash"

# A sleeve on the platform $1 whose PATH holds only fakes: whoami says tester,
# `groups tester` prints the groups $2 as Linux's does, and each further
# argument names a command that is there (sudo, brew). Each test runs the
# liberator with PATH set to $FAKE alone, so nothing the machine has answers
# for a fake.
_system_env() {
    load_liberator system
    local platform="$1" user_groups="$2" cmd
    shift 2
    eval "molt_platform() { echo $platform; }"
    FAKE="$BATS_TEST_TMPDIR/fake-bin"
    mkdir -p "$FAKE"
    printf '#!/bin/sh\necho tester\n' > "$FAKE/whoami"
    printf '#!/bin/sh\necho "tester : %s"\n' "$user_groups" > "$FAKE/groups"
    for cmd in "$@"; do
        printf '#!/bin/sh\nexit 0\n' > "$FAKE/$cmd"
    done
    chmod +x "$FAKE"/*
}

@test "check passes on Linux for a user in the sudo group" {
    _system_env linux "tester sudo" sudo
    PATH="$FAKE" run system_check
    assert_success
}

@test "check passes on Linux for a user in the wheel group, as on Fedora, RHEL and Arch" {
    _system_env linux "tester wheel" sudo
    PATH="$FAKE" run system_check
    assert_success
}

@test "check fails on Linux for a user in neither group, and a group named like one is not it" {
    _system_env linux "tester sudo-users wheelers" sudo
    PATH="$FAKE" run system_check
    assert_failure
    assert_output_contains "system: tester is in neither the sudo group nor the wheel group"
}

@test "install fails for a user in neither group, rather than saying it is complete" {
    _system_env linux "tester" sudo
    PATH="$FAKE" run system_install
    assert_failure
    assert_output_contains "tester is in neither the sudo group nor the wheel group"
    refute_output_contains "Liberator complete"
}

@test "check and install fail on macOS without Homebrew, naming it" {
    _system_env macos "staff admin" sudo
    PATH="$FAKE" run system_check
    assert_failure
    assert_output_contains "system: Homebrew is not installed"
    PATH="$FAKE" run system_install
    assert_failure
    refute_output_contains "Liberator complete"
}

@test "check passes and install completes on macOS with sudo and Homebrew" {
    _system_env macos "staff admin" sudo brew
    PATH="$FAKE" run system_check
    assert_success
    PATH="$FAKE" run system_install
    assert_success
    assert_output_contains "Liberator complete: system"
}

@test "check fails without sudo, naming it" {
    _system_env linux "tester sudo"
    PATH="$FAKE" run system_check
    assert_failure
    assert_output_contains "system: sudo is not installed"
}

@test "verify names every fault it finds" {
    _system_env macos "staff"
    PATH="$FAKE" run system_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: system: sudo is not installed"
    assert_output_contains "VERIFY FAIL: system: Homebrew is not installed"
}
