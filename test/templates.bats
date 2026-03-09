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
    hostname="$(hostname)"
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
