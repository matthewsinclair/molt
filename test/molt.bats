#!/usr/bin/env bats
# molt.bats — CLI and framework tests

load "test_helper.bash"

# --- Help ---

@test "molt help shows usage" {
    run_molt help
    assert_success
    assert_output_contains "Usage: molt <command>"
}

@test "molt with no args shows help" {
    run_molt
    assert_success
    assert_output_contains "Usage: molt <command>"
}

# --- Status ---

@test "molt status shows sleeve info" {
    run_molt status
    assert_success
    assert_output_contains "Platform:"
    assert_output_contains "Distro:"
    assert_output_contains "Arch:"
    assert_output_contains "Stack:"
}

# --- Version ---

@test "molt version shows version string" {
    run_molt version
    assert_success
    assert_output_contains "MOLT v"
}

# --- List ---

@test "molt list lists liberators" {
    run_molt list
    assert_success
    assert_output_contains "zsh"
    assert_output_contains "git"
}

# --- Doctor ---

@test "molt doctor runs without crashing" {
    run_molt doctor
    assert_success
    assert_output_contains "Checking"
}

# --- Unknown command ---

@test "unknown command returns error" {
    run_molt bogus_command
    assert_failure
    assert_output_contains "Unknown command"
}

# --- Help lists all commands ---

@test "molt help lists doctor command" {
    run_molt help
    assert_success
    assert_output_contains "doctor"
}

@test "molt help lists test command" {
    run_molt help
    assert_success
    assert_output_contains "test"
}

@test "molt help lists list command" {
    run_molt help
    assert_success
    assert_output_contains "list"
}

@test "molt help lists version command" {
    run_molt help
    assert_success
    assert_output_contains "version"
}

# --- Foreign home-path detection (doctor check 10) ---

@test "molt_foreign_home_paths flags another user's home path (incl JSON-escaped)" {
    load_molt_libs
    local me; me="$(whoami)"
    local d="$BATS_TEST_TMPDIR/cfg"; mkdir -p "$d/iterm2" "$d/zsh"
    # JSON-escaped foreign path — the iTerm2/VS Code export case
    printf '{"Working Directory":"\\/Users\\/someoneelse"}\n' > "$d/iterm2/profile.json"
    # current user's own path must NOT be flagged
    echo "export P=/Users/$me/bin" > "$d/zsh/zshenv"

    run molt_foreign_home_paths "$d"
    assert_success
    assert_output_contains "iterm2/profile.json"
    refute_output_contains "zsh/zshenv"
}

@test "molt_foreign_home_paths clean when only current user's paths" {
    load_molt_libs
    local me; me="$(whoami)"
    local d="$BATS_TEST_TMPDIR/cfg2"; mkdir -p "$d"
    echo "a = /Users/$me/x" > "$d/a.conf"
    echo "b = /home/$me/y" > "$d/b.conf"

    run molt_foreign_home_paths "$d"
    assert_success
    [ -z "$output" ]
}

# --- Symlink state helpers ---

@test "molt_link_fault distinguishes all four states" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/faults"
    mkdir -p "$d"
    : > "$d/real"
    ln -s "$d/real" "$d/good"
    ln -s "$d/NOPE" "$d/dangling"
    : > "$d/regular"

    run molt_link_fault "$d/good"
    assert_output_contains "resolves"
    run molt_link_fault "$d/dangling"
    assert_output_contains "is a broken symlink"
    run molt_link_fault "$d/regular"
    assert_output_contains "is not a symlink"
    run molt_link_fault "$d/absent"
    assert_output_contains "is missing"
}

@test "molt_link_fault does not report a fault for a healthy link" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/healthy"
    mkdir -p "$d"
    : > "$d/real"
    ln -s "$d/real" "$d/good"
    run molt_link_fault "$d/good"
    # Assert positively. A bare refute passes when the function is not loaded
    # at all and the output is "command not found" -- a false green of exactly
    # the kind these helpers exist to prevent.
    assert_success
    [ "$output" = "resolves" ]
}

@test "molt_link_points_to rejects a healthy link to the wrong target" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/points"
    mkdir -p "$d"
    : > "$d/wanted"
    : > "$d/other"
    ln -s "$d/other" "$d/link"

    run molt_link_healthy "$d/link"
    [ "$status" -eq 0 ]

    run molt_link_points_to "$d/link" "$d/wanted"
    [ "$status" -ne 0 ]

    ln -sfn "$d/wanted" "$d/link"
    run molt_link_points_to "$d/link" "$d/wanted"
    [ "$status" -eq 0 ]
}

# --- Digest covers every input the render depends on ---

