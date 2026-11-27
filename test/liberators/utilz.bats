#!/usr/bin/env bats
# utilz.bats — utilz liberator: Utilz from a checkout or from Homebrew, as each
# sleeve declares, and a verdict that names the utilz that actually runs
#
# brew is a stub that refuses everything until fake_brew_formula replaces it,
# HOME is a sandbox and molt.toml is a test repo's, so nothing here reaches the
# real Homebrew, ~/bin or manifest.

load "../test_helper.bash"

# A sleeve whose molt.toml has a utilz entry carrying the line $1 (eg
# 'source = "brew"', or none), with the liberator loaded against it.
_utilz_sleeve() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export MOLT_LOCAL_BIN="$HOME/bin"
    export UTILZ_HOME="$BATS_TEST_TMPDIR/Utilz"
    export FAKE_LOG="$BATS_TEST_TMPDIR/calls.log"
    local repo="$BATS_TEST_TMPDIR/molt-testuser"
    mkdir -p "$HOME/bin" "$repo/config" "$BATS_TEST_TMPDIR/stub"
    printf '#!/bin/bash\necho "unfaked brew $*" >> "$FAKE_LOG"\nexit 1\n' > "$BATS_TEST_TMPDIR/stub/brew"
    chmod +x "$BATS_TEST_TMPDIR/stub/brew"
    export PATH="$BATS_TEST_TMPDIR/stub:$PATH"
    printf '[[liberator]]\nname = "utilz"\nenabled = true\n%s\n' "${1:-}" > "$repo/molt.toml"
    load_liberator utilz
    MOLT_USER_REPO_SEARCH_PATHS=("$repo")
}

# A Utilz checkout at UTILZ_HOME, its dispatcher and one utility linked into
# ~/bin and first on PATH, the way a checkout install leaves them.
_utilz_checkout() {
    mkdir -p "$UTILZ_HOME/bin"
    printf '#!/bin/bash\n[[ "$1" == --version ]] && echo "utilz:dev"\n' > "$UTILZ_HOME/bin/utilz"
    chmod +x "$UTILZ_HOME/bin/utilz"
    ln -s utilz "$UTILZ_HOME/bin/cleanz"
    ln -s "$UTILZ_HOME/bin/utilz" "$HOME/bin/utilz"
    ln -s "$UTILZ_HOME/bin/cleanz" "$HOME/bin/cleanz"
    export PATH="$HOME/bin:$PATH"
}

# Homebrew's utilz, by fake_brew_formula with its arguments, as Utilz 2.15.0
# answers: --version prints the brew tree's version line (devbin's dev, opt and
# brew contract, T4), and `use`, which 2.15.0 retired, refuses in Utilz's own
# words. Each call is logged to FAKE_LOG, so a test can show what Molt asked.
_utilz_brew() {
    fake_brew_formula utilz "$@"
    cat > "$FAKE_KEG/bin/utilz" <<EOF
#!/bin/bash
echo "utilz \$*" >> "\$FAKE_LOG"
case "\$1" in
  --version) echo "utilz $1 (brew, 9fad28695cf1)" ;;
  use) echo "✗ utilz use is retired: run 'bin/devbin use' in a Utilz checkout" >&2; exit 2 ;;
  *) exit 1 ;;
esac
EOF
}

# A utilz in the tree at $1 whose --version prints the line $2, linked from
# ~/.local/bin, which comes first on PATH: what `bin/devbin use dev|opt` in a
# Utilz checkout leaves on rhadamanth. Each call is logged to FAKE_LOG. Run
# again, it points the link at the new tree.
_utilz_first() {
    mkdir -p "$1/bin" "$HOME/.local/bin"
    printf '#!/bin/bash\necho "utilz $*" >> "$FAKE_LOG"\n[[ "$1" == --version ]] && echo "%s"\n' "$2" > "$1/bin/utilz"
    chmod +x "$1/bin/utilz"
    ln -sf "$1/bin/utilz" "$HOME/.local/bin/utilz"
    export PATH="$HOME/.local/bin:$PATH"
}

