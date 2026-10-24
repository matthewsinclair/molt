#!/usr/bin/env bats
# run-liberators.bats — which liberators a run covers (issue 0054)

load "test_helper.bash"

# A user repo whose molt.toml is $1, or none when $1 is empty, on a sleeve
# whose platform is linux.
_run_env() {
    load_molt_libs
    export HOME="$BATS_TEST_TMPDIR/home"
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$HOME" "$REPO/config"
    MOLT_USER_REPO_SEARCH_PATHS=("$REPO")
    molt_platform() { echo linux; }
    [ -z "${1:-}" ] || printf '%s' "$1" > "$REPO/molt.toml"
}

MACOS_ONLY='[[liberator]]
name = "brew"
enabled = true
os = ["macos"]
'

@test "a manifest that enables no liberator for this platform is refused, naming it" {
    _run_env "$MACOS_ONLY"
    run molt_run_liberators
    assert_failure
    [ "$output" = "$REPO/molt.toml enables no liberator for linux; enable one, or remove the manifest to run them all" ]
}

@test "resleeve, upgrade, maintain and molt git refuse a manifest that enables nothing here, and run no liberator" {
    _run_env "$MACOS_ONLY"
    run molt_resleeve
    assert_failure
    assert_output_contains "Cannot resleeve: $REPO/molt.toml enables no liberator for linux"
    refute_output_contains "Sleeve ready"
    run cmd_maintain
    assert_failure
    assert_output_contains "Cannot maintain: $REPO/molt.toml enables no liberator for linux"
    run cmd_upgrade --no-pull --no-resleeve
    assert_failure
    assert_output_contains "Cannot upgrade: $REPO/molt.toml enables no liberator for linux"
    run cmd_git status
    assert_failure
    assert_output_contains "Cannot run git: $REPO/molt.toml enables no liberator for linux"
    refute_output_contains "--- molt"
}

@test "with no manifest, a run covers every liberator Molt ships" {
    _run_env ""
    local want="" f
    for f in "$MOLT_ROOT"/liberators/*.sh; do
        f="${f##*/}"
        want+="${f%.sh}"$'\n'
    done
    run molt_run_liberators
    assert_success
    [ "$output"$'\n' = "$want" ]
}

@test "a manifest covers the liberators it enables for this platform, in its order" {
    _run_env '[[liberator]]
name = "zsh"
enabled = true
os = ["linux", "macos"]

[[liberator]]
name = "brew"
enabled = true
os = ["macos"]

[[liberator]]
name = "keys"
enabled = false

[[liberator]]
name = "git"
'
    run molt_run_liberators
    assert_success
    [ "$output" = $'zsh\ngit' ]
}
