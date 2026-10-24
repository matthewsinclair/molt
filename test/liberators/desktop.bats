#!/usr/bin/env bats
# desktop.bats — desktop liberator (GTK stylesheet + GNOME dock favourites)

load "../test_helper.bash"

# --- Dock favourites ---

@test "_desktop_favorites_wanted formats a GVariant string array" {
    load_liberator desktop
    local f="$BATS_TEST_TMPDIR/favs"
    printf 'Alacritty.desktop\norg.gnome.Nautilus.desktop\n' > "$f"
    run _desktop_favorites_wanted "$f"
    [ "$output" = "['Alacritty.desktop', 'org.gnome.Nautilus.desktop']" ]
}

@test "_desktop_favorites_wanted ignores comments, blanks and stray whitespace" {
    load_liberator desktop
    local f="$BATS_TEST_TMPDIR/favs2"
    printf '# the terminal must be first\n\n  Alacritty.desktop  \n\n# browser\nfirefox.desktop\n' > "$f"
    run _desktop_favorites_wanted "$f"
    [ "$output" = "['Alacritty.desktop', 'firefox.desktop']" ]
}

@test "_desktop_favorites_wanted emits @as [] for an empty list" {
    load_liberator desktop
    local f="$BATS_TEST_TMPDIR/favs3"
    printf '# nothing pinned\n\n' > "$f"
    run _desktop_favorites_wanted "$f"
    [ "$output" = "@as []" ]
}

@test "_desktop_favorites_file returns non-zero when the instance has no file" {
    load_liberator desktop
    run _desktop_favorites_file
    [ "$status" -ne 0 ] || [ -f "$output" ]
}

# This lookup fell back to "unknown" where molt_hostname falls back to the long
# hostname, so a host whose hostname -s failed read instances/unknown/ (issue 0020).
@test "_desktop_favorites_file finds the instance by molt_hostname when hostname -s fails" {
    load_liberator desktop
    local root="$BATS_TEST_TMPDIR"
    mkdir -p "$root/bin" "$root/repo/config" "$root/repo/instances/testhost/desktop"
    # A hostname whose -s fails, as on a host with no short name to give.
    printf '#!/bin/sh\n[ "$1" = -s ] && exit 1\necho testhost.example.org\n' > "$root/bin/hostname"
    chmod +x "$root/bin/hostname"
    printf 'org.gnome.Nautilus.desktop\n' > "$root/repo/instances/testhost/desktop/favorite-apps"
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    export PATH="$root/bin:$PATH"

    run _desktop_favorites_file
    assert_success
    [ "$output" = "$root/repo/instances/testhost/desktop/favorite-apps" ]
}

@test "_desktop_favorites_empty detects a file with no usable entries" {
    load_liberator desktop
    local d="$BATS_TEST_TMPDIR"
    printf '# only comments\n\n   \n' > "$d/empty"
    printf 'Alacritty.desktop\n'      > "$d/full"

    run _desktop_favorites_empty "$d/empty"
    [ "$status" -eq 0 ]
    run _desktop_favorites_empty "$d/full"
    [ "$status" -ne 0 ]
}

@test "_desktop_favorites_wanted still emits @as [] — the guard, not the formatter, refuses it" {
    load_liberator desktop
    local d="$BATS_TEST_TMPDIR"
    printf '\n' > "$d/blank"
    run _desktop_favorites_wanted "$d/blank"
    # Confirmed against GNOME on Ubuntu 24.04 / gsettings 2.80.0: an empty
    # string array really does print "@as []", not "[]". Verified on a real
    # sleeve rather than assumed.
    [ "$output" = "@as []" ]
}

# --- Declared gsettings (issue 0035) ---
#
# The liberator set ten GNOME keys written into it, each ending
# "2>/dev/null || true", so a key that did not take was silent and check read
# back only overlay-key. The pairs now come from instances/<host>/desktop/gsettings.

