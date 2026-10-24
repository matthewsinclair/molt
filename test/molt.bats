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

@test "molt version names the version, the dev tree and its root" {
    run_molt version
    assert_success
    assert_output_contains "molt $(cat "$MOLT_ROOT/VERSION") (dev, "
    run_molt --version
    assert_success
    assert_output_contains "molt $(cat "$MOLT_ROOT/VERSION") (dev, "
}

# --- List ---

@test "molt list lists liberators" {
    run_molt list
    assert_success
    assert_output_contains "zsh"
    assert_output_contains "git"
}

# --- Doctor ---

# doctor stores no total: it counts its checks as they run, and closes with how
# many did not pass out of how many ran. What this expects is read off the
# run's own Checking lines, never written down here (hv, 23 Oct).
assert_doctor_closed() {
    local line mark ran=0 failed=0 want
    for line in "${lines[@]}"; do
        [[ "$line" == "Checking "* ]] || continue
        ran=$((ran + 1))
        mark="${line#*... }"
        [[ "$mark" == "✓"* ]] || failed=$((failed + 1))
    done
    [ "$ran" -gt 0 ] || fail "doctor printed no Checking line:\n$output"
    if [ "$failed" -eq 0 ]; then
        want="All checks passed."
    else
        want="$failed of $ran checks did not pass. Review above for details."
    fi
    [ "${lines[${#lines[@]}-1]}" = "$want" ] || fail "Expected doctor to close with: '$want'\nActual output:\n$output"
    # The exit follows the run: 0 only when every check passed (issue 0055).
    if [ "$failed" -eq 0 ]; then
        [ "$status" -eq 0 ] || fail "doctor passed every check but exited $status"
    else
        [ "$status" -eq 1 ] || fail "doctor failed $failed check(s) but exited $status"
    fi
}

@test "molt doctor runs without crashing, and exits as its checks went" {
    run_molt doctor
    assert_output_contains "Checking"
    assert_doctor_closed
}

@test "doctor's verdict passes only when no check failed, and names how many of how many did" {
    load_molt_libs
    run molt_doctor_verdict 0 3
    assert_success
    [ "$output" = "All checks passed." ]
    run molt_doctor_verdict 2 3
    [ "$status" -eq 1 ]
    [ "$output" = "2 of 3 checks did not pass. Review above for details." ]
}

@test "molt doctor prints a failing liberator's check lines as the check printed them (issue 0026)" {
    require_command git
    local repo="$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    create_test_repo "$repo"
    cat > "$repo/molt.toml" <<'TOML'
[[liberator]]
name = "git"
enabled = true
TOML
    mkdir -p "$BATS_TEST_TMPDIR/home"
    # git's check fails: nothing in this HOME is linked to the repo's gitconfig.
    HOME="$BATS_TEST_TMPDIR/home" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" run_molt doctor
    assert_output_matches 'Checking enabled liberators\.\.\. ⚠ [0-9]+ of [0-9]+ not installed: git'
    assert_failure
    assert_output_matches $'(^|\n)         Zen: git: '
    refute_output_contains "git: Zen:"
}

@test "molt doctor runs every step for a manifest that declares no user_repo (issue 0028)" {
    local repo="$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    create_test_repo "$repo"
    printf '[[liberator]]\nname = "git"\nenabled = false\n' > "$repo/molt.toml"
    MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" run_molt doctor
    assert_output_contains "Checking manifest... ✓ $repo/molt.toml"
    assert_doctor_closed
}

