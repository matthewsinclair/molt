#!/usr/bin/env bats
# keys.bats — keys liberator: keyd's config, written through sudo (issue 0033)

load "../test_helper.bash"

# A Linux sleeve with keyd installed and running, a user repo whose instance
# carries a keyd config, and MOLT_KEYD_CONFIG in the test's own directory, so
# nothing under /etc is read or written. keyd and systemctl are fakes that log
# what they were asked to do; sudo is install_fake_sudo's.
_keyd_sleeve() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_KEYD_CONFIG="$BATS_TEST_TMPDIR/etc/keyd/default.conf"
    export FAKE_LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
    install_fake_sudo
    printf '#!/usr/bin/env bash\necho "keyd $*" >> "$FAKE_LOG"\n' > "$BATS_TEST_TMPDIR/bin/keyd"
    printf '#!/usr/bin/env bash\necho "systemctl $*" >> "$FAKE_LOG"\n' > "$BATS_TEST_TMPDIR/bin/systemctl"
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