# The warning a brew sleeve gives when PATH runs the utilz that _utilz_first
# made with the line $1, which names Utilz's tree $2.
_utilz_warning() {
    echo "Zen [warning]: utilz (brew): PATH runs $HOME/.local/bin/utilz ($1), Utilz's $2 tree, not brew as this sleeve declares; 'bin/devbin use brew' in the Utilz checkout switches it back"
}

# No line that hv pasted from gyges's molt upgrade on Molt 1.4.14 is in the
# output, with this test's Homebrew prefix in place of /opt/homebrew.
_utilz_refute_field_paste() {
    refute_output_contains "$FAKE_PREFIX/bin/utilz use failed"
    refute_output_contains "utilz use is retired"
    refute_output_contains "Running liberator: utilz (install)"
    refute_output_contains "Liberator failed: utilz"
    refute_output_contains "liberators failed: utilz"
    refute_output_contains "Zen [error]"
}

@test "brew: Utilz 2.15.0 from Homebrew, with ~/.local/bin first on PATH and empty, passes check, install and resleeve, and nothing asks the retired utilz use" {
    # ST0cce65f/87d6, the field replay. gyges and kovacs, 27 Nov 2026: Molt
    # 1.4.14 asked Homebrew's `utilz use`, which Utilz 2.15.0 retired, so molt
    # upgrade said "1 of 21 liberators failed: utilz" and exited 1 before molt
    # maintain ran. PATH is as Molt's zprofile sets it: ~/.local/bin first,
    # with no utilz in it.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 2.15.0 utilz cleanz
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    run utilz_check
    assert_success
    assert_output_contains "utilz (brew): utilz 2.15.0 (brew, 9fad28695cf1) is what PATH runs"
    refute_output_contains "Zen [warning]"
    _utilz_refute_field_paste
    run utilz_install
    assert_success
    assert_output_contains "Liberator complete: utilz"
    _utilz_refute_field_paste
    run molt_resleeve false true
    assert_success
    assert_output_contains "utilz: ✓ ok"
    _utilz_refute_field_paste
    grep -qx "utilz --version" "$FAKE_LOG"
    run grep -q "^utilz use" "$FAKE_LOG"
    assert_failure
}

@test "utilz takes its source from molt.toml: none is checkout, and an unknown one is refused by name" {
    # AT001 (ST0005 AC001).
    _utilz_sleeve
    run _utilz_source
    assert_success
    [ "$output" = "checkout" ]

    _utilz_sleeve 'source = "tarball"'
    run utilz_check
    assert_failure
    assert_output_contains 'source = "tarball" on its molt.toml entry is neither checkout nor brew'
    run utilz_install
    assert_failure
    assert_output_contains 'source = "tarball" on its molt.toml entry is neither checkout nor brew; nothing installed'
    run utilz_upgrade
    assert_failure
    assert_output_contains 'source = "tarball" on its molt.toml entry is neither checkout nor brew; not upgraded'
    [ ! -e "$FAKE_LOG" ]
}

@test "brew: utilz_check passes when Homebrew's utilz runs, and names a command that runs from elsewhere" {
    # AT002 (ST0005 AC002). kovacs, 20 Oct 2026: brew-only by hv's ruling, and the
    # check said "repo not found" over a working Homebrew install.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    run utilz_check
    assert_success
    assert_output_contains "utilz 9.9.9 (brew, 9fad28695cf1) is what PATH runs"

    mkdir -p "$BATS_TEST_TMPDIR/shadow"
    printf '#!/bin/bash\n' > "$BATS_TEST_TMPDIR/shadow/cleanz"
    chmod +x "$BATS_TEST_TMPDIR/shadow/cleanz"
    export PATH="$BATS_TEST_TMPDIR/shadow:$PATH"
    run utilz_check
    assert_failure
    assert_output_contains "other than Homebrew's install, or not at all: cleanz"
    run utilz_verify
    assert_failure
    # install cannot reorder PATH, so it fails rather than report complete,
    # which would let resleeve say "Sleeve ready".
    run utilz_install
    assert_failure
    assert_output_contains "or not at all: cleanz"
}

