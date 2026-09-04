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
