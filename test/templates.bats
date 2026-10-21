#!/usr/bin/env bats
# templates.bats — Template rendering tests for molt_render and molt_install_config
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

# Helper: create a vars.sh for the current hostname
create_test_vars() {
    local repo="$1"
    local hostname
    hostname="$(test_hostname)"
    local vars_dir="$repo/instances/$hostname"
    mkdir -p "$vars_dir"
    cat > "$vars_dir/vars.sh" <<'VARS'
export MOLT_FONT_FAMILY="TestFont Nerd Font"
export MOLT_FONT_SIZE=14
export MOLT_TEST_VAR="hello-world"
VARS
}

# Helper: create a template file in the test repo
create_test_template() {
    local repo="$1"
    local rel_path="$2"
    local content="$3"
    local template_path="$repo/${rel_path}.tmpl"
    mkdir -p "$(dirname "$template_path")"
    echo "$content" > "$template_path"
}

# --- molt_render tests ---

@test "molt_render with valid template + vars.sh produces correct substitution" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/app.conf" 'font = "${MOLT_FONT_FAMILY}" size = ${MOLT_FONT_SIZE}'

    local target="$HOME/.config/test/app.conf"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_success

    # Check rendered content
    local content
    content="$(cat "$target")"
    [[ "$content" == *"TestFont Nerd Font"* ]]
    [[ "$content" == *"size = 14"* ]]
}

@test "molt_render with missing template returns error" {
    _use_test_repo
    local target="$HOME/.config/test/nonexistent.conf"
    run molt_render "$BATS_TEST_TMPDIR/does-not-exist.tmpl" "$target"
    assert_failure
    assert_output_contains "Template not found"
}

@test "molt_render fails clearly when envsubst is missing" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_template "$repo" "config/test/needs-envsubst.conf" 'v = ${MOLT_TEST_VAR}'

    local target="$HOME/.config/test/needs-envsubst.conf"
    # Empty PATH hides envsubst; the guard runs before any external command.
    PATH="/nonexistent" run molt_render "$repo/config/test/needs-envsubst.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "envsubst not found"
}

@test "molt_render with missing vars.sh warns and renders with env only" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    # No create_test_vars — vars.sh won't exist
    export MOLT_TEST_VAR="from-env"
    create_test_template "$repo" "config/test/env.conf" 'value = ${MOLT_TEST_VAR}'

    local target="$HOME/.config/test/env.conf"
    run molt_render "$repo/config/test/env.conf.tmpl" "$target"
    assert_success
    assert_output_contains "No vars.sh"

    local content
    content="$(cat "$target")"
    [[ "$content" == *"from-env"* ]]
}

