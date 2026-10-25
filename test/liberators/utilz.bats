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

# Homebrew's utilz, by fake_brew_formula with its arguments, whose `use` answers
# as Utilz's does with no link set. `use` prints use.out and exits with use.rc
# from FAKE_PREFIX, and logs each call to FAKE_LOG; _utilz_use replaces both.
_utilz_brew() {
    fake_brew_formula utilz "$@"
    cat > "$FAKE_KEG/bin/utilz" <<EOF
#!/bin/bash
[[ "\$1" == --version ]] && { echo "utilz:$1"; exit 0; }
[[ "\$1" == use ]] || exit 1
echo "utilz \$*" >> "\$FAKE_LOG"
cat "\$FAKE_PREFIX/use.out"
exit "\$(cat "\$FAKE_PREFIX/use.rc")"
EOF
    _utilz_use 0 "links: $HOME/.local/bin" "  brew: no links, and $FAKE_PREFIX/bin/utilz (the Homebrew install) answers"
}

# What Homebrew's `utilz use` says next: exit status $1, and each further
# argument a line of its output.
_utilz_use() {
    echo "$1" > "$FAKE_PREFIX/use.rc"
    shift
    printf '%s\n' "$@" > "$FAKE_PREFIX/use.out"
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
    assert_output_contains "utilz:9.9.9 is what PATH runs"

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

@test "brew: with no link set, Homebrew's utilz use is asked and the PATH check stands" {
    # Issue 0058.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    run utilz_check
    assert_success
    assert_output_contains "utilz:9.9.9 is what PATH runs"
    [ "$(cat "$FAKE_LOG")" = "utilz use" ]
}

@test "brew: a dev or opt link set fails the check, naming its tree and 'utilz use brew', and install never moves it" {
    # Issue 0058. rhadamanth, 25 Oct 2026: a dev link set left by the old
    # checkout mode read as PATH running the wrong utilz, with no remedy named.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    _utilz_use 0 "links: $HOME/.local/bin" "  dev at $UTILZ_HOME -- 2 link(s)"
    run utilz_check
    assert_failure
    assert_output_contains "utilz use has pointed its links at dev at $UTILZ_HOME, not brew as this sleeve declares; 'utilz use brew' points them back"
    run utilz_verify
    assert_failure
    assert_output_contains "'utilz use brew' points them back"
    run utilz_install
    assert_failure
    assert_output_contains "'utilz use brew' points them back"
    run grep -v '^utilz use$' "$FAKE_LOG"
    assert_failure

    _utilz_use 0 "links: $HOME/.local/bin" "  opt at /opt/utilz -- 2 link(s)"
    run utilz_check
    assert_failure
    assert_output_contains "utilz use has pointed its links at opt at /opt/utilz, not brew"
}

@test "brew: a utilz use that fails, or reports shadowing, fails the check in its own words" {
    # Issue 0058.
    _utilz_sleeve 'source = "brew"'
    _utilz_brew 9.9.9 utilz cleanz
    _utilz_use 1 "links: $HOME/.local/bin" "  brew: no links" "✗ cleanz in $HOME/.local/bin is shadowed: the first cleanz on PATH is /elsewhere/cleanz"
    run utilz_check
    assert_failure
    assert_output_contains "$FAKE_PREFIX/bin/utilz use failed (exit 1), and said:"
    assert_output_contains "✗ cleanz in $HOME/.local/bin is shadowed: the first cleanz on PATH is /elsewhere/cleanz"

    _utilz_use 2
    run utilz_check
    assert_failure
    assert_output_contains "$FAKE_PREFIX/bin/utilz use failed (exit 2), and said nothing"
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
