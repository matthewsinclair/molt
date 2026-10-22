#!/usr/bin/env bats
# tiling.bats — tiling liberator (Tactile's gsettings schema, issue 0014)

load "../test_helper.bash"

# Writes the fake tool $1, read from stdin, onto the test's own PATH dir.
_fake() {
    cat > "$BATS_TEST_TMPDIR/bin/$1"
    chmod +x "$BATS_TEST_TMPDIR/bin/$1"
}

# A Linux sleeve with Tactile installed, in a HOME of the test's own, with
# fakes for the GNOME tools and sudo (install_fake_sudo) on PATH. Each fake
# logs what it was asked to do.
_tactile_sleeve() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_SYSTEM_SCHEMA_DIR="$BATS_TEST_TMPDIR/system-schemas"
    export FAKE_LOG="$BATS_TEST_TMPDIR/calls"
    local ext="$HOME/.local/share/gnome-shell/extensions/tactile@lundal.io"
    mkdir -p "$ext/schemas" "$MOLT_SYSTEM_SCHEMA_DIR" "$BATS_TEST_TMPDIR/bin"
    printf '<schemalist>v38</schemalist>\n' > "$ext/schemas/org.gnome.shell.extensions.tactile.gschema.xml"

    install_fake_sudo
    _fake glib-compile-schemas <<'FAKE'
#!/usr/bin/env bash
echo "glib-compile-schemas $*" >> "$FAKE_LOG"
[ "$1" = --strict ] && exit "${FAKE_VALIDATE_STATUS:-0}"
exit "${FAKE_COMPILE_STATUS:-0}"
FAKE
    _fake gnome-extensions <<'FAKE'
#!/usr/bin/env bash
[ "$1" = info ] && echo "  State: ACTIVE"
exit 0
FAKE
    _fake gsettings <<'FAKE'
#!/usr/bin/env bash
[ "$1" = get ] && { echo 1; exit 0; }
echo "gsettings $*" >> "$FAKE_LOG"
exit "${FAKE_GSETTINGS_STATUS:-0}"
FAKE
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    load_liberator tiling
    molt_platform() { echo linux; }
    # No user repo, so the activation binding is the default rather than
    # whatever this machine's own vars.sh declares.
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/no-repo")
}

@test "the schema fault is empty when the system copy is the installed extension's" {
    _tactile_sleeve
    cp "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/"
    run _tiling_schema_fault
    assert_success
    [ -z "$output" ]
}

# cmp exits 2, not 1, when it cannot compare. Read as "differs", that would
# have install overwrite a copy the check never actually looked at.
@test "the schema fault says it cannot tell when the system copy cannot be read" {
    _tactile_sleeve
    cp "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/"
    chmod 000 "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
    run _tiling_schema_fault
    chmod 644 "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
    assert_failure
    assert_output_contains "cannot be checked: cmp could not compare"
}

@test "tiling check and verify pass when Tactile is active, configured, and its schema is the extension's" {
    _tactile_sleeve
    cp "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/"
    run tiling_check
    assert_success
    run tiling_verify
    assert_success
    assert_output_contains "Verified: tiling liberator is fully operational"
}

@test "tiling check and verify report a system schema that is not the installed extension's" {
    _tactile_sleeve
    printf '<schemalist>v37</schemalist>\n' > "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
    run tiling_check
    assert_failure
    assert_output_contains "Tactile's gsettings schema in $MOLT_SYSTEM_SCHEMA_DIR is not the installed extension's"
    run tiling_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: Tactile's gsettings schema in $MOLT_SYSTEM_SCHEMA_DIR is not the installed extension's"
}

# kovacs, 16 Oct: install copied the schema only when none was there, so a
# Tactile update would never have reached it.
@test "tiling install refreshes a stale system schema and recompiles it" {
    _tactile_sleeve
    printf '<schemalist>v37</schemalist>\n' > "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
    run tiling_install
    assert_success
    assert_output_contains "Liberator complete: tiling"
    cmp -s "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
    grep -qx "glib-compile-schemas $MOLT_SYSTEM_SCHEMA_DIR/" "$FAKE_LOG"
}

@test "tiling install fails, and does not say complete, when the schema cannot be installed" {
    _tactile_sleeve
    export FAKE_SUDO_STATUS=1
    run tiling_install
    assert_failure
    assert_output_contains "could not install Tactile's gsettings schema"
    refute_output_contains "Liberator complete"
}

@test "tiling install fails, and does not say complete, when a setting cannot be written" {
    _tactile_sleeve
    cp "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/"
    export FAKE_GSETTINGS_STATUS=1
    run tiling_install
    assert_failure
    assert_output_contains "could not set Tactile's col-0"
    refute_output_contains "Liberator complete"
}

# critic-shell, 21 Oct: a vars.sh molt cannot read is not a sleeve that wants
# the default binding.
@test "tiling install fails, saying why, and writes no setting, when vars.sh cannot be read" {
    _tactile_sleeve
    cp "$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML" "$MOLT_SYSTEM_SCHEMA_DIR/"
    local repo="$BATS_TEST_TMPDIR/repo" host
    host="$(test_hostname)"
    mkdir -p "$repo/config" "$repo/instances/$host"
    printf 'fi\nexport MOLT_TACTILE_ACTIVATE="<Super>t"\n' > "$repo/instances/$host/vars.sh"
    MOLT_USER_REPO_SEARCH_PATHS=("$repo")
    run tiling_install
    assert_failure
    assert_output_contains "tiling: the activation binding could not be read: $repo/instances/$host/vars.sh does not parse"
    refute_output_contains "Liberator complete"
    [ -z "$(grep 'gsettings set' "$FAKE_LOG" 2>/dev/null)" ]
}

# gsettings reads the compiled database. A copy left behind after a failed
# compile would match the extension's XML, and the next check would pass over
# the old database.
@test "tiling install takes its copy back out when the compile fails, so the fault stays visible" {
    _tactile_sleeve
    export FAKE_COMPILE_STATUS=1
    run tiling_install
    assert_failure
    assert_output_contains "so Tactile's copy was taken back out"
    refute_output_contains "Liberator complete"
    run _tiling_schema_fault
    assert_output_contains "is not installed"
}

@test "tiling install does not install an extension schema that does not compile" {
    _tactile_sleeve
    export FAKE_VALIDATE_STATUS=1
    run tiling_install
    assert_failure
    assert_output_contains "does not compile, so it was not installed"
    [ ! -e "$MOLT_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML" ]
}