# vc, 21 Oct: sourcing stops at a syntax error, so a vars.sh that does not parse
# rendered only what it exported before the error; and one that exited as it
# was sourced left the target backed up with nothing in its place.
@test "molt_render refuses a vars.sh that does not parse or stops before its end, and leaves the target as it was" {
    # AT046 (ST0006 AC011).
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    local vars="$repo/instances/$(test_hostname)/vars.sh"
    create_test_vars "$repo"
    echo 'fi' >> "$vars"
    create_test_template "$repo" "config/test/app.conf" 'value = ${MOLT_TEST_VAR}'
    local target="$HOME/.config/test/app.conf"
    mkdir -p "$(dirname "$target")"
    echo "as it was" > "$target"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/app.conf.tmpl -> $target: $vars does not parse (line 4: syntax error"
    [ "$(cat "$target")" = "as it was" ]
    create_test_vars "$repo"
    echo 'exit 0' >> "$vars"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/app.conf.tmpl -> $target: $vars stops before its end when sourced"
    [ "$(cat "$target")" = "as it was" ]
    # critic-shell, 21 Oct: a top-level return, as an include guard has, and
    # a set -e of the file's own, stop it too, under bash 3.2 and 5 alike.
    printf '[ -n "${MOLT_GUARDED:-}" ] || return 0\nexport MOLT_TEST_VAR=x\n' > "$vars"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "$vars stops before its end when sourced"
    printf 'set -e\nfalse\nexport MOLT_TEST_VAR=x\n' > "$vars"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "$vars stops before its end when sourced"
    # A file that stops only the second time it is sourced, with a tmp a
    # crashed render left behind.
    printf '[ -e %q ] && exit 0\n: > %q\nexport MOLT_TEST_VAR=x\n' "$BATS_TEST_TMPDIR/sourced-once" "$BATS_TEST_TMPDIR/sourced-once" > "$vars"
    echo "a crashed render" > "$target.molt-tmp"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/app.conf.tmpl -> $target"
    [ "$(cat "$target")" = "as it was" ]
    [ ! -e "$target.molt-tmp" ]
    [ -z "$(find "$(dirname "$target")" -name '*.molt-backup.*')" ]
}

# As root every file can be read, so this half has a test of its own to skip.
@test "molt_render refuses a vars.sh that cannot be read, and leaves the target as it was" {
    # AT049 (ST0006 AC011).
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    local vars="$repo/instances/$(test_hostname)/vars.sh"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/app.conf" 'value = ${MOLT_TEST_VAR}'
    local target="$HOME/.config/test/app.conf"
    mkdir -p "$(dirname "$target")"
    echo "as it was" > "$target"
    chmod 000 "$vars"
    [ ! -r "$vars" ] || skip "this user can read a file whatever its mode"
    run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/app.conf.tmpl -> $target: $vars cannot be read"
    [ "$(cat "$target")" = "as it was" ]
}

# The render goes to a temporary file first, so an envsubst that fails part way
# through leaves the target as it was, and no temporary file behind.
@test "molt_render leaves the target as it was, and no temporary file, when envsubst fails" {
    # AT050 (ST0006 AC015).
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/app.conf" 'value = ${MOLT_TEST_VAR}'
    local target="$HOME/.config/test/app.conf"
    mkdir -p "$(dirname "$target")" "$BATS_TEST_TMPDIR/stub"
    echo "as it was" > "$target"
    printf '#!/bin/sh\necho partial\nexit 1\n' > "$BATS_TEST_TMPDIR/stub/envsubst"
    chmod +x "$BATS_TEST_TMPDIR/stub/envsubst"
    PATH="$BATS_TEST_TMPDIR/stub:$PATH" run molt_render "$repo/config/test/app.conf.tmpl" "$target"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/app.conf.tmpl -> $target"
    [ "$(cat "$target")" = "as it was" ]
    [ ! -e "$target.molt-tmp" ]
}

# vars.sh is sourced as a profile is. Under molt's nounset an unset variable in
# it stopped the render, and what it had printed was moved in as the file. A
# declare -x in it makes a local of the function that sources it, so it is
# sourced where it is read (critic-shell, 21 Oct).
@test "molt_render renders past an unset variable in vars.sh, reads what it declare -x's, and leaves out what it prints" {
    # AT051 (ST0006 AC015).
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    local vars_dir="$repo/instances/$(test_hostname)"
    mkdir -p "$vars_dir"
    printf 'echo chatter\nexport MOLT_A=one\nexport MOLT_B="$MOLT_TEST_UNSET"\ndeclare -x MOLT_C=three\n' > "$vars_dir/vars.sh"
    create_test_template "$repo" "config/test/lenient.conf" 'a = ${MOLT_A} c = ${MOLT_C}'
    local target="$HOME/.config/test/lenient.conf"
    run molt_render "$repo/config/test/lenient.conf.tmpl" "$target"
    assert_success
    [ "$(cat "$target")" = "a = one c = three" ]
    run molt_instance_var MOLT_C
    assert_success
    [ "$output" = "three" ]
}

# BASH_ENV is read first by every bash molt starts, and its errors would be
# blamed on vars.sh (critic-shell, 21 Oct).
@test "a BASH_ENV that does not parse, or that exits, is not blamed on vars.sh" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    echo 'fi' > "$BATS_TEST_TMPDIR/bash-env"
    BASH_ENV="$BATS_TEST_TMPDIR/bash-env" run molt_instance_var MOLT_TEST_VAR
    assert_success
    [ "$output" = "hello-world" ]
    echo 'exit 3' > "$BATS_TEST_TMPDIR/bash-env"
    BASH_ENV="$BATS_TEST_TMPDIR/bash-env" run molt_instance_var MOLT_TEST_VAR
    assert_success
    [ "$output" = "hello-world" ]
}

