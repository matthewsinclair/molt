#!/usr/bin/env bats
# alacritty.bats — Tests for the alacritty liberator's config check, install and
# verify, in both the template and the linked form.
#
# The liberator had no tests, and its template arm passed molt_config_stale an
# absolute .tmpl path. molt_config_stale looked for <repo>/<abs>.tmpl.tmpl, found
# nothing and answered "not stale", so on kovacs ~/.config/alacritty/alacritty.toml
# was a dangling link for a week while resleeve reported alacritty ok (issue 0007).

load "../test_helper.bash"

_alac_env() {
    load_liberator alacritty
    local root="$BATS_TEST_TMPDIR"
    local host; host="$(test_hostname)"

    export HOME="$root/home"
    mkdir -p "$HOME" "$root/repo/config/alacritty" "$root/repo/instances/$host" "$root/bin"
    printf 'export MOLT_FONT_FAMILY="Test Mono"\n' > "$root/repo/instances/$host/vars.sh"
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    ALAC_REPO="$root/repo"
    ALAC_TARGET="$HOME/.config/alacritty/alacritty.toml"

    # Installed, and not on GNOME: the dock-favourites arm is not under test.
    printf '#!/usr/bin/env bash\nexit 0\n' > "$root/bin/alacritty"
    chmod +x "$root/bin/alacritty"
    export PATH="$root/bin:$PATH"
    molt_platform() { echo "macos"; }
}

_alac_template() {
    # Single quotes: the template must keep its ${MOLT_FONT_FAMILY} for envsubst.
    # shellcheck disable=SC2016
    printf '[font.normal]\nfamily = "${MOLT_FONT_FAMILY}"\n' > "$ALAC_REPO/config/alacritty/alacritty.toml.tmpl"
}

# --- Template form ---

# The kovacs state: the repo renamed the config to .tmpl, and the old link to
# the static file was left behind, pointing at nothing.
@test "alacritty_check flags a template config whose target is a dangling link" {
    _alac_env
    _alac_template
    mkdir -p "$(dirname "$ALAC_TARGET")"
    ln -s "$ALAC_REPO/config/alacritty/alacritty.toml" "$ALAC_TARGET"

    run alacritty_check
    assert_failure
    assert_output_contains "re-rendering"
    run alacritty_verify
    assert_failure
    assert_output_contains "VERIFY FAIL"
}

@test "alacritty_check flags a template config that was never rendered" {
    _alac_env
    _alac_template

    run alacritty_check
    assert_failure
}

@test "alacritty_install renders over a dangling link, then check and verify pass" {
    require_command envsubst "rendering a template needs envsubst (gettext)"
    _alac_env
    _alac_template
    mkdir -p "$(dirname "$ALAC_TARGET")"
    ln -s "$ALAC_REPO/config/alacritty/alacritty.toml" "$ALAC_TARGET"

    run alacritty_install
    assert_success
    [[ -f "$ALAC_TARGET" && ! -L "$ALAC_TARGET" ]]
    run cat "$ALAC_TARGET"
    assert_output_contains 'family = "Test Mono"'

    run alacritty_check
    assert_success
    run alacritty_verify
    assert_success
}

@test "alacritty_check flags a rendered config once its template changes" {
    require_command envsubst "rendering a template needs envsubst (gettext)"
    _alac_env
    _alac_template
    alacritty_install >/dev/null 2>&1
    run alacritty_check
    assert_success

    printf 'size = 14\n' >> "$ALAC_REPO/config/alacritty/alacritty.toml.tmpl"
    run alacritty_check
    assert_failure
}

# The install ignored molt_install_config's return, so a render that failed
# still ended on "Liberator complete" and resleeve showed alacritty installed
# (issue 0019).
@test "alacritty_install fails when its config render fails" {
    _alac_env
    _alac_template
    molt_render() { molt_error "render refused: $1"; return 1; }

    run alacritty_install
    assert_failure
    assert_output_contains "render refused"
    refute_output_contains "Liberator complete"
}

# gsettings set's status was dropped, so a dock favourite that was never added
# was reported added, and the install complete (issue 0021).
@test "alacritty_install fails when gsettings cannot add the dock favourite" {
    _alac_env
    molt_platform() { echo "linux"; }
    # get answers with a favourites list; set fails.
    cat > "$BATS_TEST_TMPDIR/bin/gsettings" <<'EOF'
#!/bin/sh
[ "$1" = get ] && { echo "['org.gnome.Nautilus.desktop']"; exit 0; }
exit 1
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/gsettings"

    run alacritty_install
    assert_failure
    assert_output_contains "gsettings could not add Alacritty"
    refute_output_contains "Liberator complete"
}

# --- Linked form ---

@test "alacritty_check passes a healthy link and flags a dangling one" {
    _alac_env
    printf '[font]\nsize = 13\n' > "$ALAC_REPO/config/alacritty/alacritty.toml"
    alacritty_install >/dev/null 2>&1
    run alacritty_check
    assert_success

    ln -sfn "$BATS_TEST_TMPDIR/nowhere.toml" "$ALAC_TARGET"
    run alacritty_check
    assert_failure
    assert_output_contains "broken symlink"
}

# --- molt_config_stale refuses the call shape that hid this ---

# An absolute or .tmpl source cannot name a template, so answering "not stale"
# for it is a silent pass. It now says so and answers stale, the same fail-closed
# direction as its other can't-tell paths.
@test "molt_config_stale refuses an absolute source and fails closed" {
    _alac_env
    _alac_template
    run molt_config_stale "$ALAC_REPO/config/alacritty/alacritty.toml" "$ALAC_TARGET"
    assert_success
    assert_output_contains "repo-relative"
}

@test "molt_config_stale refuses a .tmpl source and fails closed" {
    _alac_env
    _alac_template
    run molt_config_stale "config/alacritty/alacritty.toml.tmpl" "$ALAC_TARGET"
    assert_success
    assert_output_contains "without .tmpl"
}
