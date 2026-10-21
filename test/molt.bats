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

# A sleeve's name is its short hostname, whichever form hostname gives, and a
# host that gives none is a failure, not an empty name (critic-shell, 21 Oct).
@test "molt_hostname cuts the name at its first dot, and fails when the host gives no name" {
    load_molt_libs
    mkdir -p "$BATS_TEST_TMPDIR/stub"
    printf '#!/bin/sh\necho kovacs.example.net\n' > "$BATS_TEST_TMPDIR/stub/hostname"
    chmod +x "$BATS_TEST_TMPDIR/stub/hostname"
    PATH="$BATS_TEST_TMPDIR/stub:$PATH" run molt_hostname
    assert_success
    [ "$output" = "kovacs" ]
    printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/stub/hostname"
    HOSTNAME="" PATH="$BATS_TEST_TMPDIR/stub:$PATH" run molt_hostname
    assert_failure
    [ -z "$output" ]
}

# ST0006
@test "molt help lists the agent command, and molt agent alone prints its usage and fails" {
    # AT043 (ST0006 AC006).
    run_molt help
    assert_success
    assert_output_contains "agent list"
    assert_output_contains "agent config <name>"
    run_molt agent
    assert_failure
    assert_output_contains "Usage: molt agent list"
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

# Issue 0008. This was one pipeline ending in `grep -qvE`, which exits at the
# first foreign path. With that path at the top of a large file, the upstream
# grep -oE took SIGPIPE, pipefail (on once lib/molt.sh is sourced) made the whole
# test false, and the file went unreported.
@test "molt_foreign_home_paths flags a foreign path at the top of a large file" {
    load_molt_libs
    local me; me="$(whoami)"
    local d="$BATS_TEST_TMPDIR/cfg3"; mkdir -p "$d"
    awk -v me="$me" 'BEGIN { print "/Users/someoneelse/x"; for (i = 0; i < 200000; i++) print "/Users/" me "/f" i }' > "$d/big.conf"

    run molt_foreign_home_paths "$d"
    assert_success
    assert_output_contains "big.conf"
}

# The trap in converting it: a file that mentions "home" but holds no home path
# captures nothing, and `grep -qv` on an empty herestring matches its blank line.
@test "molt_foreign_home_paths ignores a file that mentions home but holds no home path" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/cfg4"; mkdir -p "$d"
    echo "go home early; Users welcome" > "$d/words.txt"

    run molt_foreign_home_paths "$d"
    assert_success
    [ -z "$output" ]
}

# Issue 0017. /home/linuxbrew is a system account's home holding Homebrew's
# default Linux prefix, /home/linuxbrew/.linuxbrew, and a cross-platform
# zprofile names it. The exemption is that one home: not a name that starts
# with it, and not a file that also names another user's home.
@test "molt_foreign_home_paths exempts Homebrew's Linux prefix and nothing more" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/cfg5"; mkdir -p "$d"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' > "$d/zprofile"
    echo 'P=/home/linuxbrewer/bin' > "$d/near.conf"
    echo 'P=/home/linuxbrew/.linuxbrew/bin:/home/someoneelse/bin' > "$d/both.conf"

    run molt_foreign_home_paths "$d"
    assert_success
    refute_output_contains "zprofile"
    assert_output_contains "near.conf"
    assert_output_contains "both.conf"
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

# The steps after the existence checks ran unchecked, and molt_link is called
# inside `if` and `||`, where set -e does not apply.
@test "molt_link fails, and does not say Linked, when it cannot make the link" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/readonly"
    mkdir -p "$d"
    : > "$BATS_TEST_TMPDIR/source"
    chmod 555 "$d"
    run molt_link "$BATS_TEST_TMPDIR/source" "$d/target"
    chmod 755 "$d"
    assert_failure
    assert_output_contains "Could not link $d/target"
    refute_output_contains "Linked:"
}

