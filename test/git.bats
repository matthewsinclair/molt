#!/usr/bin/env bats
# git.bats — Tests for `molt git` multi-repo command

load "test_helper.bash"

# ============================================================================
# HELPERS
# ============================================================================

# Create a minimal git repo at the given path
create_git_repo() {
    local path="$1"
    mkdir -p "$path"
    git -C "$path" init -q
    git -C "$path" commit --allow-empty -m "initial" -q
}

# Create a mock liberator script with repo convention functions
create_mock_liberator() {
    local name="$1"
    local repo_path="$2"
    local allowed_cmds="${3:-pull status log diff fetch}"

    cat > "${MOLT_LIBERATORS_DIR}/${name}.sh" <<BASH
#!/usr/bin/env bash
${name}_repo() { echo "${repo_path}"; }
${name}_repo_remote() { echo "origin"; }
${name}_repo_git_commands() { echo "${allowed_cmds}"; }
${name}_check() { return 0; }
${name}_install() { return 0; }
BASH
}

# Override MOLT_ROOT and related paths for test isolation
setup_isolated_molt() {
    export MOLT_TEST_ORIG_ROOT="$MOLT_ROOT"
    export MOLT_TEST_ORIG_LIBERATORS="$MOLT_LIBERATORS_DIR"

    # Create an isolated molt "framework" repo
    local molt_repo="$BATS_TEST_TMPDIR/molt-framework"
    create_git_repo "$molt_repo"
    mkdir -p "$molt_repo/lib" "$molt_repo/liberators" "$molt_repo/bin"

    # Copy real libraries into the fake framework
    cp "$MOLT_TEST_ORIG_ROOT/lib/constants.sh" "$molt_repo/lib/"
    cp "$MOLT_TEST_ORIG_ROOT/lib/molt.sh" "$molt_repo/lib/"
    cp "$MOLT_TEST_ORIG_ROOT/lib/liberator.sh" "$molt_repo/lib/"

    export MOLT_ROOT="$molt_repo"
    export MOLT_LIBERATORS_DIR="$molt_repo/liberators"

    # Create a fake user config repo
    local config_repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_git_repo "$config_repo"
    mkdir -p "$config_repo/config"

    # Re-source libs so they pick up new MOLT_ROOT
    source "$molt_repo/lib/constants.sh"
    source "$molt_repo/lib/molt.sh"
    source "$molt_repo/lib/liberator.sh"

    # Override AFTER sourcing so we don't get clobbered by the real definitions
    eval "molt_find_user_repo() { echo \"$config_repo\"; }"
    molt_enabled_liberators() { return 1; }
}

# ============================================================================
# CLI TESTS
# ============================================================================

@test "molt help lists git command" {
    run_molt help
    assert_success
    assert_output_contains "git <cmd>"
}

@test "molt git with no args shows usage" {
    run_molt git
    assert_success
    assert_output_contains "Usage: molt git"
}

@test "molt git usage shows examples" {
    run_molt git
    assert_success
    assert_output_contains "molt git status"
    assert_output_contains "molt git pull"
}

# ============================================================================
# MOLT_ALL_REPOS TESTS
# ============================================================================

@test "molt_all_repos includes framework repo" {
    setup_isolated_molt
    run molt_all_repos
    assert_success
    assert_output_contains "molt:"
}

@test "molt_all_repos includes config repo" {
    setup_isolated_molt
    run molt_all_repos
    assert_success
    assert_output_contains "config:"
}

@test "molt_all_repos includes liberator repos" {
    setup_isolated_molt
    local lib_repo="$BATS_TEST_TMPDIR/fake-lib-repo"
    create_git_repo "$lib_repo"
    create_mock_liberator "fakelib" "$lib_repo"

    run molt_all_repos
    assert_success
    assert_output_contains "fakelib:${lib_repo}"
}

@test "molt_all_repos skips liberators without _repo function" {
    setup_isolated_molt
    # Create a liberator with no _repo function
    cat > "${MOLT_LIBERATORS_DIR}/norep.sh" <<'BASH'
#!/usr/bin/env bash
norep_check() { return 0; }
norep_install() { return 0; }
BASH

    run molt_all_repos
    assert_success
    refute_output_contains "norep:"
}

@test "molt_all_repos skips liberator when _repo returns failure" {
    setup_isolated_molt
    cat > "${MOLT_LIBERATORS_DIR}/badrepo.sh" <<'BASH'
#!/usr/bin/env bash
badrepo_repo() { return 1; }
badrepo_check() { return 0; }
BASH

    run molt_all_repos
    assert_success
    refute_output_contains "badrepo:"
}