@test "molt doctor reports a manifest it cannot read, and carries on (issue 0028)" {
    [[ "$(id -u)" != 0 ]] || skip "root reads a mode-000 file"
    local repo="$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    create_test_repo "$repo"
    printf '[[liberator]]\nname = "git"\nenabled = false\n' > "$repo/molt.toml"
    chmod 000 "$repo/molt.toml"
    MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" run_molt doctor
    chmod 600 "$repo/molt.toml"
    assert_output_contains "Checking manifest... ⚠ $repo/molt.toml"
    assert_output_contains "could not be read"
    assert_doctor_closed
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
    assert_output_contains "agent config <role>"
    # ST0007 AC001, AC003.
    assert_output_contains "agent start <role> [-- <claude args>]"
    assert_output_contains "agent roles"
    assert_output_contains "agent home <role>"
    run_molt agent
    assert_failure
    assert_output_contains "Usage: molt agent list"
}

# --- Foreign home-path detection (doctor's foreign home paths check) ---

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

# It ran python3 wherever realpath(1) was missing (issue 0039). The expected
# path is /bin/pwd -P's, not the resolver's own.
@test "_molt_realpath follows absolute and relative links, through a linked directory, to the file as the disk names it" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/resolve" want
    mkdir -p "$d/dir"
    : > "$d/dir/file"
    ln -s "$d/dir" "$d/dirlink"
    ln -s ../dirlink/file "$d/dir/rel"
    ln -s "$d/dir/rel" "$d/abs"
    want="$(cd "$d/dir" && /bin/pwd -P)/file"

    run _molt_realpath "$d/abs"
    assert_success
    [ "$output" = "$want" ]
    run _molt_realpath "$d/dirlink/file"
    [ "$output" = "$want" ]
    cd "$d"
    run _molt_realpath abs
    [ "$output" = "$want" ]
}

# critic-shell, 23 Oct: cd takes up/.. off as text before it follows up, so a ..
# after a linked directory, in the path or in a link's target, named a file
# beside the link, not the one the disk reaches.
@test "_molt_realpath takes a .. after a linked directory where the link leads, in the path and in a link's target" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/dotdot" want
    mkdir -p "$d/deep/inner"
    : > "$d/deep/x"
    ln -s "$d/deep/inner" "$d/up"
    ln -s up/../x "$d/via"
    want="$(cd "$d/deep" && /bin/pwd -P)/x"

    run _molt_realpath "$d/up/../x"
    assert_success
    [ "$output" = "$want" ]
    run _molt_realpath "$d/via"
    [ "$output" = "$want" ]
    run molt_same_file "$d/via" "$d/deep/x"
    assert_success
}

@test "_molt_realpath gives back as it was a path in a link loop" {
    load_molt_libs
    local d="$BATS_TEST_TMPDIR/loop"
    mkdir -p "$d"
    ln -s "$d/b" "$d/a"
    ln -s "$d/a" "$d/b"
    run _molt_realpath "$d/a"
    assert_success
    [ "$output" = "$d/a" ]
}

# hv, 23 Oct 2026: ship no Python in any repo. Molt is shell.
@test "Molt ships no Python: no .py file, and no python call in what it runs" {
    local hits
    cd "$MOLT_ROOT"
    run git ls-files -- '*.py'
    assert_success
    [ -z "$output" ]
    # A comment may name it; a line of code may not, nor a shebang, which a
    # heredoc may write. A path or a default, /usr/bin/python3 or
    # ${PYTHON:-python3}, is a call. git grep exits 1 when nothing matches, and
    # any other failure must not read as nothing found (critic-shell, 23 Oct).
    run git grep -nIE '(^|[^[:alnum:]_.])python[0-9.]*([^[:alnum:]_-]|$)' -- bin lib liberators templates .github
    [ "$status" -le 1 ]
    # grep -v exits 1 when every hit is a comment.
    hits="$(printf '%s\n' "$output" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#([^!]|$)' || true)"
    echo "$hits"
    [ -z "$hits" ]
}