# molt_config_digest RESOLVES vars.sh THROUGH molt_find_user_repo and returns 1
# when it cannot find one -- correctly, because a digest taken without vars.sh
# would silently omit an input the rendered result depends on, which is the very
# hole the digest exists to close.
#
# The two arms below assert on that digest, and originally supplied no user repo.
# So they read the DEVELOPER'S machine -- ~/Devel/prj/Molt-$(whoami)/config, which
# happens to exist there -- and passed, while failing on every CI runner from the
# moment they landed. Green where it was written, red where it mattered, for three
# days and twelve runs before anyone looked.
#
# Same idiom as test/instances.bats:41: point the search paths at a repo the test
# builds itself.
_use_digest_test_repo() {
    mkdir -p "$BATS_TEST_TMPDIR/molt-testuser/config"
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/molt-testuser")
}

@test "molt_config_digest changes when an extra input changes" {
    load_molt_libs
    _use_digest_test_repo
    local d="$BATS_TEST_TMPDIR/dg"
    mkdir -p "$d"
    printf 'template body\n' > "$d/config.tmpl"
    printf 'fragment one\n'  > "$d/a.conf"

    local base with_frag
    base="$(molt_config_digest "$d/config.tmpl" 2>/dev/null || true)"
    with_frag="$(molt_config_digest "$d/config.tmpl" "$d/a.conf" 2>/dev/null || true)"
    [ -n "$base" ]
    [ -n "$with_frag" ]
    # Adding a fragment must change the digest -- this is the bug: a new
    # fragment altered the rendered result while nothing marked it stale.
    [ "$base" != "$with_frag" ]

    # Editing that fragment must change it again.
    printf 'fragment one EDITED\n' > "$d/a.conf"
    local edited
    edited="$(molt_config_digest "$d/config.tmpl" "$d/a.conf" 2>/dev/null || true)"
    [ "$edited" != "$with_frag" ]
}

@test "molt_config_digest is stable regardless of extra-input order" {
    load_molt_libs
    _use_digest_test_repo
    local d="$BATS_TEST_TMPDIR/dg2"
    mkdir -p "$d"
    printf 'template body\n' > "$d/config.tmpl"
    printf 'one\n' > "$d/a.conf"
    printf 'two\n' > "$d/b.conf"

    local ab ba
    ab="$(molt_config_digest "$d/config.tmpl" "$d/a.conf" "$d/b.conf" 2>/dev/null || true)"
    ba="$(molt_config_digest "$d/config.tmpl" "$d/b.conf" "$d/a.conf" 2>/dev/null || true)"
    [ -n "$ab" ]
    [ "$ab" = "$ba" ]
}

# ---------------------------------------------------------------------------
# molt_font_available -- the config names a font; does the machine have it?
# ---------------------------------------------------------------------------

@test "molt_font_available resolves a family fontconfig actually lists" {
    load_molt_libs
    command -v fc-list &>/dev/null || skip "fontconfig not installed"
    local fam
    # Take a family the machine really has, so the test asserts resolution
    # rather than the presence of one particular font.
    fam="$(fc-list : family 2>/dev/null | tr ',' '\n' \
           | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
           | grep -v '^$' | head -1)"
    [ -n "$fam" ]
    run molt_font_available "$fam"
    [ "$status" -eq 0 ]
}

@test "molt_font_available returns 1 for a font that is not installed" {
    load_molt_libs
    command -v fc-list &>/dev/null || skip "fontconfig not installed"
    # THE REGRESSION GUARD. fc-match answers this exact query with Verdana --
    # it always succeeds -- so a check built on fc-match would return 0 here and
    # report every font on earth as present. If this test ever goes green on a
    # status of 0, the honest test has been swapped for the lying one.
    run molt_font_available "ThisFontDoesNotExist12345"
    [ "$status" -eq 1 ]
}

@test "molt_font_available does not partial-match a longer family name" {
    load_molt_libs
    command -v fc-list &>/dev/null || skip "fontconfig not installed"
    local fam
    fam="$(fc-list : family 2>/dev/null | tr ',' '\n' \
           | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
           | grep -v '^$' | head -1)"
    [ -n "$fam" ]
    # A substring of a real family is still not that family.
    run molt_font_available "${fam} Definitely Not A Real Suffix"
    [ "$status" -eq 1 ]
}

@test "molt_font_available returns 2 -- not 0 or 1 -- for an empty family" {
    load_molt_libs
    run molt_font_available ""
    [ "$status" -eq 2 ]
}

@test "molt_font_available returns 2 when fontconfig is absent" {
    load_molt_libs
    # "Cannot determine" must stay distinct from "not installed". Folding it
    # into 1 would report a missing font on every machine without fontconfig;
    # folding it into 0 would report ok having measured nothing.
    local empty="$BATS_TEST_TMPDIR/nopath"
    mkdir -p "$empty"
    PATH="$empty" run molt_font_available "Hack Nerd Font Mono"
    [ "$status" -eq 2 ]
}