# Under bash 4.1 and later, ((failed++)) from 0 returned 1 and set -e ended
# resleeve at the first failure, unreported. bash 3.2, CI's, carried on.
@test "molt resleeve reports every liberator that failed and exits non-zero" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    local name
    for name in aaa bbb; do
        printf '%s_check() { return 1; }\n%s_install() { return 1; }\n' "$name" "$name" > "$libs/$name.sh"
    done
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt resleeve
    assert_failure
    assert_output_contains "Liberator failed: aaa"
    assert_output_contains "Liberator failed: bbb"
    assert_output_contains "2 liberator(s) failed"
    refute_output_contains "Sleeve ready"
}

# kovacs, 16 Oct: doom sync failed inside the editors upgrade hook, and molt
# upgrade warned, resleeved and said "Sleeve ready" (issue 0013).
@test "molt upgrade names a failed upgrade hook, exits non-zero and does not say Sleeve ready" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    printf 'aaa_check() { return 0; }\naaa_upgrade() { return 1; }\n' > "$libs/aaa.sh"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt upgrade aaa --resleeve
    assert_failure
    assert_output_contains "Upgrade failed: aaa"
    assert_output_contains "aaa: ✓ ok"
    assert_output_contains "Upgrade incomplete: the upgrade hook failed for aaa"
    refute_output_contains "Sleeve ready"
}

# The control for the test above: with every hook passing, the verdict is the
# one it must not print over a failure.
@test "molt upgrade says Sleeve ready when its hooks and liberators pass" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    printf 'aaa_check() { return 0; }\naaa_upgrade() { return 0; }\n' > "$libs/aaa.sh"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt upgrade aaa --resleeve
    assert_success
    assert_output_contains "Sleeve ready. Welcome back."
    refute_output_contains "Upgrade incomplete"
}

# The same through a full upgrade, the path hv ran. The repo pull is stubbed:
# it is git against the real checkout, and the hooks are what is under test.
@test "a full molt upgrade carries a failed hook to its verdict and runs the rest" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    printf 'aaa_check() { return 0; }\naaa_upgrade() { return 1; }\n' > "$libs/aaa.sh"
    printf 'bbb_check() { return 0; }\nbbb_upgrade() { echo "bbb upgraded"; }\n' > "$libs/bbb.sh"
    unset MOLT_PRJ_DIR
    export HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" MOLT_LIBERATORS_DIR="$libs"
    load_molt_libs
    _upgrade_pull_repos() { :; }
    run cmd_upgrade
    assert_failure
    assert_output_contains "Upgrade hook failed: aaa"
    assert_output_contains "bbb upgraded"
    assert_output_contains "aaa: ✓ ok"
    assert_output_contains "Upgrade incomplete: the upgrade hook failed for aaa"
    refute_output_contains "Sleeve ready"
}

# bin/molt sources lib/ once, before the pull, and liberator_load reads each
# liberator from disk after it. A pull that brought a liberator calling a new
# library function failed in that liberator until a second run (issue 0023).
@test "a full molt upgrade whose pull changes the framework runs the hooks on the pulled code" {
    local origin="$BATS_TEST_TMPDIR/origin" fw="$BATS_TEST_TMPDIR/fw" cfg="$BATS_TEST_TMPDIR/cfg"
    local g=(git -c user.name=test -c user.email=test@example.com)
    mkdir -p "$origin/liberators" "$cfg/Molt-$(whoami)/config"
    cp -R "$MOLT_ROOT/bin" "$MOLT_ROOT/lib" "$MOLT_ROOT/VERSION" "$origin/"
    printf 'zzz_check() { return 0; }\nzzz_upgrade() { echo "zzz on the old code"; }\n' > "$origin/liberators/zzz.sh"
    "${g[@]}" -C "$origin" init -q
    "${g[@]}" -C "$origin" add -A
    "${g[@]}" -C "$origin" commit -qm old
    git clone -q "$origin" "$fw"
    printf '\nmolt_pulled_only() { echo "zzz on the pulled lib"; }\n' >> "$origin/lib/molt.sh"
    printf 'zzz_check() { return 0; }\nzzz_upgrade() { molt_pulled_only; }\n' > "$origin/liberators/zzz.sh"
    "${g[@]}" -C "$origin" commit -qam new
    "${g[@]}" -C "$cfg/Molt-$(whoami)" init -q
    run env -u MOLT_PRJ_DIR -u MOLT_LIBERATORS_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$cfg" \
        "$fw/bin/molt" upgrade
    assert_success
    assert_output_contains "Framework updated"
    assert_output_contains "zzz on the pulled lib"
    refute_output_contains "Upgrade hook failed"
    assert_output_contains "Running resleeve"
    assert_output_contains "Sleeve ready"
    [ "$(git -C "$fw" rev-parse HEAD)" = "$(git -C "$origin" rev-parse HEAD)" ]
}

