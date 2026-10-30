#!/usr/bin/env bats
# brew.bats — brew liberator: maintain fails, naming the step, when brew does (issue 0052)

load "../test_helper.bash"

# A fake brew that records each call and fails the one whose arguments are
# $BREW_FAIL, and a fake npm, on a PATH that holds nothing else of theirs.
_brew_env() {
    load_liberator brew
    FAKES="$BATS_TEST_TMPDIR/fakes"
    CALLS="$BATS_TEST_TMPDIR/brew-calls"
    mkdir -p "$FAKES"
    cat > "$FAKES/brew" <<FAKE
#!/bin/sh
echo "\$*" >> "$CALLS"
[ "\$*" != "\${BREW_FAIL:-}" ]
FAKE
    printf '#!/bin/sh\nexit 0\n' > "$FAKES/npm"
    chmod +x "$FAKES/brew" "$FAKES/npm"
    export PATH="$FAKES:/bin:/usr/bin"
}

@test "on macOS brew_maintain passes when every brew step passes, the cask upgrade among them" {
    _brew_env
    eval 'molt_platform() { echo macos; }'
    run brew_maintain
    assert_success
    assert_output_contains "Homebrew maintenance complete."
    grep -qx "upgrade --cask" "$CALLS"
}

@test "on macOS brew_maintain fails, naming the step, when update, upgrade, upgrade --cask or cleanup fails" {
    _brew_env
    eval 'molt_platform() { echo macos; }'
    local step
    for step in "update" "upgrade" "upgrade --cask" "cleanup -s"; do
        rm -f "$CALLS"
        BREW_FAIL="$step" run brew_maintain
        assert_failure
        assert_output_contains "Homebrew maintenance failed: brew $step (above)"
        refute_output_contains "Homebrew maintenance complete."
        grep -qx "cleanup -s" "$CALLS"
    done
}

# kovacs, 30 Oct: the brew liberator was macOS only, so nothing upgraded
# Linuxbrew there (issue 0077). It runs wherever brew is on PATH, and casks
# are macOS's alone.
@test "on Linux brew_maintain runs update, upgrade and cleanup, and not the cask upgrade (issue 0077)" {
    _brew_env
    eval 'molt_platform() { echo linux; }'
    run brew_maintain
    assert_success
    assert_output_contains "Homebrew maintenance complete."
    grep -qx "update" "$CALLS"
    grep -qx "upgrade" "$CALLS"
    grep -qx "cleanup -s" "$CALLS"
    run grep -qx "upgrade --cask" "$CALLS"
    assert_failure
}

@test "on Linux brew check, install and verify pass with brew on PATH (issue 0077)" {
    _brew_env
    eval 'molt_platform() { echo linux; }'
    run brew_check
    assert_success
    run brew_install
    assert_success
    run brew_verify
    assert_success
}

@test "on Linux brew check and verify fail, naming Homebrew, with no brew on PATH (issue 0077)" {
    _brew_env
    eval 'molt_platform() { echo linux; }'
    export PATH="/bin:/usr/bin"
    run command -v brew
    assert_failure
    run brew_check
    assert_failure
    assert_output_contains "brew: Homebrew not installed"
    run brew_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: brew not installed"
}
