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

@test "MOLT_PROJECTS_DIR defaults to \$HOME/Devel/prj" {
    unset MOLT_PROJECTS_DIR
    load_molt_libs
    [[ "$MOLT_PROJECTS_DIR" == "$HOME/Devel/prj" ]]
}

@test "MOLT_PROJECTS_DIR respects env var override" {
    export MOLT_PROJECTS_DIR="/tmp/custom-projects"
    load_molt_libs
    [[ "$MOLT_PROJECTS_DIR" == "/tmp/custom-projects" ]]
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

@test "MOLT_USER_REPO_SEARCH_PATHS includes Devel/prj path" {
    load_molt_libs
    local found=0
    for p in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
        [[ "$p" == *"Devel/prj"* ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}