# A sleeve on GNOME with a user repo holding $1 as its gsettings file (no file
# when $1 is empty). The fake gsettings keeps each key in GS_STORE/<schema>/<key>,
# logs each set to GS_LOG, refuses a set when GS_STORE/<schema>/<key>.refuse
# exists, and stores the contents of GS_STORE/<schema>/<key>.mangle in place of
# the value it was given when that exists, as GNOME does with a value it rewrites.
_gs_env() {
    load_liberator desktop
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    export GS_STORE="$root/gs" GS_LOG="$root/gs.log"
    mkdir -p "$HOME" "$GS_STORE" "$root/bin" "$root/repo/config" "$root/repo/instances/$(test_hostname)/desktop"
    GS_FILE="$root/repo/instances/$(test_hostname)/desktop/gsettings"
    [ -z "${1:-}" ] || printf '%s\n' "$1" > "$GS_FILE"
    # A stylesheet to link, so whether install went on past the keys shows.
    mkdir -p "$root/repo/config/gtk"
    : > "$root/repo/config/gtk/gtk.css"
    cat > "$root/bin/gsettings" <<'FAKE'
#!/bin/sh
d="$GS_STORE/$2"
case "$1" in
  list-schemas) echo molt.probe ;;
  list-keys) echo k ;;
  set)
    echo "set $2 $3 $4" >> "$GS_LOG"
    if [ -e "$d/$3.refuse" ]; then echo "No such key “$3”" >&2; exit 1; fi
    mkdir -p "$d"
    if [ -e "$d/$3.mangle" ]; then cp "$d/$3.mangle" "$d/$3"; else printf '%s\n' "$4" > "$d/$3"; fi ;;
  get)
    if [ -e "$d/$3" ]; then cat "$d/$3"; else echo "No such key “$3”" >&2; exit 1; fi ;;
esac
FAKE
    chmod +x "$root/bin/gsettings"
    export PATH="$root/bin:$PATH"
    # A key for molt to ask the fake through dconf before it chooses it.
    mkdir -p "$GS_STORE/molt.probe"
    echo "'v'" > "$GS_STORE/molt.probe/k"
    gsettings_from_path
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    molt_platform() { echo linux; }
}

# What the fake holds for schema $1, key $2.
_gs_held() {
    cat "$GS_STORE/$1/$2"
}

_GS_PAIRS="# GNOME keys for this sleeve
org.gnome.mutter overlay-key ''

org.gnome.desktop.wm.keybindings switch-windows ['<Alt>Tab', '<Super>Tab']"

@test "desktop_install sets each declared key and reads it back" {
    _gs_env "$_GS_PAIRS"
    run desktop_install
    assert_success
    [ "$(_gs_held org.gnome.mutter overlay-key)" = "''" ]
    [ "$(_gs_held org.gnome.desktop.wm.keybindings switch-windows)" = "['<Alt>Tab', '<Super>Tab']" ]
    [ "$(grep -c '^set ' "$GS_LOG")" -eq 2 ]
}

@test "desktop_install fails naming the key gsettings refused, with gsettings' words" {
    _gs_env "$_GS_PAIRS"
    mkdir -p "$GS_STORE/org.gnome.mutter"
    touch "$GS_STORE/org.gnome.mutter/overlay-key.refuse"
    run desktop_install
    assert_failure
    assert_output_contains "gsettings refused org.gnome.mutter overlay-key"
    assert_output_contains "    No such key “overlay-key”"
    refute_output_contains "Liberator complete: desktop"
    # Every pair is tried, and the rest of install still runs.
    [ "$(_gs_held org.gnome.desktop.wm.keybindings switch-windows)" = "['<Alt>Tab', '<Super>Tab']" ]
    [ -L "$HOME/.config/gtk-3.0/gtk.css" ]
}

@test "desktop_install fails when a key reads back other than the file declares" {
    _gs_env "$_GS_PAIRS"
    mkdir -p "$GS_STORE/org.gnome.mutter"
    echo "'Super_L'" > "$GS_STORE/org.gnome.mutter/overlay-key.mangle"
    run desktop_install
    assert_failure
    assert_output_contains "org.gnome.mutter overlay-key did not take: wanted '', got 'Super_L'"
    refute_output_contains "Liberator complete: desktop"
    [ "$(_gs_held org.gnome.desktop.wm.keybindings switch-windows)" = "['<Alt>Tab', '<Super>Tab']" ]
    [ -L "$HOME/.config/gtk-3.0/gtk.css" ]
}

