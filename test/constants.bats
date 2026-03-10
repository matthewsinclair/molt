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

@test "MOLT_USER_REPO_SEARCH_PATHS has home fallbacks when MOLT_PRJ_DIR unset" {
    unset MOLT_PRJ_DIR
    load_molt_libs
    local found=0
    for p in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
        [[ "$p" == "$HOME/molt-"* ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}