@test "brew: utilz_install installs by full name and links nothing, and upgrade leaves it to brew" {
    # AT003 (ST0005 AC002).
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    rm "$FAKE_PREFIX/.installed"
    printf '#!/bin/bash\necho "git $*" >> "$FAKE_LOG"\n' > "$BATS_TEST_TMPDIR/stub/git"
    chmod +x "$BATS_TEST_TMPDIR/stub/git"
    run utilz_install
    assert_success
    grep -qx "brew install matthewsinclair/utilz/utilz" "$FAKE_LOG"
    [ ! -e "$HOME/bin/utilz" ]
    [ ! -e "$HOME/bin/cleanz" ]
    run utilz_upgrade
    assert_success
    assert_output_contains "brew upgrade"
    run grep -q "^git" "$FAKE_LOG"
    assert_failure
    run grep -q "^brew upgrade" "$FAKE_LOG"
    assert_failure
}

@test "brew: a keg whose utilities cannot be listed is reported, not passed over" {
    # AT006 (ST0005 AC002). "None runs from elsewhere" over an empty list would
    # vouch for commands the check never looked at.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz
    run utilz_check
    assert_failure
    assert_output_contains "found no utilities in $FAKE_PREFIX/opt/utilz/libexec/bin, so none was checked"
}

@test "brew: a dev or opt tree first on PATH is warned of, naming the tree and 'bin/devbin use brew', passes, and install never moves it" {
    # Issue 0058. rhadamanth, 25 Oct 2026: a dev link set left by the old
    # checkout mode read as PATH running the wrong utilz, with no remedy named.
    # hv's decision 18, 24 Nov 2026: the tree is the user's choice, so Molt
    # warns and does not fail. On rhadamanth, 1.4.10, the dev link ran first on
    # PATH, and Homebrew's check still failed over it, so the link is first on
    # PATH here too, and no PATH fault may come from anywhere. ST0cce65f/87d6:
    # the tree comes from the version line, and Molt asks no `utilz use`.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    local line="utilz 9.9.9 (dev, 1234567890ab)" warning
    _utilz_first "$UTILZ_HOME" "$line"
    warning="$(_utilz_warning "$line" dev)"
    run utilz_check
    assert_success
    assert_output_contains "$warning"
    refute_output_contains "Zen [error]"
    refute_output_contains "not Homebrew's"
    run utilz_verify
    assert_success
    assert_output_contains "$warning"
    refute_output_contains "Zen [error]"
    refute_output_contains "not Homebrew's"
    run utilz_install
    assert_success
    assert_output_contains "$warning"
    refute_output_contains "Zen [error]"
    refute_output_contains "not Homebrew's"
    [ "$(readlink "$HOME/.local/bin/utilz")" = "$UTILZ_HOME/bin/utilz" ]
    run grep -q "^utilz use" "$FAKE_LOG"
    assert_failure

    line="utilz 9.9.9 (opt, 1234567890ab)"
    _utilz_first "$BATS_TEST_TMPDIR/opt/utilz" "$line"
    run utilz_check
    assert_success
    assert_output_contains "$(_utilz_warning "$line" opt)"
    refute_output_contains "Zen [error]"
    refute_output_contains "not Homebrew's"
}

@test "brew: resleeve shows a dev tree's warning once, with utilz ok, and once when install runs after the check" {
    # Molt 1.4.12. rhadamanth, 24 Nov 2026: molt upgrade on 1.4.11 printed
    # "utilz: ✓ ok" and no warning, because resleeve drops a check's stderr.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    local line="utilz 9.9.9 (dev, 1234567890ab)" warning
    _utilz_first "$UTILZ_HOME" "$line"
    warning="$(_utilz_warning "$line" dev)"
    run molt_resleeve false true
    assert_success
    assert_output_contains "utilz: ✓ ok"
    refute_output_contains "Zen [error]"
    [ "$(grep -cxF "$warning" <<< "$output")" = 1 ]

    # A formula Homebrew does not trust fails the check, so install runs after
    # it, and the two see the same tree.
    touch "$FAKE_PREFIX/.gate"
    run molt_resleeve false true
    assert_success
    assert_output_contains "utilz: ✓ installed"
    refute_output_contains "Zen [error]"
    [ "$(grep -cxF "$warning" <<< "$output")" = 1 ]
}

