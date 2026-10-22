#!/usr/bin/env bats
# keys.bats — keys liberator: keyd's build, service and config (issues 0033, 0034)

load "../test_helper.bash"

# A Linux sleeve with keyd installed and running, a user repo whose instance
# carries a keyd config, and MOLT_KEYD_CONFIG in the test's own directory, so
# nothing under /etc is read or written. keyd and systemctl are fakes that log
# what they were asked to do: systemctl reports keyd active unless
# FAKE_KEYD_INACTIVE is set, and fails enable or start when FAKE_ENABLE_STATUS
# or FAKE_START_STATUS says so; keyd fails reload with FAKE_RELOAD_STATUS. sudo
# is install_fake_sudo's.
_keyd_sleeve() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_KEYD_CONFIG="$BATS_TEST_TMPDIR/etc/keyd/default.conf"
    export FAKE_LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
    install_fake_sudo
    cat > "$BATS_TEST_TMPDIR/bin/keyd" <<'FAKE'
#!/usr/bin/env bash
echo "keyd $*" >> "$FAKE_LOG"
[ "$1" = reload ] && exit "${FAKE_RELOAD_STATUS:-0}"
exit 0
FAKE
    cat > "$BATS_TEST_TMPDIR/bin/systemctl" <<'FAKE'
#!/usr/bin/env bash
echo "systemctl $*" >> "$FAKE_LOG"
case "$1" in
  is-active) [ -z "${FAKE_KEYD_INACTIVE:-}" ] || exit 3 ;;
  enable) exit "${FAKE_ENABLE_STATUS:-0}" ;;
  start) exit "${FAKE_START_STATUS:-0}" ;;
esac
exit 0
FAKE
    chmod +x "$BATS_TEST_TMPDIR/bin/keyd" "$BATS_TEST_TMPDIR/bin/systemctl"

    REPO="$BATS_TEST_TMPDIR/repo"
    CONF="$REPO/instances/$(test_hostname)/keyd/default.conf"
    mkdir -p "$(dirname "$CONF")"
    printf '[ids]\n*\n\n[main]\ncapslock = overload(control, esc)\n' > "$CONF"
    load_liberator keys
    molt_platform() { echo linux; }
    eval "molt_find_user_repo() { echo \"$REPO\"; }"
}

@test "keys install puts the instance's keyd config in place through molt_sudo_install, mode 644, then reloads keyd" {
    _keyd_sleeve
    run keys_install
    assert_success
    assert_output_contains "Liberator complete: keys"
    cmp "$CONF" "$MOLT_KEYD_CONFIG"
    [ "$(test_file_mode "$MOLT_KEYD_CONFIG")" = 644 ]
    grep -q "^sudo install -m 644 .* $MOLT_KEYD_CONFIG\$" "$BATS_TEST_TMPDIR/sudo.log"
    grep -qx "keyd reload" "$FAKE_LOG"
}

@test "keys install fails, saying why, and neither reloads keyd nor says complete, when sudo refuses" {
    _keyd_sleeve
    FAKE_SUDO_STATUS=1 run keys_install
    assert_failure
    assert_output_contains "keys: the keyd config was not installed: sudo could not install $MOLT_KEYD_CONFIG"
    refute_output_contains "Liberator complete"
    [ ! -e "$MOLT_KEYD_CONFIG" ]
    [ ! -e "$FAKE_LOG" ] || ! grep -qx "keyd reload" "$FAKE_LOG"
}

@test "keys check looks for the config where install puts it" {
    _keyd_sleeve
    run keys_check
    assert_failure
    assert_output_contains "keys: keyd config not present"
    keys_install >/dev/null
    run keys_check
    assert_success
}

# --- Issue 0034: each command keys runs is checked, and named when it fails ---

