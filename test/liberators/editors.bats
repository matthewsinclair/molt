#!/usr/bin/env bats
# editors.bats — editors liberator (straight.el build-tree hygiene)

load "../test_helper.bash"

_make_straight() {
    local root="$1" version="$2"
    mkdir -p "$root/build-${version}/cider"
    : > "$root/build-${version}/cider/cider-history.el"
    ln -s "$root/build-${version}/cider/cider-history.el" \
          "$root/build-${version}/cider/cider-good.el"
}

@test "_editors_warn_stale_straight_links is silent on a clean build tree" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight1"
    _make_straight "$root" "31.1"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "_editors_warn_stale_straight_links reports a dangling build link" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight2"
    _make_straight "$root" "31.1"
    # Exactly kovacs's failure: upstream renamed the file, straight did not prune.
    ln -s "$root/build-31.1/cider/cider-repl-history.el" \
          "$root/build-31.1/cider/cider-repl-history-link.el"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    assert_output_contains "cider-repl-history-link.el"
    assert_output_contains "did not prune"
}

@test "_editors_warn_stale_straight_links ignores orphaned build dirs for other versions" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight3"
    _make_straight "$root" "31.1"
    mkdir -p "$root/build-31.0.91/cider"
    ln -s "$root/build-31.0.91/cider/gone.el" "$root/build-31.0.91/cider/stale.el"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ -z "$output" ]
}

@test "_editors_warn_stale_straight_links is silent when there is no straight dir" {
    load_liberator editors
    MOLT_STRAIGHT_DIR="$BATS_TEST_TMPDIR/nope" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- doom sync (issue 0013) ---

# A doom that records each call and fails the subcommand FAKE_DOOM_FAIL names,
# saying so on stderr as Doom would, in a HOME and DOOMLOCALDIR of the test's
# own. %q keeps one argument with a space in it apart from two arguments.
_fake_doom() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export DOOMLOCALDIR="$HOME/.config/emacs/.local"
    mkdir -p "$HOME/.config/emacs/bin" "$DOOMLOCALDIR/etc"
    cat > "$HOME/.config/emacs/bin/doom" <<'DOOM'
#!/usr/bin/env bash
{ printf 'doom'; printf ' %q' "$@"; echo; } >> "$HOME/doom.calls"
if [ "$1" = "${FAKE_DOOM_FAIL:-}" ]; then
    echo "doom: $1 failed" >&2
    exit 1
fi
DOOM
    chmod +x "$HOME/.config/emacs/bin/doom"
}

# Doom's record of the Emacs it last synced under, in Doom's own format.
_doom_synced_under() {
    printf '("%s" . "bfd10121412b33d1dd5a0109e56d1cb6")' "$1" > "$DOOMLOCALDIR/etc/sync"
}

# kovacs, 16 Oct: Emacs went from 29.3 to 30.2, doom sync asked whether to
# rebuild, read EOF and failed.
@test "doom sync rebuilds when Emacs has changed since Doom last synced" {
    _fake_doom
    _doom_synced_under "29.3"
    load_liberator editors
    MOLT_EMACS_VERSION="30.2" run _editors_doom_sync
    assert_success
    [ "$(cat "$HOME/doom.calls")" = "doom sync --rebuild" ]
}

@test "doom sync does not rebuild when Emacs is unchanged, or when Doom has no record yet" {
    _fake_doom
    load_liberator editors
    MOLT_EMACS_VERSION="30.2" run _editors_doom_sync -u
    assert_success
    _doom_synced_under "30.2"
    MOLT_EMACS_VERSION="30.2" run _editors_doom_sync -u
    assert_success
    [ "$(cat "$HOME/doom.calls")" = "$(printf 'doom sync -u\ndoom sync -u')" ]
}

@test "doom sync says so when Doom's record names no Emacs version" {
    _fake_doom
    printf 'not a record' > "$DOOMLOCALDIR/etc/sync"
    load_liberator editors
    MOLT_EMACS_VERSION="30.2" run _editors_doom_sync
    assert_success
    assert_output_contains "names no Emacs version"
    [ "$(cat "$HOME/doom.calls")" = "doom sync" ]
}

# kovacs, 16 Oct: the hook ran doom sync with its stderr thrown away, warned and
# returned 0.
@test "the editors upgrade hook rebuilds after an Emacs change, and fails with Doom's own error" {
    _fake_doom
    _doom_synced_under "29.3"
    load_liberator editors
    MOLT_EMACS_VERSION="30.2" run editors_upgrade
    assert_success
    export FAKE_DOOM_FAIL=sync
    MOLT_EMACS_VERSION="30.2" run editors_upgrade
    assert_failure
    assert_output_contains "doom: sync failed"
    assert_output_contains "editors: doom sync failed"
    [ "$(cat "$HOME/doom.calls")" = "$(printf 'doom sync --rebuild\ndoom sync --rebuild')" ]
}

@test "the editors maintain hook fails when doom upgrade fails, and still syncs" {
    _fake_doom
    _doom_synced_under "29.3"
    load_liberator editors
    export FAKE_DOOM_FAIL=upgrade
    MOLT_EMACS_VERSION="30.2" run editors_maintain
    assert_failure
    assert_output_contains "doom: upgrade failed"
    assert_output_contains "editors: doom upgrade failed"
    [ "$(cat "$HOME/doom.calls")" = "$(printf 'doom upgrade --force\ndoom sync -u --rebuild')" ]
}

@test "the editors maintain hook fails when doom sync -u fails" {
    _fake_doom
    load_liberator editors
    MOLT_EMACS_VERSION="30.2" run editors_maintain
    assert_success
    export FAKE_DOOM_FAIL=sync
    MOLT_EMACS_VERSION="30.2" run editors_maintain
    assert_failure
    assert_output_contains "doom: sync failed"
    assert_output_contains "editors: doom sync -u failed"
}

# A Doom config cloned from an origin in the test directory (issue 0015).
_doom_config_repo() {
    local origin="$BATS_TEST_TMPDIR/doom-origin"
    mkdir -p "$origin"
    : > "$origin/init.el"
    git -C "$origin" init -q
    git -C "$origin" add -A
    git -c user.name=test -c user.email=test@example.com -C "$origin" commit -qm init
    git clone -q "$origin" "$HOME/.config/doom"
    DOOM_ORIGIN="$origin"
}

@test "the editors upgrade hook warns when the Doom config has no upstream, and fails, naming the repo and git's reason, when its pull fails, syncing either way" {
    _fake_doom
    _doom_synced_under "30.2"
    _doom_config_repo
    load_liberator editors
    git -C "$HOME/.config/doom" branch -q --unset-upstream
    MOLT_EMACS_VERSION="30.2" run editors_upgrade
    assert_success
    assert_output_contains "Doom config pull skipped: $HOME/.config/doom has no upstream branch"

    git -C "$HOME/.config/doom" branch -q --set-upstream-to="origin/$(git -C "$HOME/.config/doom" branch --show-current)"
    rm -rf "$DOOM_ORIGIN" "$HOME/doom.calls"
    MOLT_EMACS_VERSION="30.2" run editors_upgrade
    assert_failure
    assert_output_contains "Doom config pull failed in $HOME/.config/doom:"
    assert_output_contains "$DOOM_ORIGIN"
    refute_output_contains "pull skipped"
    [ "$(cat "$HOME/doom.calls")" = "doom sync" ]
}