# ============================================================================
# LIBERATOR REPO CONVENTION TESTS
# ============================================================================

@test "liberator_has_repo returns true when _repo exists" {
    load_molt_libs
    load_liberator utilz
    run liberator_has_repo utilz
    assert_success
}

@test "liberator_has_repo returns false when _repo missing" {
    load_molt_libs
    load_liberator system
    run liberator_has_repo system
    assert_failure
}

@test "liberator_repo calls the _repo function" {
    setup_isolated_molt
    local lib_repo="$BATS_TEST_TMPDIR/test-repo"
    create_git_repo "$lib_repo"
    create_mock_liberator "testrepo" "$lib_repo"

    liberator_load testrepo
    run liberator_repo testrepo
    assert_success
    assert_output_contains "$lib_repo"
}

# ============================================================================
# CMD_GIT WHITELIST TESTS
# ============================================================================

@test "cmd_git runs allowed command on liberator repo" {
    setup_isolated_molt
    local lib_repo="$BATS_TEST_TMPDIR/allowed-repo"
    create_git_repo "$lib_repo"
    create_mock_liberator "mylib" "$lib_repo" "status pull"

    run cmd_git status
    assert_success
    assert_output_contains "--- mylib ("
    # Should show git status output (not a warning)
    refute_output_contains "not in mylib"
}

@test "cmd_git blocks disallowed command on liberator repo" {
    setup_isolated_molt
    local lib_repo="$BATS_TEST_TMPDIR/blocked-repo"
    create_git_repo "$lib_repo"
    create_mock_liberator "blocked" "$lib_repo" "status pull"

    run cmd_git push
    assert_output_contains "--- blocked ("
    assert_output_contains "not in blocked's allowed commands"
}

@test "cmd_git runs any command on framework repo" {
    setup_isolated_molt
    run cmd_git log --oneline -1
    assert_success
    assert_output_contains "--- molt ("
    # Should show log output
    assert_output_contains "initial"
}

@test "cmd_git runs any command on config repo" {
    setup_isolated_molt
    run cmd_git log --oneline -1
    assert_success
    assert_output_contains "--- config ("
    assert_output_contains "initial"
}

@test "cmd_git prints header for each repo" {
    setup_isolated_molt
    run cmd_git status
    assert_success
    assert_output_contains "--- molt ("
    assert_output_contains "--- config ("
}

@test "cmd_git continues after error in one repo" {
    setup_isolated_molt
    local lib_repo="$BATS_TEST_TMPDIR/good-repo"
    create_git_repo "$lib_repo"
    create_mock_liberator "goodlib" "$lib_repo" "status log"

    # Create a liberator pointing to a non-existent repo path
    create_mock_liberator "badlib" "/nonexistent/repo" "status log"

    run cmd_git status
    # Should still show output from good repos
    assert_output_contains "--- molt ("
    assert_output_contains "--- goodlib ("
}

@test "cmd_git reports error count" {
    setup_isolated_molt
    create_mock_liberator "errlib" "/nonexistent/repo" "status"

    run cmd_git status
    assert_output_contains "repo(s) had errors"
}

# ============================================================================
# LIBERATOR CONVENTION FUNCTION TESTS
# ============================================================================

@test "utilz defines repo convention functions" {
    load_molt_libs
    load_liberator utilz
    [ "$(type -t utilz_repo)" = "function" ]
    [ "$(type -t utilz_repo_git_commands)" = "function" ]
}

@test "utilz_repo_git_commands returns expected commands" {
    load_molt_libs
    load_liberator utilz
    run utilz_repo_git_commands
    assert_success
    assert_output_contains "pull"
    assert_output_contains "status"
    assert_output_contains "log"
    assert_output_contains "diff"
    assert_output_contains "fetch"
}

@test "intent defines repo convention functions" {
    load_molt_libs
    load_liberator intent
    [ "$(type -t intent_repo)" = "function" ]
    [ "$(type -t intent_repo_git_commands)" = "function" ]
}

@test "pplr defines repo convention functions" {
    load_molt_libs
    load_liberator pplr
    [ "$(type -t pplr_repo)" = "function" ]
    [ "$(type -t pplr_repo_git_commands)" = "function" ]
}

@test "web defines repo convention functions" {
    load_molt_libs
    load_liberator web
    [ "$(type -t web_repo)" = "function" ]
    [ "$(type -t web_repo_git_commands)" = "function" ]
}

@test "editors defines repo convention functions" {
    load_molt_libs
    load_liberator editors
    [ "$(type -t editors_repo)" = "function" ]
    [ "$(type -t editors_repo_git_commands)" = "function" ]
}