@test "molt_render idempotent re-render produces same output without duplicate backups" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/idem.conf" 'val = ${MOLT_FONT_SIZE}'

    local target="$HOME/.config/test/idem.conf"

    # First render
    molt_render "$repo/config/test/idem.conf.tmpl" "$target"
    assert_file_exists "$target"
    assert_file_exists "${target}.molt-rendered"

    # Second render (idempotent)
    molt_render "$repo/config/test/idem.conf.tmpl" "$target"
    assert_file_exists "$target"

    # Should NOT have a backup (second render replaces first render, no backup)
    local backup_count
    backup_count="$(find "$HOME/.config/test/" -name '*.molt-backup.*' 2>/dev/null | wc -l)"
    [[ "$backup_count" -eq 0 ]]
}

@test "molt_render creates .molt-rendered marker with provenance" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/marker.conf" 'test'

    local target="$HOME/.config/test/marker.conf"
    molt_render "$repo/config/test/marker.conf.tmpl" "$target"

    assert_file_exists "${target}.molt-rendered"
    local marker
    marker="$(cat "${target}.molt-rendered")"
    [[ "$marker" == *"rendered"* ]]
    [[ "$marker" == *"marker.conf.tmpl"* ]]
}

@test "molt_render backs up existing non-rendered file" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/existing.conf" 'new content'

    local target="$HOME/.config/test/existing.conf"
    mkdir -p "$(dirname "$target")"
    echo "original content" > "$target"

    molt_render "$repo/config/test/existing.conf.tmpl" "$target"

    # Original should have been backed up
    local backup_count
    backup_count="$(find "$HOME/.config/test/" -name '*.molt-backup.*' 2>/dev/null | wc -l)"
    [[ "$backup_count" -eq 1 ]]

    # New content should be in place
    local content
    content="$(cat "$target")"
    [[ "$content" == *"new content"* ]]
}

# --- molt_install_config tests ---

@test "molt_install_config picks render for .tmpl file" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/pick.conf" 'rendered = ${MOLT_FONT_SIZE}'

    local target="$HOME/.config/test/pick.conf"
    run molt_install_config "config/test/pick.conf" "$target"
    assert_success
    assert_output_contains "Rendered"

    local content
    content="$(cat "$target")"
    [[ "$content" == *"rendered = 14"* ]]
    assert_file_exists "${target}.molt-rendered"
}

@test "molt_install_config picks link for static file" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    # config/zsh/zshrc already exists from create_test_repo (static file, no .tmpl)

    local target="$HOME/.zshrc"
    run molt_install_config "config/zsh/zshrc" "$target"
    assert_success
    assert_output_contains "Linked"
    assert_symlink_exists "$target"
}

@test "molt_install_config with neither template nor static warns and returns 1" {
    _use_test_repo
    local target="$HOME/.config/test/missing.conf"
    run molt_install_config "config/nonexistent/file.conf" "$target"
    assert_failure
    assert_output_contains "Config not found"
}

# The @@MOLT:BEGIN@@ contract: what a user writes above the marker survives a
# render. It had no test, and a render whose own text came above the marker
# had that text kept and written again under it at every render
# (critic-shell, 21 Oct), so the region is kept only for a render that opens
# with the marker, as the ssh templates do.
@test "molt_render keeps the lines above @@MOLT:BEGIN@@ for a render that opens with it, and copies nothing for one with text of its own above it" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser" target="$HOME/.config/test/kept.conf"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/kept.conf" '# @@MOLT:BEGIN@@ managed by molt
size ${MOLT_FONT_SIZE}'
    molt_render "$repo/config/test/kept.conf.tmpl" "$target" >/dev/null
    { echo "Host mine"; cat "$target"; } > "$target.new" && mv "$target.new" "$target"
    sed -i.bak 's/MOLT_FONT_SIZE=14/MOLT_FONT_SIZE=15/' "$repo/instances/$(test_hostname)/vars.sh"
    run molt_render "$repo/config/test/kept.conf.tmpl" "$target"
    assert_success
    assert_output_contains "Preserved 1 line(s) above @@MOLT:BEGIN@@"
    [ "$(cat "$target")" = "$(printf 'Host mine\n# @@MOLT:BEGIN@@ managed by molt\nsize 15')" ]
    # The kept lines go in before the compare: a render that writes the same
    # file again backs nothing up (critic-shell, 21 Oct).
    local backups
    backups="$(find "$HOME/.config/test" -name 'kept.conf.molt-backup.*' | wc -l | tr -d ' ')"
    echo 'export MOLT_UNUSED=1' >> "$repo/instances/$(test_hostname)/vars.sh"
    run molt_render "$repo/config/test/kept.conf.tmpl" "$target"
    assert_success
    refute_output_contains "backing up"
    [ "$(find "$HOME/.config/test" -name 'kept.conf.molt-backup.*' | wc -l | tr -d ' ')" = "$backups" ]
    # A render that no longer opens with the marker keeps nothing, and says so.
    create_test_template "$repo" "config/test/kept.conf" '# a header now