# A sleeve with no keyd yet: keys builds it from a clone. git, make and gcc are
# fakes; git fails the clone with FAKE_CLONE_STATUS; make fails `make install` with FAKE_INSTALL_STATUS, and otherwise puts
# the keyd fake on PATH, as the real install does. mktemp's directory
# goes under the test's own TMPDIR, so what is left behind can be seen.
_keyd_unbuilt() {
    _keyd_sleeve
    mv "$BATS_TEST_TMPDIR/bin/keyd" "$BATS_TEST_TMPDIR/keyd.built"
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    mkdir -p "$TMPDIR"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<'FAKE'
#!/usr/bin/env bash
echo "git $*" >> "$FAKE_LOG"
[ "${FAKE_CLONE_STATUS:-0}" -eq 0 ] || exit "$FAKE_CLONE_STATUS"
mkdir -p "${@: -1}"
FAKE
    cat > "$BATS_TEST_TMPDIR/bin/make" <<'FAKE'
#!/usr/bin/env bash
echo "make $*" >> "$FAKE_LOG"
if [ "${1:-}" = install ]; then
  [ "${FAKE_INSTALL_STATUS:-0}" -eq 0 ] || exit "$FAKE_INSTALL_STATUS"
  cp "$BATS_TEST_TMPDIR/keyd.built" "$BATS_TEST_TMPDIR/bin/keyd"
fi
exit 0
FAKE
    printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/bin/gcc"
    chmod +x "$BATS_TEST_TMPDIR/bin/git" "$BATS_TEST_TMPDIR/bin/make" "$BATS_TEST_TMPDIR/bin/gcc"
}

@test "keys install fails, naming it, and goes no further, when keyd cannot be built and installed, and leaves no clone behind" {
    _keyd_unbuilt
    command -v keyd >/dev/null && skip "this machine has a keyd of its own"
    FAKE_INSTALL_STATUS=1 run keys_install
    assert_failure
    assert_output_contains "keys: keyd could not be built and installed from source"
    refute_output_contains "Liberator complete"
    grep -qx "make install" "$FAKE_LOG"
    [ ! -e "$MOLT_KEYD_CONFIG" ]
    run grep -c "^systemctl " "$FAKE_LOG"
    [ "$output" = 0 ]
    [ -z "$(ls -A "$TMPDIR")" ]

    # A clone that fails, the likeliest failure, is named as the clone.
    rm -f "$FAKE_LOG"
    FAKE_CLONE_STATUS=128 run keys_install
    assert_failure
    assert_output_contains "keys: keyd could not be cloned from https://github.com/rvaiya/keyd"
    refute_output_contains "Liberator complete"
    [ ! -e "$FAKE_LOG" ] || ! grep -q "^make" "$FAKE_LOG"
    [ -z "$(ls -A "$TMPDIR")" ]
}

@test "keys install fails, naming it, when the keyd service cannot be enabled or started, and goes no further" {
    _keyd_sleeve
    export FAKE_KEYD_INACTIVE=1
    FAKE_ENABLE_STATUS=1 run keys_install
    assert_failure
    assert_output_contains "keys: the keyd service could not be enabled"
    refute_output_contains "Liberator complete"
    run grep -cx "systemctl start keyd" "$FAKE_LOG"
    [ "$output" = 0 ]
    [ ! -e "$MOLT_KEYD_CONFIG" ]

    rm -f "$FAKE_LOG"
    FAKE_START_STATUS=1 run keys_install
    assert_failure
    grep -qx "systemctl enable keyd" "$FAKE_LOG"
    grep -qx "systemctl start keyd" "$FAKE_LOG"
    assert_output_contains "keys: the keyd service could not be started"
    refute_output_contains "Liberator complete"
    [ ! -e "$MOLT_KEYD_CONFIG" ]
}

@test "keys install fails, naming it, when keyd does not reload the config it installed" {
    _keyd_sleeve
    FAKE_RELOAD_STATUS=1 run keys_install
    assert_failure
    assert_output_contains "keys: the keyd config is in place at $MOLT_KEYD_CONFIG, but keyd did not reload it"
    refute_output_contains "Liberator complete"
}

@test "keys install builds keyd, enables and starts its service, and reloads its config when each succeeds" {
    _keyd_unbuilt
    command -v keyd >/dev/null && skip "this machine has a keyd of its own"
    export FAKE_KEYD_INACTIVE=1
    run keys_install
    assert_success
    assert_output_contains "Liberator complete: keys"
    grep -qx "make install" "$FAKE_LOG"
    grep -qx "systemctl enable keyd" "$FAKE_LOG"
    grep -qx "systemctl start keyd" "$FAKE_LOG"
    grep -qx "keyd reload" "$FAKE_LOG"
    [ -z "$(ls -A "$TMPDIR")" ]
}
