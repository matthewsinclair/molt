#!/usr/bin/env bats
# intent.bats — intent liberator: Intent from Homebrew, and a verdict that names
# the Intent that actually runs
#
# brew is the shared stub (fake_brew_formula) and intent a stub in its keg, and
# XDG_DATA_HOME puts the gate home in the test directory. Nothing here reaches
# the real Homebrew or gate home.

load "../test_helper.bash"

# Homebrew's Intent installed, linked and first on PATH, with a gate home naming
# its install. Each test then breaks one thing.
_fake_brew_intent() {
    fake_brew_formula intent 9.9.9 intent
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/xdg"
    mkdir -p "$FAKE_KEG/lib/templates" "$XDG_DATA_HOME/intent"
    cat > "$FAKE_KEG/bin/intent" <<'EOF'
#!/bin/bash
case "$1" in
  --version) echo "intent 9.9.9 (fake)" ;;
  bootstrap) echo "intent bootstrap" >> "$FAKE_LOG" ;;
esac
EOF
    echo "$FAKE_KEG" > "$XDG_DATA_HOME/intent/home"
}

@test "intent_check passes when Homebrew's intent is what PATH and the gate run" {
    _fake_brew_intent
    load_liberator intent
    run intent_check
    assert_success
    assert_output_contains "intent 9.9.9 (fake)"
}

@test "intent_check FAILS, naming it, when PATH runs another intent" {
    # AT001 (ST0004 AC002). gyges, 23 Sep 2026: a link to Intent 2.6.0 checked ok while a login shell
    # ran Homebrew's 3.2.0 and a non-login shell ran the 2.6.0.
    _fake_brew_intent
    mkdir -p "$BATS_TEST_TMPDIR/v2"
    printf '#!/bin/bash\necho "Intent version 2.6.0"\n' > "$BATS_TEST_TMPDIR/v2/intent"
    chmod +x "$BATS_TEST_TMPDIR/v2/intent"
    export PATH="$BATS_TEST_TMPDIR/v2:$PATH"
    load_liberator intent
    run intent_check
    assert_failure
    assert_output_contains "PATH runs $BATS_TEST_TMPDIR/v2/intent (Intent version 2.6.0)"
    run intent_verify
    assert_failure
}

@test "intent_check FAILS when the gate home names an install that is gone" {
    # AT002 (ST0004 AC003). What a brew upgrade leaves behind when the gate home names a versioned
    # keg and cleanup has removed it.
    _fake_brew_intent
    echo "$FAKE_PREFIX/Cellar/intent/9.9.8/libexec" > "$XDG_DATA_HOME/intent/home"
    load_liberator intent
    run intent_check
    assert_failure
    assert_output_contains "install is gone"
}

@test "intent_install installs from the tap and bootstraps a missing gate home" {
    _fake_brew_intent
    rm "$FAKE_PREFIX/.installed" "$XDG_DATA_HOME/intent/home"
    load_liberator intent
    run intent_install
    assert_success
    grep -qx "brew install matthewsinclair/intent/intent" "$FAKE_LOG"
    grep -qx "intent bootstrap" "$FAKE_LOG"
}

@test "intent_install leaves a gate home that points at another install alone" {
    # bootstrap repoints whatever is there. A deliberately placed pointer is the
    # check's to report, not install's to move.
    _fake_brew_intent
    mkdir -p "$BATS_TEST_TMPDIR/checkout/lib/templates"
    echo "$BATS_TEST_TMPDIR/checkout" > "$XDG_DATA_HOME/intent/home"
    load_liberator intent
    run intent_install
    assert_success
    [ ! -e "$FAKE_LOG" ]
    run intent_check
    assert_failure
    assert_output_contains "gate runs $BATS_TEST_TMPDIR/checkout"
}