# @@MOLT:BEGIN@@ managed by molt
size ${MOLT_FONT_SIZE}'
    run molt_render "$repo/config/test/kept.conf.tmpl" "$target"
    assert_success
    assert_output_contains "1 line(s) above @@MOLT:BEGIN@@ in $target are not kept: the new render does not open with the marker, so they are in $target.molt-backup."
    grep -qx "Host mine" "$target".molt-backup.*

    create_test_template "$repo" "config/test/header.conf" '# a header of its own
# @@MOLT:BEGIN@@ managed by molt
size ${MOLT_FONT_SIZE}'
    target="$HOME/.config/test/header.conf"
    molt_render "$repo/config/test/header.conf.tmpl" "$target" >/dev/null
    sed -i.bak 's/MOLT_FONT_SIZE=15/MOLT_FONT_SIZE=16/' "$repo/instances/$(test_hostname)/vars.sh"
    run molt_render "$repo/config/test/header.conf.tmpl" "$target"
    assert_success
    refute_output_contains "Preserved"
    # Its own lines above the marker are in the new render: nothing is lost,
    # and nothing is said to be (critic-shell, 21 Oct).
    refute_output_contains "are not kept"
    [ "$(grep -c '^# a header of its own$' "$target")" -eq 1 ]
}

# The render's subshell writes nothing to its caller, whose capture is the
# reason a failure is given: an EXIT trap set in vars.sh would speak in it
# (critic-shell, 21 Oct).
@test "a failed render's reason holds nothing an EXIT trap in vars.sh prints" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    create_test_vars "$repo"
    echo "trap 'echo vars-trap-said' EXIT" >> "$repo/instances/$(test_hostname)/vars.sh"
    create_test_template "$repo" "config/test/unreadable.conf" 'v = ${MOLT_TEST_VAR}'
    [ "$(id -u)" -ne 0 ] || skip "root reads a file whatever its mode"
    chmod 000 "$repo/config/test/unreadable.conf.tmpl"
    run molt_render "$repo/config/test/unreadable.conf.tmpl" "$HOME/.config/test/unreadable.conf"
    chmod 644 "$repo/config/test/unreadable.conf.tmpl"
    assert_failure
    assert_output_contains "Could not render $repo/config/test/unreadable.conf.tmpl"
    refute_output_contains "vars-trap-said"
}

# A backup is named for its second, and a second render in the same second took
# the first one's name, and mv put the newer backup over the older with no word
# (critic-shell, 21 Oct).
@test "two backups made in the same second are both kept" {
    _use_test_repo
    local repo="$BATS_TEST_TMPDIR/molt-testuser" target="$HOME/.config/test/twice.conf"
    mkdir -p "$BATS_TEST_TMPDIR/stub"
    printf '#!/bin/sh\necho 20261021000000\n' > "$BATS_TEST_TMPDIR/stub/date"
    chmod +x "$BATS_TEST_TMPDIR/stub/date"
    create_test_vars "$repo"
    create_test_template "$repo" "config/test/twice.conf" 'v = ${MOLT_TEST_VAR}'
    molt_render "$repo/config/test/twice.conf.tmpl" "$target" >/dev/null
    echo "first edit" >> "$target"
    PATH="$BATS_TEST_TMPDIR/stub:$PATH" molt_render "$repo/config/test/twice.conf.tmpl" "$target" >/dev/null
    echo "second edit" >> "$target"
    PATH="$BATS_TEST_TMPDIR/stub:$PATH" molt_render "$repo/config/test/twice.conf.tmpl" "$target" >/dev/null
    grep -qx "first edit" "$target.molt-backup.20261021000000"
    grep -qx "second edit" "$target.molt-backup.20261021000000.1"
}