@test "a gsettings line with fewer than three fields is a fault naming the file and line" {
    _gs_env "$(printf '# keys\norg.gnome.mutter overlay-key\n')"
    run desktop_install
    assert_failure
    assert_output_contains "$GS_FILE line 2: expected <schema> <key> <value>"
    [ ! -e "$GS_LOG" ]
    [ ! -e "$HOME/.config/gtk-3.0/gtk.css" ]
}

@test "desktop_install applies nothing when the instance has no gsettings file" {
    _gs_env ""
    run desktop_install
    assert_success
    [ ! -e "$GS_LOG" ]
}

@test "desktop_check and desktop_verify name each declared key that differs" {
    _gs_env "$_GS_PAIRS"
    # Installed, then the keys moved under it, so drift is the only fault.
    desktop_install >/dev/null
    echo "'Super_L'" > "$GS_STORE/org.gnome.mutter/overlay-key"
    echo "['<Super>Tab']" > "$GS_STORE/org.gnome.desktop.wm.keybindings/switch-windows"
    run desktop_check
    assert_failure
    assert_output_contains "desktop: org.gnome.mutter overlay-key is 'Super_L', wanted ''"
    assert_output_contains "desktop: org.gnome.desktop.wm.keybindings switch-windows is ['<Super>Tab'], wanted ['<Alt>Tab', '<Super>Tab']"
    run desktop_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: desktop: org.gnome.mutter overlay-key is 'Super_L', wanted ''"
    assert_output_contains "VERIFY FAIL: desktop: org.gnome.desktop.wm.keybindings switch-windows is ['<Super>Tab'], wanted ['<Alt>Tab', '<Super>Tab']"
}

# GLib can warn on stderr beside a value it read; the value is what counts.
@test "a key gsettings reads with a warning beside it is not drift" {
    _gs_env "$_GS_PAIRS"
    desktop_install >/dev/null
    mv "$BATS_TEST_TMPDIR/bin/gsettings" "$BATS_TEST_TMPDIR/bin/gsettings.real"
    printf '#!/bin/sh\necho "GLib-WARNING: a warning" >&2\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR/bin/gsettings.real" > "$BATS_TEST_TMPDIR/bin/gsettings"
    chmod +x "$BATS_TEST_TMPDIR/bin/gsettings"
    run desktop_check
    assert_success
    run desktop_install
    assert_success
    assert_output_contains "GLib-WARNING: a warning"
}

@test "desktop_check passes once every declared key holds its value" {
    _gs_env "$_GS_PAIRS"
    desktop_install >/dev/null
    run desktop_check
    assert_success
    run desktop_verify
    assert_success
}

# --- A declared file gsettings is not here to check (issue 0043) ---

@test "a declared desktop file with no gsettings fails check and install and leaves verify incomplete" {
    _gs_env "$_GS_PAIRS"
    printf 'org.gnome.Terminal.desktop\n' > "$(dirname "$GS_FILE")/favorite-apps"
    # No stylesheet, so an unlinked one cannot fail verify before it reaches 2.
    rm "$BATS_TEST_TMPDIR/repo/config/gtk/gtk.css"
    no_gsettings
    run desktop_check
    assert_failure
    assert_output_contains "desktop/gsettings is declared, but gsettings is not on PATH"
    assert_output_contains "desktop/favorite-apps is declared, but gsettings is not on PATH"
    run desktop_install
    assert_failure
    assert_output_contains "desktop/gsettings is declared, but gsettings is not on PATH"
    [ ! -e "$GS_LOG" ]
    run desktop_verify
    [ "$status" -eq 2 ]
    assert_output_contains "VERIFY INCOMPLETE: desktop:"
    assert_output_contains "desktop/favorite-apps is declared, but gsettings is not on PATH"
    refute_output_contains "Verified:"
}

@test "no declared desktop file and no gsettings is a quiet pass" {
    _gs_env ""
    no_gsettings
    run desktop_check
    assert_success
    refute_output_contains "is declared"
    run desktop_install
    assert_success
    refute_output_contains "is declared"
}
