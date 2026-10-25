#!/usr/bin/env bats
# gsettings.bats — the gsettings molt sets GNOME keys with (issue 0047)

load "test_helper.bash"

# A fake gsettings in the directory $1 that lists one schema with one key and
# keeps what it sets in $1/store. With $2 "keyfile" it has no dconf module:
# asked for dconf, it warns as GLib does, then reads its fallback and exits 0.
# Shell builtins only, so a test can run it with nothing else on PATH.
_fake_gsettings() {
    mkdir -p "$1"
    [ "${2:-}" != keyfile ] || : > "$1/no-dconf"
    cat > "$1/gsettings" <<'FAKE'
#!/bin/sh
here="${0%/*}"
case "$1" in
  list-schemas) echo org.gnome.shell ;;
  list-keys) echo favorite-apps ;;
  get)
    if [ "${GSETTINGS_BACKEND:-}" = dconf ] && [ -e "$here/no-dconf" ]; then
      printf '\n(process:1): GLib-GIO-WARNING **: Can'"'"'t find module '"'"'dconf'"'"' specified in GSETTINGS_BACKEND\n' >&2
    fi
    if [ -e "$here/store" ]; then read -r v < "$here/store"; echo "$v"; else echo "@as []"; fi ;;
  set) echo "$4" > "$here/store" ;;
esac
FAKE
    chmod +x "$1/gsettings"
}

# The two fakes each test asks: KEYFILE, which has no dconf module, and DCONF,
# which has one. Neither is on PATH until a test puts it there.
_gsettings_env() {
    load_molt_libs
    export HOME="$BATS_TEST_TMPDIR/home"
    gsettings_from_path
    KEYFILE="$BATS_TEST_TMPDIR/brew/bin"
    DCONF="$BATS_TEST_TMPDIR/usr/bin"
    _fake_gsettings "$KEYFILE" keyfile
    _fake_gsettings "$DCONF"
}

@test "molt chooses the gsettings that reaches dconf over one before it on PATH that does not" {
    _gsettings_env
    local status=0
    PATH="$KEYFILE:$DCONF" molt_gsettings_find || status=$?
    [ "$status" -eq 0 ]

    molt_gsettings set org.gnome.shell favorite-apps "['Alacritty.desktop']"
    [ "$(cat "$DCONF/store")" = "['Alacritty.desktop']" ]
    [ ! -e "$KEYFILE/store" ]
    [ "$(molt_gsettings get org.gnome.shell favorite-apps)" = "['Alacritty.desktop']" ]
}

@test "a gsettings with no dconf backend is a fault that names it, not an absent gsettings" {
    _gsettings_env
    local status=0
    PATH="$KEYFILE" molt_gsettings_find || status=$?
    [ "$status" -eq 2 ]
    [[ "$MOLT_GSETTINGS_FAULT" == *"no gsettings on PATH reaches dconf"* ]]
    [[ "$MOLT_GSETTINGS_FAULT" == *"$KEYFILE/gsettings does not read through dconf"* ]]
    [[ "$MOLT_GSETTINGS_FAULT" == *"Can't find module 'dconf'"* ]]

    run molt_gsettings set org.gnome.shell favorite-apps "['Alacritty.desktop']"
    assert_failure
    [ ! -e "$KEYFILE/store" ]
}

@test "a liberator whose only gsettings has no dconf backend reports the fault, and sets nothing" {
    _gsettings_env
    load_liberator alacritty
    molt_platform() { echo linux; }
    local tools="$BATS_TEST_TMPDIR/tools"
    mkdir -p "$tools" "$BATS_TEST_TMPDIR/repo/config"
    printf '#!/bin/sh\nexit 0\n' > "$tools/alacritty"
    chmod +x "$tools/alacritty"
    export PATH="$tools:$PATH"
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/repo")
    PATH="$KEYFILE" molt_gsettings_find || true

    run alacritty_check
    assert_failure
    assert_output_contains "alacritty: no gsettings on PATH reaches dconf"
    refute_output_contains "not installed"
    run alacritty_install
    assert_failure
    assert_output_contains "alacritty: no gsettings on PATH reaches dconf"
    refute_output_contains "Liberator complete"
    [ ! -e "$KEYFILE/store" ]
}

@test "a gsettings that fails asked for dconf and says nothing is a fault saying molt cannot tell" {
    _gsettings_env
    printf '#!/bin/sh\ncase "$1" in list-schemas) echo s ;; list-keys) echo k ;; *) exit 3 ;; esac\n' > "$KEYFILE/gsettings"
    local status=0
    PATH="$KEYFILE" molt_gsettings_find || status=$?
    [ "$status" -eq 2 ]
    [[ "$MOLT_GSETTINGS_FAULT" == *"cannot tell: asked to read s k through dconf, it exited 3 and said nothing"* ]]
}

@test "no gsettings on PATH is no GNOME, which callers pass by" {
    _gsettings_env
    local status=0
    PATH="$BATS_TEST_TMPDIR/empty" molt_gsettings_find || status=$?
    [ "$status" -eq 1 ]
    [ "$MOLT_GSETTINGS_FAULT" = "gsettings is not on PATH" ]
    run molt_gsettings_unreachable molt_info "" alacritty
    assert_success
    [ -z "$output" ]
}

@test "molt asks once per run, and keeps what it chose" {
    _gsettings_env
    PATH="$KEYFILE:$DCONF" molt_gsettings_find
    _fake_gsettings "$BATS_TEST_TMPDIR/later"
    PATH="$BATS_TEST_TMPDIR/later" molt_gsettings set org.gnome.shell favorite-apps "['Alacritty.desktop']"
    [ -e "$DCONF/store" ]
    [ ! -e "$BATS_TEST_TMPDIR/later/store" ]
}

@test "doctor names a gsettings with no dconf backend, and passes one that has it" {
    _gsettings_env
    molt_platform() { echo linux; }
    PATH="$KEYFILE" molt_gsettings_find || true
    run cmd_doctor
    assert_output_contains "Checking gsettings... ⚠ no gsettings on PATH reaches dconf, the store GNOME reads: $KEYFILE/gsettings does not read through dconf"

    gsettings_from_path
    PATH="$KEYFILE:$DCONF" molt_gsettings_find
    run cmd_doctor
    grep -qxF -- "Checking gsettings... ✓ found, and it reaches dconf" <<< "$output"
}
