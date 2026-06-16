#!/usr/bin/env bats
# newuser.bats — Tests for the new-user scaffold (molt_new_user / cmd_new_user)
#
# SAFETY: every test writes only under BATS_TEST_TMPDIR. The skeleton is read
# from the real MOLT_ROOT/templates/molt-user but never modified.

load "test_helper.bash"

# Load core libs + the newuser module for function-level tests.
_load_newuser() {
    load_molt_libs
    source "$MOLT_LIB_DIR/newuser.sh"
}

# Scaffold a standard fixture and echo its path.
_scaffold_flynn() {
    local dest="$BATS_TEST_TMPDIR/molt-flynn"
    molt_new_user "flynn" "Flynn Sinclair" "flynn.sinclair@gmail.com" \
        "flynn-sinclair" "jormungandr" "$dest" >/dev/null
    echo "$dest"
}

# --- molt_new_user: structure ---

@test "molt_new_user creates the destination repo" {
    _load_newuser
    local dest="$BATS_TEST_TMPDIR/molt-flynn"
    run molt_new_user "flynn" "Flynn Sinclair" "flynn.sinclair@gmail.com" \
        "flynn-sinclair" "jormungandr" "$dest"
    assert_success
    assert_directory_exists "$dest"
    assert_file_exists "$dest/README.md"
}

@test "molt_new_user renames the hostname instance directory" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    assert_directory_exists "$dest/instances/jormungandr"
    [[ ! -d "$dest/instances/__MOLT_HOSTNAME__" ]]
}

@test "molt_new_user renames the github identity file" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    assert_file_exists "$dest/config/git/gitconfig_flynn-sinclair"
    [[ ! -e "$dest/config/git/gitconfig___MOLT_GITHUB__" ]]
}

# --- molt_new_user: content substitution ---

@test "molt_new_user substitutes git identity tokens" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    run cat "$dest/config/git/gitconfig"
    assert_output_contains "name = Flynn Sinclair"
    assert_output_contains "email = flynn.sinclair@gmail.com"
    assert_output_contains "path = ~/.gitconfig_flynn-sinclair"
}

@test "molt_new_user substitutes vars and manifest tokens" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    run cat "$dest/instances/jormungandr/vars.sh"
    assert_output_contains 'MOLT_USER="flynn"'
    assert_output_contains 'MOLT_HOSTNAME="jormungandr"'

    run cat "$dest/instances/jormungandr/molt.toml"
    assert_output_contains 'name = "molt-flynn"'
    assert_output_contains 'user_repo = "molt-flynn"'
}

@test "molt_new_user substitutes README tokens (heading and name)" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    run cat "$dest/README.md"
    assert_output_contains "molt-flynn"
    assert_output_contains "Flynn Sinclair"
    # Catches both unsubstituted (__MOLT_USER__) and markdown-mangled
    # (**MOLT_USER**) tokens, since both retain the bare MOLT_ name.
    refute_output_contains "MOLT_USER"
    refute_output_contains "MOLT_FULL_NAME"
}

@test "molt_new_user leaves runtime template vars untouched" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    # The scaffold must NOT touch ${MOLT_SSH_KEY} — that is rendered later by
    # resleeve via envsubst, not at scaffold time.
    run cat "$dest/config/ssh/config.tmpl"
    assert_output_contains 'IdentityFile ~/.ssh/${MOLT_SSH_KEY}'
    assert_output_contains "Host github.com-flynn-sinclair"
}

@test "molt_new_user leaves no __MOLT_ tokens anywhere" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    run grep -rl '__MOLT_' "$dest"
    # grep exits non-zero when nothing matches — that is what we want.
    assert_failure
}

# --- molt_new_user: safety ---

@test "molt_new_user refuses to overwrite an existing destination" {
    _load_newuser
    local dest="$BATS_TEST_TMPDIR/molt-existing"
    mkdir -p "$dest"
    run molt_new_user "flynn" "Flynn Sinclair" "flynn.sinclair@gmail.com" \
        "flynn-sinclair" "jormungandr" "$dest"
    assert_failure
    assert_output_contains "already exists"
}

# --- CLI wiring ---

@test "molt help lists the new-user command" {
    run_molt help
    assert_success
    assert_output_contains "new-user"
}

@test "molt new-user end-to-end with flags scaffolds and prints next steps" {
    local dest="$BATS_TEST_TMPDIR/molt-flynn"
    run_molt new-user flynn \
        --name "Flynn Sinclair" \
        --email "flynn.sinclair@gmail.com" \
        --github flynn-sinclair \
        --hostname jormungandr \
        --dest "$dest"
    assert_success
    assert_directory_exists "$dest/instances/jormungandr"
    assert_output_contains "git remote add origin git@github.com-flynn-sinclair:flynn-sinclair/molt-flynn.git"
}