# critic-shell, 23 Oct: bin/molt read a relative link's target from the
# directory it was run in, not from the link's.
@test "molt runs through a relative link to bin/molt, from any directory" {
    local d="$BATS_TEST_TMPDIR/rel"
    mkdir -p "$d/bin"
    ln -s "$MOLT_ROOT" "$d/molt-root"
    ln -s ../molt-root/bin/molt "$d/bin/molt"
    cd /
    run "$d/bin/molt" help
    assert_success
    assert_output_contains "agent start <role>"
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
# The failure line says how many of how many ran, and names them.
@test "molt resleeve reports every liberator that failed and exits non-zero" {
    local libs="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$libs" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)/config"
    local name
    for name in aaa bbb; do
        printf '%s_check() { return 1; }\n%s_install() { return 1; }\n' "$name" "$name" > "$libs/$name.sh"
    done
    printf 'ccc_check() { return 0; }\n' > "$libs/ccc.sh"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt resleeve
    assert_failure
    assert_output_contains "Liberator failed: aaa"
    assert_output_contains "Liberator failed: bbb"
    assert_output_contains "2 of 3 liberators failed: aaa, bbb."
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

# --- A pull that fails (issue 0015) ---

# A framework clone and a user config clone in the test directory, each
# pulling from an origin beside it, and one liberator whose upgrade hook says
# it ran. A pull is made to fail by removing its origin: git's own failure,
# with no network involved.
_pull_sleeve() {
    ORIGIN="$BATS_TEST_TMPDIR/origin" FW="$BATS_TEST_TMPDIR/fw" CFG="$BATS_TEST_TMPDIR/cfg"
    CFG_ORIGIN="$BATS_TEST_TMPDIR/cfg-origin"
    USER_REPO="$CFG/Molt-$(whoami)"
    G=(git -c user.name=test -c user.email=test@example.com)
    mkdir -p "$ORIGIN/liberators" "$CFG_ORIGIN/config" "$CFG"
    cp -R "$MOLT_ROOT/bin" "$MOLT_ROOT/lib" "$MOLT_ROOT/VERSION" "$ORIGIN/"
    printf 'zzz_check() { return 0; }\nzzz_upgrade() { echo "zzz upgraded"; }\n' > "$ORIGIN/liberators/zzz.sh"
    : > "$CFG_ORIGIN/config/.keep"
    local r
    for r in "$ORIGIN" "$CFG_ORIGIN"; do
        "${G[@]}" -C "$r" init -q
        "${G[@]}" -C "$r" add -A
        "${G[@]}" -C "$r" commit -qm init
    done
    git clone -q "$ORIGIN" "$FW"
    git clone -q "$CFG_ORIGIN" "$USER_REPO"
}

# molt upgrade, run from the framework clone, with $@.
_pull_upgrade() {
    run env -u MOLT_PRJ_DIR -u MOLT_LIBERATORS_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$CFG" \
        "$FW/bin/molt" upgrade "$@"
}

@test "a repo with no upstream is the one pull molt upgrade skips: it warns, and the run goes on to Sleeve ready" {
    _pull_sleeve
    git -C "$USER_REPO" branch -q --unset-upstream
    _pull_upgrade
    assert_success
    assert_output_contains "User config pull skipped: $USER_REPO has no upstream branch"
    assert_output_contains "zzz upgraded"
    assert_output_contains "Sleeve ready"
}

@test "a pull that fails is an error naming the repo and git's reason; the liberators still run, and the upgrade ends non-zero without Sleeve ready" {
    _pull_sleeve
    rm -rf "$ORIGIN"
    _pull_upgrade
    assert_failure
    assert_output_contains "Framework pull failed in $FW:"
    assert_output_contains "$ORIGIN"
    refute_output_contains "pull skipped"
    assert_output_contains "Pulling user config repo"
    assert_output_contains "zzz upgraded"
    assert_output_contains "Running resleeve"
    assert_output_contains "Upgrade incomplete: the pull failed for the framework repo ($FW)"
    refute_output_contains "Sleeve ready"

    _pull_upgrade --self
    [ "$status" -eq 1 ]
    assert_output_contains "Framework pull failed in $FW:"
}

# git rev-parse @{upstream} fails for an upstream that is configured and gone,
# as for none, but only none is a skip.
@test "a pull from a configured upstream that is gone fails the upgrade; it is not a repo with no upstream" {
    _pull_sleeve
    git -C "$USER_REPO" config "branch.$(git -C "$USER_REPO" branch --show-current).merge" refs/heads/gone
    _pull_upgrade
    assert_failure
    assert_output_contains "User config pull failed in $USER_REPO:"
    assert_output_contains "gone"
    refute_output_contains "User config pull skipped"
    refute_output_contains "Sleeve ready"
}

# A pull that moved the framework restarts the upgrade in a new process
# (issue 0023); a pull that failed before it must still fail the run.
@test "a failed pull is carried through the restart a framework pull makes" {
    _pull_sleeve
    echo "# pulled" >> "$ORIGIN/VERSION.note"
    "${G[@]}" -C "$ORIGIN" add -A
    "${G[@]}" -C "$ORIGIN" commit -qm new
    rm -rf "$CFG_ORIGIN"
    _pull_upgrade
    assert_failure
    assert_output_contains "restarting on the new code"
    assert_output_contains "User config pull failed in $USER_REPO:"
    assert_output_contains "zzz upgraded"
    assert_output_contains "Upgrade incomplete: the pull failed for the user config repo ($USER_REPO)"
    refute_output_contains "Sleeve ready"
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

# --- Where errors go (issue 0016) ---

@test "molt_error writes to stderr, and warnings and the rest to stdout, so a captured call never takes an error for its value" {
    load_molt_libs
    [ "$(molt_error boom 2>/dev/null)" = "" ]
    [ "$(molt_error boom 2>&1 >/dev/null)" = "Zen [error]: boom" ]
    [ "$(molt_warn careful 2>/dev/null)" = "Zen [warning]: careful" ]
    [ "$(molt_info hello 2>/dev/null)" = "Zen: hello" ]
}

# A sleeve with no user config repo, in this shell.
_no_user_repo() {
    unset MOLT_PRJ_DIR
    export HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg"
    load_molt_libs
}

@test "a caller that captures molt_find_user_repo and fails on it no longer swallows what it searched" {
    _no_user_repo
    run molt_resleeve false true
    assert_failure
    assert_output_contains "Could not find user config repo (Molt-$(whoami))."
    assert_output_contains "Searched:"
    assert_output_contains "  $BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    assert_output_contains "Cannot resleeve without a user config repo."
}

@test "molt_find_user_repo leaves a caller's path as it was" {
    _no_user_repo
    local path=keep
    molt_find_user_repo >/dev/null 2>&1 || true
    [ "$path" = keep ]
}

@test "a caller that discards the lookup's stderr reads no repo, not the error's text" {
    _no_user_repo
    load_liberator git
    run git_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: user config repo not found, so no git config link was checked"
}

@test "a lookup whose caller gives its own reason, where no repo can be a sleeve's normal state, says only that reason" {
    _no_user_repo
    run molt_instance_file vars.sh
    assert_failure
    [ "$output" = "this sleeve's vars.sh cannot be found: there is no user config repo, or this host has no name" ]
    run molt_agent_role_dir sysadm
    assert_failure
    [ "$output" = "" ]
    run molt_config_stale config/zsh/zshrc "$HOME/.zshrc"
    assert_success
    [ "$output" = "Zen [warning]: molt_config_stale: no user repo — cannot tell whether $HOME/.zshrc is stale" ]
}

@test "molt upgrade and molt maintain name a liberator the manifest enables and the framework does not have" {
    local libs="$BATS_TEST_TMPDIR/liberators" repo="$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    mkdir -p "$libs" "$repo/config"
    printf 'bbb_maintain() { echo "bbb maintained"; }\nbbb_upgrade() { echo "bbb upgraded"; }\n' > "$libs/bbb.sh"
    printf '[[liberator]]\nname = "ghost"\nenabled = true\n\n[[liberator]]\nname = "bbb"\nenabled = true\n' > "$repo/molt.toml"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt maintain
    assert_output_contains "Liberator not found: ghost"
    assert_output_contains "bbb maintained"
    run env -u MOLT_PRJ_DIR HOME="$BATS_TEST_TMPDIR" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" \
        MOLT_LIBERATORS_DIR="$libs" molt upgrade --no-pull
    assert_output_contains "Liberator not found: ghost"
    assert_output_contains "bbb upgraded"
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

# --- The managed floor (ST0006 WP06) ---

# A sleeve in the test directory, in this shell: a user repo with a sysadm
# role and its floor, a managed dir of the test's own, and a fake sudo that
# runs what it is given unless FAKE_SUDO_STATUS says otherwise.
_floor_sleeve() {
    load_molt_libs
    source "$MOLT_ROOT/liberators/agents.sh"
    export HOME="$BATS_TEST_TMPDIR/home" MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    REPO="$BATS_TEST_TMPDIR/repo"
    INSTANCE="$REPO/instances/$(test_hostname)"
    mkdir -p "$HOME" "$REPO/config/agents/roles/sysadm" "$INSTANCE"
    eval "molt_find_user_repo() { echo \"$REPO\"; }"
    eval "molt_claude_managed_dir() { echo \"$BATS_TEST_TMPDIR/managed\"; }"
    FLOOR="$BATS_TEST_TMPDIR/managed/managed-settings.d/molt-sysadm.json"
    printf '{"permissions": {"deny": ["Read(~/.ssh/id_*)", "Read(~/.aws/credentials)"]}}\n' \
        > "$REPO/config/agents/roles/sysadm/floor.json"
    printf '[stack]\nname = "test"\n\n[[agent]]\nrole = "sysadm"\n' > "$INSTANCE/molt.toml"
    printf 'export MOLT_CLAUDE_CONFIG_DIR="%s"\n' "$HOME/.config/claude" > "$INSTANCE/vars.sh"
    install_fake_apparmor
}

@test "doctor's managed floor check warns on a sysadm sleeve whose floor is missing or stale, and on one with no sysadm agent or no declared config dir carrying molt's, and passes otherwise" {
    # AT072 (ST0006 AC019).
    _floor_sleeve
    run cmd_doctor
    assert_output_contains "Checking managed floor... ⚠"
    assert_output_contains "         $FLOOR is missing"
    _agents_floor >/dev/null
    run cmd_doctor
    assert_output_contains "Checking managed floor... ✓ in place: $FLOOR"
    echo '{"permissions": {"deny": []}}' > "$FLOOR"
    run cmd_doctor
    assert_output_contains "         $FLOOR is not $REPO/config/agents/roles/sysadm/floor.json"

    : > "$INSTANCE/vars.sh"
    run cmd_doctor
    assert_output_contains "Checking managed floor... ⚠"
    assert_output_contains "         $FLOOR is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR"
    echo 'if then' > "$INSTANCE/vars.sh"
    run cmd_doctor
    assert_output_contains "Checking managed floor... ⚠"
    assert_output_contains "         MOLT_CLAUDE_CONFIG_DIR could not be read: $INSTANCE/vars.sh does not parse"
    printf 'export MOLT_CLAUDE_CONFIG_DIR="%s"\n' "$HOME/.config/claude" > "$INSTANCE/vars.sh"

    printf '[stack]\nname = "test"\n' > "$INSTANCE/molt.toml"
    run cmd_doctor
    assert_output_contains "Checking managed floor... ⚠"
    assert_output_contains "         $FLOOR is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR"
    rm -f "$FLOOR.molt-rendered"
    run cmd_doctor
    assert_output_contains "Checking managed floor... ✓ none needed; $FLOOR is not molt's, and is left"
    rm -f "$FLOOR"
    run cmd_doctor
    assert_output_contains "Checking managed floor... ✓ none needed, and none of molt's here"
}

@test "doctor's sandbox profile check warns on a Linux ops sleeve whose sandbox profile is not molt's, or not taking, and on one that takes none carrying molt's, and passes otherwise" {
    _floor_sleeve
    mkdir -p "$REPO/config/agents/roles/ops"
    printf '[stack]\nname = "test"\n\n[[agent]]\nrole = "ops"\n' > "$INSTANCE/molt.toml"
    eval 'molt_platform() { echo linux; }'
    local profile="$BATS_TEST_TMPDIR/apparmor.d/bwrap-userns-restrict"
    echo "the distro's profile" > "$profile"
    run cmd_doctor
    assert_output_contains "Checking sandbox profile... ⚠"
    assert_output_contains "         $profile is not molt's, so bwrap's children are denied the sys_admin Claude Code's sandbox needs"
    _agents_sandbox >/dev/null
    run cmd_doctor
    assert_output_contains "Checking sandbox profile... ✓ in place: $profile"
    FAKE_BWRAP_STATUS=1 run cmd_doctor
    assert_output_contains "Checking sandbox profile... ⚠"
    assert_output_contains "         $profile is molt's, but bwrap's children still cannot make the sandbox's user namespace"

    printf '[stack]\nname = "test"\n' > "$INSTANCE/molt.toml"
    run cmd_doctor
    assert_output_contains "Checking sandbox profile... ⚠"
    assert_output_contains "         $profile is molt's, and this sleeve takes no sandbox profile: it enables no ops or docs agent, or is not Linux"
    _agents_sandbox >/dev/null
    run cmd_doctor
    assert_output_contains "Checking sandbox profile... ✓ none needed; $profile is not molt's, and is left"
    rm -f "$profile"
    run cmd_doctor
    assert_output_contains "Checking sandbox profile... ✓ none needed, and none of molt's here"
}

@test "doctor closes with how many checks did not pass out of how many ran, a check that could not run among them" {
    _floor_sleeve
    printf 'export MOLT_FONT_FAMILY="Test Font"\n' >> "$INSTANCE/vars.sh"
    eval 'molt_font_available() { return 2; }'
    run cmd_doctor
    assert_output_contains "Checking declared font... ? cannot verify Test Font"
    refute_output_contains "All checks passed."
    assert_doctor_closed
}

@test "doctor's liberator checks pass with no count, and on a failure say how many of how many, and name them" {
    _floor_sleeve
    MOLT_LIBERATORS_DIR="$BATS_TEST_TMPDIR/liberators"
    mkdir -p "$MOLT_LIBERATORS_DIR"
    # The counts expected are the fixture's own, never written down.
    local lib libs=(alpha beta gamma) unchecked=(gamma) failing=(beta gamma)
    for lib in "${libs[@]}"; do
        printf '%s_check() { :; }\n' "$lib" > "$MOLT_LIBERATORS_DIR/$lib.sh"
        printf '\n[[liberator]]\nname = "%s"\n' "$lib" >> "$INSTANCE/molt.toml"
    done
    run cmd_doctor
    assert_output_contains "Checking liberators... ✓ all have _check"
    assert_output_contains "Checking enabled liberators... ✓ all installed"

    printf 'beta_check() { echo "beta: not here"; return 1; }\n' > "$MOLT_LIBERATORS_DIR/beta.sh"
    printf 'gamma_install() { :; }\n' > "$MOLT_LIBERATORS_DIR/gamma.sh"
    run cmd_doctor
    assert_output_contains "Checking liberators... ⚠ ${#unchecked[@]} of ${#libs[@]} have no _check: gamma"
    assert_output_contains "Checking enabled liberators... ⚠ ${#failing[@]} of ${#libs[@]} not installed: beta, gamma"
    assert_output_contains "         beta: not here"
    assert_doctor_closed
}

# What the test's own disk does with case, found by making a file and asking
# for it in another case, not by the question doctor asks.
_disk_folds_case() {
    touch "$BATS_TEST_TMPDIR/casefold"
    [ -e "$BATS_TEST_TMPDIR/CASEFOLD" ]
}

@test "doctor's git case sensitivity check passes where core.ignorecase matches the disk, and warns, naming the fix, where it does not" {
    _floor_sleeve
    git init -q "$REPO"
    local folds=false other=true
    if _disk_folds_case; then
        folds=true other=false
    fi
    git -C "$REPO" config core.ignorecase "$folds"
    run cmd_doctor
    assert_output_contains "Checking git case sensitivity... ✓ core.ignorecase matches the disk"
    git -C "$REPO" config core.ignorecase "$other"
    run cmd_doctor
    assert_output_contains "Checking git case sensitivity... ⚠ core.ignorecase does not match the disk in ${REPO##*/}"
    assert_output_contains "           git -C $REPO config core.ignorecase $folds"
    assert_doctor_closed
}

@test "doctor's git case sensitivity check passes on a disk that folds case with core.ignorecase=true, and says how to rename" {
    _floor_sleeve
    _disk_folds_case || skip "this disk keeps case"
    git init -q "$REPO"
    git -C "$REPO" config core.ignorecase true
    run cmd_doctor
    assert_output_contains "Checking git case sensitivity... ✓ core.ignorecase matches the disk"
    assert_output_contains "Rename with 'git mv -f Old New'"
}

@test "the sudo helpers install a user copy, not the file named, refuse with sudo absent or refusing, and write nothing unprivileged" {
    # AT073 (ST0006 AC019).
    _floor_sleeve
    local src="$REPO/config/agents/roles/sysadm/floor.json"
    mkdir -p "$(dirname "$FLOOR")"

    FAKE_SUDO_STATUS=1 run molt_sudo_install "$src" "$FLOOR"
    assert_failure
    assert_output_contains "sudo could not install $FLOOR"
    [ ! -e "$FLOOR" ]

    PATH="$BATS_TEST_TMPDIR/nosudo" run molt_sudo_install "$src" "$FLOOR"
    assert_failure
    assert_output_contains "sudo is not installed, so $FLOOR was not written"
    [ ! -e "$FLOOR" ]

    rm -f "$BATS_TEST_TMPDIR/sudo.log"
    run molt_sudo_install "$src" "$FLOOR"
    assert_success
    cmp "$src" "$FLOOR"
    [ "$(test_file_mode "$FLOOR")" = 644 ]
    grep -q "^sudo install -m 644 " "$BATS_TEST_TMPDIR/sudo.log"
    run grep -qF "install -m 644 $src " "$BATS_TEST_TMPDIR/sudo.log"
    assert_failure
    # The directory, there already, keeps its mode; a missing one is made.
    run grep -q "install -d" "$BATS_TEST_TMPDIR/sudo.log"
    assert_failure
    rm -rf "$(dirname "$FLOOR")"
    run molt_sudo_install "$src" "$FLOOR"
    assert_success
    grep -qF "sudo install -d -m 755 $(dirname "$FLOOR")" "$BATS_TEST_TMPDIR/sudo.log"
    cmp "$src" "$FLOOR"

    FAKE_SUDO_STATUS=1 run molt_sudo_remove "$FLOOR"
    assert_failure
    [ -e "$FLOOR" ]
    PATH="$BATS_TEST_TMPDIR/nosudo" run molt_sudo_remove "$FLOOR"
    assert_failure
    assert_output_contains "sudo is not installed"
    [ -e "$FLOOR" ]
    run molt_sudo_remove "$FLOOR"
    assert_success
    [ ! -e "$FLOOR" ]
}