@test "brew: doctor shows a dev tree's warning once, with utilz installed" {
    # vc todo 61. Molt 1.4.12: doctor dropped what a check printed when it
    # passed, so the warning that resleeve and upgrade show was lost there.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    local line="utilz 9.9.9 (dev, 1234567890ab)" warning
    _utilz_first "$UTILZ_HOME" "$line"
    warning="$(_utilz_warning "$line" dev)"
    run cmd_doctor
    assert_output_contains "Checking enabled liberators... ✓ all installed"
    refute_output_contains "not installed: utilz"
    [ "$(grep -cF "$warning" <<< "$output")" = 1 ]
}

@test "brew: a version line that names no dev, opt or brew tree fails the check, and its one fault quotes the line" {
    # ST0cce65f/87d6. The tree is read from the version line alone (devbin's
    # contract, T4), so a line with no tree, or with T4's unknown, says nothing
    # of the switch, and a PATH fault beside it would only repeat it.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    _utilz_first "$BATS_TEST_TMPDIR/elsewhere" "utilz 2.14.0"
    run utilz_check
    assert_failure
    assert_output_contains "utilz (brew): PATH runs $HOME/.local/bin/utilz, whose version line names no dev, opt or brew tree: 'utilz 2.14.0'"
    refute_output_contains "not Homebrew's"

    _utilz_first "$BATS_TEST_TMPDIR/elsewhere" "utilz 2.15.0 (unknown, unknown)"
    run utilz_check
    assert_failure
    assert_output_contains "utilz (brew): PATH runs $HOME/.local/bin/utilz, whose version line names no dev, opt or brew tree: 'utilz 2.15.0 (unknown, unknown)'"
    refute_output_contains "not Homebrew's"
}

@test "checkout: utilz_check passes when the checkout's utilz runs, and names Homebrew's when it runs instead" {
    # AT004 (ST0005 AC003). rhadamanth, 20 Oct 2026: Homebrew's utilz ran ahead of
    # the checkout's links, and the check said healthy because it asked only
    # whether its link resolved.
    _utilz_sleeve 'source = "checkout"'
    _utilz_checkout
    run utilz_check
    assert_success
    assert_output_contains "utilz:dev is what PATH runs"

    fake_brew_formula utilz 9.9.9 utilz cleanz
    run utilz_check
    assert_failure
    assert_output_contains "PATH runs $FAKE_PREFIX/bin/utilz (utilz:9.9.9), not the checkout's $UTILZ_HOME/bin/utilz"
    assert_output_contains "other than the checkout, or not at all: cleanz"
    run utilz_install
    assert_failure
    assert_output_contains "PATH runs $FAKE_PREFIX/bin/utilz"
}

@test "a formula Homebrew does not trust is reported, and install trusts exactly that formula" {
    # AT005 (ST0005 AC004). Homebrew 7.0.10 leaves an installed formula from an
    # untrusted tap out of a plain brew upgrade, with a warning and exit 0.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    touch "$FAKE_PREFIX/.gate"
    run utilz_check
    assert_failure
    assert_output_contains "does not trust matthewsinclair/utilz/utilz"
    run utilz_install
    assert_success
    grep -qx "brew trust --formula matthewsinclair/utilz/utilz" "$FAKE_LOG"
    run grep -q "^brew install" "$FAKE_LOG"
    assert_failure
    run utilz_check
    assert_success

    # Trusting the tap covers its formulae too.
    echo '{"taps":["matthewsinclair/utilz"],"formulae":[]}' > "$FAKE_PREFIX/trust.json"
    run utilz_check
    assert_success

    # A trust store that cannot be read is reported as that, not passed as trusted.
    touch "$FAKE_PREFIX/.store-unreadable"
    run utilz_check
    assert_failure
    assert_output_contains "brew trust --json=v1 failed, so whether brew upgrade includes matthewsinclair/utilz/utilz is unknown"
}

@test "checkout: utilz_upgrade reports Utilz updated, warns when it has no upstream, and fails, naming the repo and git's reason, when its pull fails" {
    _utilz_sleeve
    clone_test_origin "$UTILZ_HOME" bin/utilz
    assert_upgrade_hook_pulls utilz_upgrade Utilz "$UTILZ_HOME"
    [ ! -e "$FAKE_LOG" ]
}
