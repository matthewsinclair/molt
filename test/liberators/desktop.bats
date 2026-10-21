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
