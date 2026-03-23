#!/usr/bin/env bats
# instances.bats — Tests for cross-instance aggregation (molt_instances_field)
#
# SAFETY: Every test sandboxes HOME to a temp directory so that
# constants.sh (which builds paths from $HOME) can never resolve
# to the real home directory. No test in this file should ever
# read, write, or delete anything under the real $HOME.

load "test_helper.bash"

setup() {
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"

    # Sandbox HOME
    export REAL_HOME="$HOME"
    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"

    # Create a test user repo
    create_test_repo "$BATS_TEST_TMPDIR/molt-testuser"
}

teardown() {
    if [[ -n "${REAL_HOME:-}" ]]; then
        export HOME="$REAL_HOME"
    fi
    if [[ -n "$ORIGINAL_PWD" && -d "$ORIGINAL_PWD" ]]; then
        cd "$ORIGINAL_PWD"
    fi
    if [[ -n "$BATS_TEST_TMPDIR" && -d "$BATS_TEST_TMPDIR" ]]; then
        rm -rf "$BATS_TEST_TMPDIR"
    fi
}

# Helper: load libs and point search paths at our test repo.
_use_test_repo() {
    load_molt_libs
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/molt-testuser")
}

# Helper: create an instance.toml in the test repo
create_test_instance() {
    local repo="$1"
    local hostname="$2"
    local content="$3"
    local dir="$repo/instances/$hostname"
    mkdir -p "$dir"
    echo "$content" > "$dir/instance.toml"
}

# --- molt_instances_field tests ---

@test "molt_instances_field returns correct hostname:value pairs" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    create_test_instance "$repo" "alpha" '[instance]
hostname = "alpha"
os = "macos"

[terminal]
ssh_bg_color = "1a1a2e"'

    create_test_instance "$repo" "beta" '[instance]
hostname = "beta"
os = "linux"

[terminal]
ssh_bg_color = "1a2e1a"'

    run molt_instances_field "ssh_bg_color" "terminal"
    assert_success
    assert_output_contains "alpha:1a1a2e"
    assert_output_contains "beta:1a2e1a"
}

@test "molt_instances_field skips instances without the requested field" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    create_test_instance "$repo" "alpha" '[instance]
hostname = "alpha"

[terminal]
ssh_bg_color = "1a1a2e"'

    create_test_instance "$repo" "gamma" '[instance]
hostname = "gamma"
os = "linux"'

    run molt_instances_field "ssh_bg_color" "terminal"
    assert_success
    assert_output_contains "alpha:1a1a2e"
    refute_output_contains "gamma"
}

@test "molt_instances_field handles missing instance.toml gracefully" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    # Create an instance directory with no instance.toml
    mkdir -p "$repo/instances/empty"

    create_test_instance "$repo" "alpha" '[terminal]
ssh_bg_color = "aabbcc"'

    run molt_instances_field "ssh_bg_color" "terminal"
    assert_success
    assert_output_contains "alpha:aabbcc"
    refute_output_contains "empty"
}

@test "molt_instances_field returns nothing when no instances have the field" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    create_test_instance "$repo" "alpha" '[instance]
hostname = "alpha"'

    run molt_instances_field "ssh_bg_color" "terminal"
    [[ -z "$output" ]]
}

@test "molt_instances_field reads from correct TOML section" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    create_test_instance "$repo" "alpha" '[instance]
hostname = "alpha"
ssh_bg_color = "wrong"

[terminal]
ssh_bg_color = "correct"'

    run molt_instances_field "ssh_bg_color" "terminal"
    assert_success
    assert_output_contains "alpha:correct"
    refute_output_contains "wrong"
}

@test "molt_instances_field defaults to instance section" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"

    create_test_instance "$repo" "alpha" '[instance]
hostname = "alpha"
os = "macos"'

    run molt_instances_field "hostname"
    assert_success
    assert_output_contains "alpha:alpha"
}
