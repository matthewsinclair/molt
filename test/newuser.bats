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
    # Two conventions, deliberately different: the stack/GitHub name is
    # lowercase (matthewsinclair/molt-matts), the DIRECTORY is Capitalised
    # (Molt-matts), and user_repo names the directory.
    assert_output_contains 'name = "molt-flynn"'
    assert_output_contains 'user_repo = "Molt-flynn"'
}

@test "molt_new_user manifest declares the scaffolded liberators" {
    _load_newuser
    local dest; dest="$(_scaffold_flynn)"
    run cat "$dest/instances/jormungandr/molt.toml"
    assert_output_contains 'name = "claude"'
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

@test "molt new-user without --dest scaffolds into MOLT_CFG_DIR" {
    export MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg"
    mkdir -p "$MOLT_CFG_DIR"
    run_molt new-user flynn \
        --name "Flynn Sinclair" \
        --email "flynn.sinclair@gmail.com" \
        --github flynn-sinclair \
        --hostname jormungandr
    assert_success
    assert_directory_exists "$MOLT_CFG_DIR/Molt-flynn/instances/jormungandr"
    assert_output_contains "MOLT_CFG_DIR=\"$MOLT_CFG_DIR\" molt resleeve --dry-run"
}

# Until a resleeve has run, git has no identity for the commit and ssh no
# github.com-<github> host for the push, and git init may make master where the
# push names main (issue 0085).
@test "molt new-user's next steps resleeve before the first commit and push, on main" {
    export MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg"
    mkdir -p "$MOLT_CFG_DIR"
    run_molt new-user flynn \
        --name "Flynn Sinclair" \
        --email "flynn.sinclair@gmail.com" \
        --github flynn-sinclair \
        --hostname jormungandr
    assert_success
    assert_output_contains "git init -b main"
    local resleeve commit push
    resleeve="$(grep -n 'molt resleeve$' <<< "$output" | cut -d: -f1)"
    commit="$(grep -n 'git commit' <<< "$output" | cut -d: -f1)"
    push="$(grep -n 'git push -u origin main' <<< "$output" | cut -d: -f1)"
    [ -n "$resleeve" ] && [ -n "$commit" ] && [ -n "$push" ]
    [ "$resleeve" -lt "$commit" ]
    [ "$commit" -lt "$push" ]
}

# --- --from: another template (issue 0097) ---

# A template of the test's own, as a course's would be: a config/, by which
# molt finds a stack, tokens in file contents and in path names, among them a
# tokened file inside a tokened directory, and a marker line the skeleton does
# not carry. Prints its path.
_course_template() {
    local template="$BATS_TEST_TMPDIR/course-template"
    mkdir -p "$template/config/git" "$template/instances/__MOLT_HOSTNAME__"
    printf '[user]\n\tname = __MOLT_FULL_NAME__\n\temail = __MOLT_EMAIL__\n' > "$template/config/git/gitconfig"
    printf 'login = __MOLT_USER__\nforge = __MOLT_GITHUB__\n' > "$template/config/git/forge___MOLT_GITHUB__"
    printf 'export MOLT_HOSTNAME="__MOLT_HOSTNAME__"\n' > "$template/instances/__MOLT_HOSTNAME__/vars.sh"
    printf 'notes for __MOLT_USER__\n' > "$template/instances/__MOLT_HOSTNAME__/notes___MOLT_USER__.md"
    echo "# a course template" > "$template/README.md"
    echo "$template"
}

@test "molt_new_user from another template substitutes its tokens in contents and path names (issue 0097)" {
    _load_newuser
    local template dest="$BATS_TEST_TMPDIR/Molt-ada"
    template="$(_course_template)"
    run molt_new_user ada "Ada Lovelace" ada@example.com ada-l analytical "$dest" "$template"
    assert_success
    grep -qx '# a course template' "$dest/README.md" || fail "not scaffolded from the template: $(cat "$dest/README.md")"
    [ ! -e "$dest/config/ssh/config.tmpl" ] || fail "the skeleton's files are in the scaffold"
    assert_file_exists "$dest/config/git/forge_ada-l"
    assert_file_exists "$dest/instances/analytical/vars.sh"
    assert_file_exists "$dest/instances/analytical/notes_ada.md"
    run cat "$dest/config/git/gitconfig"
    assert_output_contains "name = Ada Lovelace"
    assert_output_contains "email = ada@example.com"
    run cat "$dest/config/git/forge_ada-l"
    assert_output_contains "login = ada"
    assert_output_contains "forge = ada-l"
    run find "$dest" -name '*__MOLT_*'
    [ -z "$output" ] || fail "tokens left in path names: $output"
    run grep -rl '__MOLT_' "$dest"
    assert_failure
}

@test "molt_new_user copies no .git from a template, at any depth (issue 0097)" {
    _load_newuser
    local template dest="$BATS_TEST_TMPDIR/Molt-ada"
    template="$(_course_template)"
    git -C "$template" init -q
    git -C "$template" add -A
    git -C "$template" -c user.name=t -c user.email=t@t commit -qm template
    mkdir -p "$template/vendor/kit/.git"
    echo "ref: refs/heads/__MOLT_USER__" > "$template/vendor/kit/.git/HEAD"
    echo "kit" > "$template/vendor/kit/README"
    run molt_new_user ada "Ada Lovelace" ada@example.com ada-l analytical "$dest" "$template"
    assert_success
    grep -qx '# a course template' "$dest/README.md" || fail "not scaffolded from the template"
    assert_file_exists "$dest/vendor/kit/README"
    run find "$dest" -name .git
    [ -z "$output" ] || fail "a .git came from the template: $output"
    grep -qx 'ref: refs/heads/__MOLT_USER__' "$template/vendor/kit/.git/HEAD" || fail "the template's own .git changed"
}

@test "molt_new_user refuses a template that is not a directory, or holds no config/, and writes nothing (issue 0097)" {
    _load_newuser
    local dest="$BATS_TEST_TMPDIR/Molt-ada" file="$BATS_TEST_TMPDIR/a-file" bare="$BATS_TEST_TMPDIR/no-config"
    echo "not a template" > "$file"
    mkdir -p "$bare/instances"
    local not_dirs=("$file" "$BATS_TEST_TMPDIR/missing") template
    for template in "${not_dirs[@]}"; do
        run molt_new_user ada "Ada Lovelace" ada@example.com ada-l analytical "$dest" "$template"
        assert_failure
        assert_output_contains "new-user: $template is not a directory"
        [ ! -e "$dest" ] || fail "$dest was written for $template"
    done
    run molt_new_user ada "Ada Lovelace" ada@example.com ada-l analytical "$dest" "$bare"
    assert_failure
    assert_output_contains "new-user: $bare holds no config/"
    [ ! -e "$dest" ] || fail "$dest was written for a template with no config/"
}

@test "molt new-user --from scaffolds from the template with flags alone, and its next steps leave out the GitHub lines (issue 0097)" {
    local template dest="$BATS_TEST_TMPDIR/Molt-ada"
    template="$(_course_template)"
    run_molt new-user ada --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" --from "$template"
    assert_success
    grep -qx '# a course template' "$dest/README.md" || fail "not scaffolded from the template"
    assert_output_contains "molt resleeve --dry-run"
    assert_output_contains "git init -b main && git add -A && git commit"
    refute_output_contains "GitHub"
    refute_output_contains "git remote add"
    refute_output_contains "git push"
}

@test "molt new-user refuses an empty --from as no directory, rather than read it as the skeleton (issue 0097)" {
    local dest="$BATS_TEST_TMPDIR/Molt-ada"
    run_molt new-user ada --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" --from ""
    assert_failure
    assert_output_contains "is not a directory"
    [ ! -e "$dest" ] || fail "$dest was written for an empty --from"
}

# bash 5.2 and later put the token back in place of an & in the value of a
# ${name//token/value}, by patsub_replacement, where 3.2 keeps the &: a path
# name takes its tokens through sed, as the contents do (issue 0097).
@test "molt new-user --from keeps an & in a value whole in a path name, as in the contents (issue 0097)" {
    local template dest="$BATS_TEST_TMPDIR/Molt-ada"
    template="$(_course_template)"
    printf 'by __MOLT_FULL_NAME__\n' > "$template/config/notes___MOLT_FULL_NAME__.md"
    run_molt new-user ada --name "Tom & Jerry" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" --from "$template"
    assert_success
    assert_file_exists "$dest/config/notes_Tom & Jerry.md"
    grep -qxF 'by Tom & Jerry' "$dest/config/notes_Tom & Jerry.md" || fail "the contents lost the &"
}

# A file takes its tokens written back into it, never a new file moved over
# it, so it keeps its mode: a script in the template stays executable (issue
# 0097).
@test "molt new-user --from keeps a template file's mode, so a script stays executable (issue 0097)" {
    local template dest="$BATS_TEST_TMPDIR/Molt-ada"
    template="$(_course_template)"
    mkdir -p "$template/bin"
    printf '#!/bin/sh\necho __MOLT_USER__\n' > "$template/bin/setup"
    chmod 755 "$template/bin/setup"
    run_molt new-user ada --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" --from "$template"
    assert_success
    [ -x "$dest/bin/setup" ] || fail "the script lost its exec bit: $(ls -l "$dest/bin/setup")"
    grep -qx 'echo ada' "$dest/bin/setup" || fail "the script's token was not substituted"
}

# Under a UTF-8 locale, macOS's sed refuses a file that is not UTF-8, so the
# substitution runs byte-wise. The locale is the test's own, since a caller's
# LC_ALL=C would hide the fault. GNU sed passes such a file under either
# locale, so on Linux this passes without the fix too (issue 0097).
@test "molt new-user --from carries a file that is not UTF-8 byte for byte under a UTF-8 locale, tokens and all (issue 0097)" {
    local template dest="$BATS_TEST_TMPDIR/Molt-ada" want="$BATS_TEST_TMPDIR/want.bin"
    template="$(_course_template)"
    printf '\211PNG\r\n\032\n\000\000\000\rIHDR\377\376\200' > "$template/config/logo.png"
    printf '\377\376__MOLT_USER__\200\000' > "$template/config/blob.bin"
    printf '\377\376ada\200\000' > "$want"
    unset LC_ALL
    export LANG=C.UTF-8 LC_CTYPE=C.UTF-8
    run_molt new-user ada --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" --from "$template"
    assert_success
    cmp "$template/config/logo.png" "$dest/config/logo.png" || fail "logo.png changed in the scaffold"
    cmp "$want" "$dest/config/blob.bin" || fail "blob.bin's token was not substituted byte-wise"
}

# --- a value flag with no value, or a prompt with nothing to read (issue 0098) ---

@test "molt new-user refuses each value flag given last with no value, naming it, and writes nothing (issue 0098)" {
    local dest="$BATS_TEST_TMPDIR/Molt-ada" flags=() flag
    # Every flag new-user's usage gives a value, as molt help prints it.
    run_molt help
    while IFS= read -r flag; do
        flags+=("$flag")
    done < <(grep 'new-user <user>' <<< "$output" | grep -o -- '\[--[a-z]*' | sed 's/^\[//')
    [ "${#flags[@]}" -gt 0 ] || fail "molt help names no value flag for new-user: $output"
    for flag in "${flags[@]}"; do
        run_molt new-user ada --dest "$dest" "$flag" < /dev/null
        assert_failure
        assert_output_contains "new-user: $flag needs a value"
        [ ! -e "$dest" ] || fail "$dest was written for $flag given last"
    done
}

@test "molt new-user with nothing to read refuses a missing user, --email or --hostname, or an empty --email, naming it, and writes nothing (issue 0098)" {
    local dest="$BATS_TEST_TMPDIR/Molt-ada"
    run_molt new-user --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --hostname analytical --dest "$dest" < /dev/null
    assert_failure
    assert_output_contains "username is required"
    [ ! -e "$dest" ] || fail "$dest was written with no user"
    run_molt new-user ada --name "Ada Lovelace" --github ada-l \
        --hostname analytical --dest "$dest" < /dev/null
    assert_failure
    assert_output_contains "email is required"
    [ ! -e "$dest" ] || fail "$dest was written with no --email"
    run_molt new-user ada --name "Ada Lovelace" --email "" --github ada-l \
        --hostname analytical --dest "$dest" < /dev/null
    assert_failure
    assert_output_contains "email is required"
    [ ! -e "$dest" ] || fail "$dest was written with an empty --email"
    run_molt new-user ada --name "Ada Lovelace" --email ada@example.com --github ada-l \
        --dest "$dest" < /dev/null
    assert_failure
    assert_output_contains "hostname is required"
    [ ! -e "$dest" ] || fail "$dest was written with no --hostname"
}

@test "molt new-user with nothing to read gives a missing --name and an empty --github the user, as Enter does (issue 0098)" {
    local dest="$BATS_TEST_TMPDIR/Molt-ada"
    run_molt new-user ada --email ada@example.com --github "" --hostname analytical \
        --dest "$dest" < /dev/null
    assert_success
    assert_file_exists "$dest/config/git/gitconfig_ada"
    run cat "$dest/config/git/gitconfig"
    assert_output_contains "name = ada"
    assert_output_contains "path = ~/.gitconfig_ada"
}
