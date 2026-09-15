#!/usr/bin/env bats
# constants.bats — Tests for lib/constants.sh

load "test_helper.bash"

@test "MOLT_VERSION is set" {
    load_molt_libs
    [[ -n "$MOLT_VERSION" ]]
}

@test "MOLT_VERSION matches semver pattern" {
    load_molt_libs
    [[ "$MOLT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "MOLT_NAME is set" {
    load_molt_libs
    [[ "$MOLT_NAME" == "MOLT" ]]
}

@test "MOLT_PRJ_DIR is empty when unset" {
    unset MOLT_PRJ_DIR
    load_molt_libs
    [[ -z "$MOLT_PRJ_DIR" ]]
}

@test "MOLT_PRJ_DIR respects env var override" {
    export MOLT_PRJ_DIR="/tmp/custom-projects"
    load_molt_libs
    [[ "$MOLT_PRJ_DIR" == "/tmp/custom-projects" ]]
}

@test "MOLT_OPT_DIR derives from MOLT_PRJ_DIR parent" {
    unset MOLT_OPT_DIR
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    [[ "$MOLT_OPT_DIR" == "/tmp/opt" ]]
}

@test "MOLT_OPT_DIR is empty when MOLT_PRJ_DIR unset" {
    unset MOLT_PRJ_DIR
    unset MOLT_OPT_DIR
    load_molt_libs
    [[ -z "$MOLT_OPT_DIR" ]]
}

@test "MOLT_OPT_DIR respects env var override" {
    export MOLT_OPT_DIR="/custom/opt"
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    [[ "$MOLT_OPT_DIR" == "/custom/opt" ]]
}

@test "MOLT_LOCAL_BIN defaults to \$HOME/bin" {
    unset MOLT_LOCAL_BIN
    load_molt_libs
    [[ "$MOLT_LOCAL_BIN" == "$HOME/bin" ]]
}

@test "MOLT_LOCAL_BIN respects env var override" {
    export MOLT_LOCAL_BIN="/tmp/custom-bin"
    load_molt_libs
    [[ "$MOLT_LOCAL_BIN" == "/tmp/custom-bin" ]]
}

@test "MOLT_UTILZ_HOME respects UTILZ_HOME env var" {
    export UTILZ_HOME="/opt/my-utilz"
    load_molt_libs
    [[ "$MOLT_UTILZ_HOME" == "/opt/my-utilz" ]]
}

@test "MOLT_USER_REPO_SEARCH_PATHS is an array" {
    load_molt_libs
    [[ ${#MOLT_USER_REPO_SEARCH_PATHS[@]} -gt 0 ]]
}

@test "MOLT_USER_REPO_SEARCH_PATHS includes MOLT_PRJ_DIR path when set" {
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    local found=0
    for p in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
        [[ "$p" == *"/tmp/test-projects"* ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}

@test "MOLT_CFG_DIR derives from MOLT_PRJ_DIR parent" {
    unset MOLT_CFG_DIR
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    [[ "$MOLT_CFG_DIR" == "/tmp/cfg" ]]
}

@test "MOLT_CFG_DIR is empty when MOLT_PRJ_DIR unset" {
    unset MOLT_PRJ_DIR
    unset MOLT_CFG_DIR
    load_molt_libs
    [[ -z "$MOLT_CFG_DIR" ]]
}

@test "MOLT_CFG_DIR respects env var override" {
    export MOLT_CFG_DIR="/custom/cfg"
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    [[ "$MOLT_CFG_DIR" == "/custom/cfg" ]]
}

# The move to cfg/ is per sleeve, so a sleeve that has not moved its repo must
# still find it in MOLT_PRJ_DIR -- but only after cfg/ has been tried.
@test "MOLT_USER_REPO_SEARCH_PATHS searches MOLT_CFG_DIR before MOLT_PRJ_DIR" {
    unset MOLT_CFG_DIR
    export MOLT_PRJ_DIR="/tmp/test-projects"
    load_molt_libs
    [[ "${MOLT_USER_REPO_SEARCH_PATHS[0]}" == "/tmp/cfg/Molt-$(whoami)" ]]
    [[ "${MOLT_USER_REPO_SEARCH_PATHS[1]}" == "/tmp/cfg/molt-$(whoami)" ]]
    [[ "${MOLT_USER_REPO_SEARCH_PATHS[2]}" == "/tmp/test-projects/Molt-$(whoami)" ]]
}

@test "molt_find_user_repo resolves a repo left in MOLT_PRJ_DIR and prefers MOLT_CFG_DIR" {
    unset MOLT_CFG_DIR
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/Devel/prj"
    mkdir -p "$MOLT_PRJ_DIR/Molt-$(whoami)/config"
    load_molt_libs
    run molt_find_user_repo
    assert_success
    [[ "$output" == "$MOLT_PRJ_DIR/Molt-$(whoami)" ]]

    mkdir -p "$BATS_TEST_TMPDIR/Devel/cfg/Molt-$(whoami)/config"
    run molt_find_user_repo
    assert_success
    [[ "$output" == "$BATS_TEST_TMPDIR/Devel/cfg/Molt-$(whoami)" ]]
}

@test "MOLT_USER_REPO_SEARCH_PATHS has home fallbacks when MOLT_PRJ_DIR unset" {
    unset MOLT_PRJ_DIR
    load_molt_libs
    local found=0
    for p in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
        [[ "$p" == "$HOME/molt-"* ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}
