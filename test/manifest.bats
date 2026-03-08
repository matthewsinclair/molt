#!/usr/bin/env bats
# manifest.bats — Manifest (molt.toml) parsing tests
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

    # Sandbox HOME — constants.sh builds MOLT_USER_REPO_SEARCH_PATHS from
    # $HOME, so this ensures nothing ever resolves to the real home dir.
    export REAL_HOME="$HOME"
    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"

    # Create a test user repo so manifest discovery works
    create_test_repo "$BATS_TEST_TMPDIR/molt-testuser"
    create_test_manifest "$BATS_TEST_TMPDIR/molt-testuser/molt.toml"
}

teardown() {
    # Restore real HOME before cleanup
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

# Helper: load libs then point search paths at our test repo.
# Must be called AFTER load_molt_libs because constants.sh resets the paths.
_use_test_repo() {
    load_molt_libs
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/molt-testuser")
}

@test "molt_enabled_liberators returns enabled liberators" {
    _use_test_repo
    run molt_enabled_liberators
    assert_success
    assert_output_contains "zsh"
    assert_output_contains "git"
}

@test "disabled liberators are excluded" {
    _use_test_repo
    run molt_enabled_liberators
    assert_success
    refute_output_contains "keys"
}

@test "OS filtering works — linux liberators on linux" {
    _use_test_repo
    local platform
    platform="$(molt_platform)"
    run molt_enabled_liberators

    if [[ "$platform" == "linux" ]]; then
        # desktop is linux-only and enabled
        assert_output_contains "desktop"
    else
        # desktop should be excluded on non-linux
        refute_output_contains "desktop"
    fi
}

@test "missing manifest returns error" {
    # Point to a repo with no manifest
    local empty_repo="$BATS_TEST_TMPDIR/empty-repo"
    mkdir -p "$empty_repo/config"

    load_molt_libs
    MOLT_USER_REPO_SEARCH_PATHS=("$empty_repo")

    run molt_enabled_liberators
    assert_failure
}

@test "molt_find_manifest finds repo-level manifest" {
    _use_test_repo
    run molt_find_manifest
    assert_success
    assert_output_contains "molt.toml"
}

@test "instance manifest takes priority over repo manifest" {
    local hostname
    hostname="$(hostname)"
    local instance_dir="$BATS_TEST_TMPDIR/molt-testuser/instances/$hostname"
    mkdir -p "$instance_dir"

    # Create instance-specific manifest with different content
    cat > "$instance_dir/molt.toml" <<'TOML'
[stack]
name = "instance-stack"
version = "0.1.0"

[[liberator]]
name = "ssh"
enabled = true
os = ["linux", "macos"]
TOML

    _use_test_repo
    run molt_find_manifest
    assert_success
    assert_output_contains "instances/$hostname/molt.toml"
}