# The commit is captured, so a warning printed inside the capture became its
# value and reached nobody.
@test "a full molt upgrade that cannot read the framework commit says so and carries on without restarting" {
    local fw="$BATS_TEST_TMPDIR/fw" cfg="$BATS_TEST_TMPDIR/cfg"
    mkdir -p "$fw/liberators" "$cfg/Molt-$(whoami)/config"
    cp -R "$MOLT_ROOT/bin" "$MOLT_ROOT/lib" "$MOLT_ROOT/VERSION" "$fw/"
    printf 'zzz_check() { return 0; }\nzzz_upgrade() { echo "zzz upgraded"; }\n' > "$fw/liberators/zzz.sh"
    git -C "$cfg/Molt-$(whoami)" init -q
    run env -u MOLT_PRJ_DIR -u MOLT_LIBERATORS_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$cfg" \
        GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" "$fw/bin/molt" upgrade --no-resleeve
    assert_success
    assert_output_contains "Cannot read the framework commit in $fw; a pull that changes lib/ needs a second molt upgrade."
    assert_output_contains "zzz upgraded"
    refute_output_contains "restarting on the new code"
}

@test "molt upgrade refuses --self with --no-pull" {
    run_molt upgrade --self --no-pull
    assert_failure
    assert_output_contains "cannot take --no-pull"
}

# molt upgrade runs resleeve on the left of `||`, where set -e does not apply,
# so a failed lookup inside it has to be caught by hand.
@test "molt resleeve fails, and does not say Sleeve ready, when there are no liberators to run" {
    mkdir -p "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    unset MOLT_PRJ_DIR
    export HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" MOLT_LIBERATORS_DIR="$BATS_TEST_TMPDIR/nope"
    load_molt_libs
    run molt_resleeve false true
    assert_failure
    assert_output_contains "Liberators directory not found"
    assert_output_contains "there are no liberators to run"
    refute_output_contains "Sleeve ready"
}

@test "molt maintain names a failed maintain hook, runs the rest and exits non-zero" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    printf 'aaa_maintain() { return 1; }\n' > "$libs/aaa.sh"
    printf 'bbb_maintain() { echo "bbb maintained"; }\n' > "$libs/bbb.sh"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt maintain
    assert_failure
    assert_output_contains "Maintain hook failed: aaa"
    assert_output_contains "bbb maintained"
    assert_output_contains "Maintenance incomplete: the maintain hook failed for aaa"
    refute_output_contains "System maintenance complete"
}

@test "molt maintain says maintenance is complete when its hooks pass" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    printf 'aaa_maintain() { return 0; }\n' > "$libs/aaa.sh"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt maintain
    assert_success
    assert_output_contains "System maintenance complete."
    refute_output_contains "Maintenance incomplete"
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

# ST0006. An agent's AGENTS.md names the sleeve's overlay as an extra input
# whether or not the sleeve has one. Before the fix the digest failed for an
# absent last extra, so a home with no overlay read stale however often it was
# rendered.
@test "molt_config_digest counts an absent extra input as none, and its arrival as a change" {
    # AT044 (ST0006 AC005).
    load_molt_libs
    _use_digest_test_repo
    local d="$BATS_TEST_TMPDIR/dg3"
    mkdir -p "$d"
    printf 'template body\n' > "$d/config.tmpl"
    local base absent arrived
    base="$(molt_config_digest "$d/config.tmpl")"
    run molt_config_digest "$d/config.tmpl" "$d/overlay.md"
    assert_success
    absent="$output"
    [ "$absent" = "$base" ]
    printf 'host facts\n' > "$d/overlay.md"
    arrived="$(molt_config_digest "$d/config.tmpl" "$d/overlay.md")"
    [ "$arrived" != "$base" ]
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
