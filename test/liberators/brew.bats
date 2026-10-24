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

@test "brew_maintain passes when every brew step passes" {
    _brew_env
    run brew_maintain
    assert_success
    assert_output_contains "Homebrew maintenance complete."
}

@test "brew_maintain fails, naming the step, when update, upgrade, upgrade --cask or cleanup fails" {
    _brew_env
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
