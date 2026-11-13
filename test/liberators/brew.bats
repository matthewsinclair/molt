#!/usr/bin/env bats
# brew.bats — brew liberator: maintain fails, naming the step, when brew does
# (issue 0052), and a sleeve's Brewfile is checked and installed through brew
# bundle (issue 0101)

load "../test_helper.bash"

# A fake brew that records each call and fails the one whose arguments are
# $BREW_FAIL, saying $BREW_SAYS on stderr as it does, and a fake npm, on a PATH
# that holds nothing else of theirs. A call made with HOMEBREW_NO_AUTO_UPDATE
# set is recorded in $CALLS.no-auto-update as well.
#
# The liberator finds no user repo, so no Brewfile: with MOLT_PRJ_DIR set, the
# search constants.sh builds reaches the stack of whoever runs bats, and its
# sleeve's Brewfile. The search holds one empty folder, not none: an empty
# array trips set -u under bash 3.2.
_brew_env() {
    load_liberator brew
    FAKES="$BATS_TEST_TMPDIR/fakes"
    CALLS="$BATS_TEST_TMPDIR/brew-calls"
    mkdir -p "$FAKES" "$BATS_TEST_TMPDIR/no-user-repo"
    MOLT_USER_REPO_SEARCH_PATHS=("$BATS_TEST_TMPDIR/no-user-repo")
    cat > "$FAKES/brew" <<FAKE
#!/bin/sh
echo "\$*" >> "$CALLS"
[ -z "\${HOMEBREW_NO_AUTO_UPDATE:-}" ] || echo "\$*" >> "$CALLS.no-auto-update"
[ "\$*" != "\${BREW_FAIL:-}" ] && exit 0
[ -z "\${BREW_SAYS:-}" ] || echo "\$BREW_SAYS" >&2
exit 1
FAKE
    printf '#!/bin/sh\nexit 0\n' > "$FAKES/npm"
    chmod +x "$FAKES/brew" "$FAKES/npm"
    export PATH="$FAKES:/bin:/usr/bin"
}

# _brew_env, with a user repo of the test's own as the only one found, holding
# this sleeve's Brewfile, $BREWFILE. The fake brew never reads it.
_brewfile_env() {
    _brew_env
    local repo="$BATS_TEST_TMPDIR/repo"
    BREWFILE="$repo/instances/$(test_hostname)/Brewfile"
    mkdir -p "$repo/config" "${BREWFILE%/*}"
    printf 'brew "pigz"\n' > "$BREWFILE"
    MOLT_USER_REPO_SEARCH_PATHS=("$repo")
}

# brew_check as resleeve runs it, with what the check writes to stderr dropped.
_brew_check_stdout() {
    brew_check 2>/dev/null
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

# hv, 13 Nov: a sleeve lists the packages it needs in a Brewfile of its own in
# the user repo, and the brew liberator has Homebrew install what is missing
# from it (issue 0101). A check is a read: brew bundle check is asked with
# --no-upgrade, which passes a listed formula that is only outdated, and with
# HOMEBREW_NO_AUTO_UPDATE set, since bundle is among the commands Homebrew
# updates itself before, so a check without it would fetch.
@test "with a Brewfile brew check and verify pass when brew bundle check does, asked with no upgrade and no update (issue 0101)" {
    _brewfile_env
    run brew_check
    assert_success
    run brew_verify
    assert_success
    assert_output_contains "Verified: brew liberator is fully operational"
    grep -Fqx "bundle check --verbose --no-upgrade --file=$BREWFILE" "$CALLS.no-auto-update"
    # Nothing else was asked of brew, with an update or without one.
    run grep -Fxv "bundle check --verbose --no-upgrade --file=$BREWFILE" "$CALLS" "$CALLS.no-auto-update"
    [ -z "$output" ]
}

# brew prints what is missing on stderr, which resleeve drops from a check, so
# the check says it again on stdout.
@test "with a Brewfile brew check and verify fail, saying what brew bundle check names as missing, the check on stdout, and naming the Brewfile (issue 0101)" {
    _brewfile_env
    export BREW_FAIL="bundle check --verbose --no-upgrade --file=$BREWFILE"
    export BREW_SAYS="brew bundle can't satisfy your Brewfile's dependencies.
→ Formula pigz needs to be installed.
Satisfy missing dependencies with \`brew bundle install\`."
    run _brew_check_stdout
    assert_failure
    assert_output_contains "Zen: brew: → Formula pigz needs to be installed."
    assert_output_contains "Zen: brew: this sleeve's Brewfile is $BREWFILE, and molt resleeve installs what it lists"
    run brew_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: brew: → Formula pigz needs to be installed."
    refute_output_contains "Verified: brew liberator is fully operational"
}

@test "with a Brewfile brew_install has brew bundle install what is missing, and asks brew for no upgrade and no cleanup (issue 0101)" {
    _brewfile_env
    run brew_install
    assert_success
    assert_output_contains "Liberator complete: brew"
    grep -Fqx "bundle install --no-upgrade --file=$BREWFILE" "$CALLS"
    # The one thing asked of brew: the file is a minimum, so nothing it leaves
    # out is removed, and brew_maintain is what upgrades.
    run grep -Fxv "bundle install --no-upgrade --file=$BREWFILE" "$CALLS"
    [ -z "$output" ]
}

@test "with a Brewfile brew_install fails under brew's own words, naming the Brewfile, when brew bundle install fails (issue 0101)" {
    _brewfile_env
    BREW_FAIL="bundle install --no-upgrade --file=$BREWFILE" BREW_SAYS='Error: No available formula with the name "pigz".' run brew_install
    assert_failure
    assert_output_contains 'Error: No available formula with the name "pigz".'
    assert_output_contains "brew: brew bundle install failed for $BREWFILE (above)"
    refute_output_contains "Liberator complete: brew"
}

# kovacs has no Brewfile, and a sleeve without one is as it was before 0101.
@test "with no Brewfile for this sleeve brew check, install and verify pass, and brew is asked nothing (issue 0101)" {
    _brewfile_env
    rm "$BREWFILE"
    run brew_check
    assert_success
    run brew_install
    assert_success
    run brew_verify
    assert_success
    assert_file_not_exists "$CALLS"
}
