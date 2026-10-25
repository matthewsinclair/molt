#!/usr/bin/env bash
# test_helper.bash — Shared BATS test infrastructure for MOLT
#
# Adapted from Utilz test_helper.bash. Provides:
# - Setup/teardown for test isolation
# - Assertion helpers
# - Molt-specific test utilities
#
# Usage: load "test_helper.bash" at the top of each .bats file

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# Determine MOLT_ROOT from this script's location (test/ is one level down)
MOLT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MOLT_ROOT
export MOLT_BIN_DIR="$MOLT_ROOT/bin"
export MOLT_LIB_DIR="$MOLT_ROOT/lib"
export MOLT_TEST_DIR="$MOLT_ROOT/test"

# Put molt on PATH
export PATH="$MOLT_BIN_DIR:$PATH"

# Disable colors in tests for consistent output
export NO_COLOR=1
export TERM=dumb

# Claude Code keeps its state wherever CLAUDE_CONFIG_DIR says, so a test that
# inherited it from the shell running bats would read and write the real config
# dir, whatever it did to HOME (ST0006). No test starts with either set.
unset CLAUDE_CONFIG_DIR XDG_CONFIG_HOME

# Nor with the agents root the shell running bats exports, which the user
# repo's zshenv sets: a resleeve of an [[agent]] fixture would make homes there.
# setup gives each test a root of its own; this one, removed with the run, is
# for the files whose setup replaces it.
export MOLT_AGT_DIR="${BATS_RUN_TMPDIR:-${BATS_TMPDIR:-/tmp}}/molt-test-agt"

# Nor with the host's AppArmor profiles, which molt writes through sudo: the
# same, for MOLT_APPARMOR_DIR (issue 0061). setup gives each test one of its
# own, made only by a test that wants one.
export MOLT_APPARMOR_DIR="${BATS_RUN_TMPDIR:-${BATS_TMPDIR:-/tmp}}/molt-test-apparmor.d"

# Nor reaching the host's root-owned state: molt doctor, status and list ask
# launchd with launchctl getenv (issue 0059), and the agents liberator's sandbox
# profile goes through sudo and apparmor_parser (issue 0061). These, first on
# PATH, record their argv in calls.log beside them and do nothing. They are set
# here rather than in setup, which some files replace; a test that fakes one
# puts its own in front.
_molt_test_stub_dir="${BATS_RUN_TMPDIR:-${BATS_TMPDIR:-/tmp}}/molt-test-stubs"
for _molt_test_stub in launchctl sudo apparmor_parser; do
    if [[ ! -x "$_molt_test_stub_dir/$_molt_test_stub" ]]; then
        mkdir -p "$_molt_test_stub_dir"
        printf '#!/bin/sh\necho "%s $*" >> "%s/calls.log"\n' "$_molt_test_stub" "$_molt_test_stub_dir" \
            > "$_molt_test_stub_dir/$_molt_test_stub"
        chmod +x "$_molt_test_stub_dir/$_molt_test_stub"
    fi
done
export PATH="$_molt_test_stub_dir:$PATH"
unset _molt_test_stub_dir _molt_test_stub

# Nor with the runner's git config, or the machine's: an identity, a signing
# key or a url rewrite there would decide what a test's git does (issue 0062).
# A helper that commits names its own identity.
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="${BATS_RUN_TMPDIR:-${BATS_TMPDIR:-/tmp}}/molt-test-gitconfig"
: > "$GIT_CONFIG_GLOBAL"

# ============================================================================
# SETUP AND TEARDOWN
# ============================================================================

# Per-file setup — runs once before all tests in a file
setup_file() {
    export MOLT_TEST_TMPDIR="${BATS_FILE_TMPDIR:-/tmp}/molt-test-$$"
    mkdir -p "$MOLT_TEST_TMPDIR"
}

# Per-file teardown — runs once after all tests in a file
teardown_file() {
    if [[ -n "$MOLT_TEST_TMPDIR" && -d "$MOLT_TEST_TMPDIR" ]]; then
        rm -rf "$MOLT_TEST_TMPDIR"
    fi
}

# Per-test setup — runs before each test
setup() {
    BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    export BATS_TEST_TMPDIR
    mkdir -p "$BATS_TEST_TMPDIR"
    # A root no other test, run or worktree shares (critic-shell, 21 Oct).
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export MOLT_APPARMOR_DIR="$BATS_TEST_TMPDIR/apparmor.d"
    ORIGINAL_PWD="$(pwd)"
    export ORIGINAL_PWD
    cd "$BATS_TEST_TMPDIR" || return
}

# Per-test teardown — runs after each test
teardown() {
    if [[ -n "$ORIGINAL_PWD" && -d "$ORIGINAL_PWD" ]]; then
        # shellcheck disable=SC2164 # bats runs teardown with errexit off, and the
        # cleanup below must still run when this cd fails, as it always has
        cd "$ORIGINAL_PWD"
    fi
    if [[ -n "$BATS_TEST_TMPDIR" && -d "$BATS_TEST_TMPDIR" ]]; then
        rm -rf "$BATS_TEST_TMPDIR"
    fi
}

# ============================================================================
# EXECUTION HELPERS
# ============================================================================

# Run the molt CLI with arguments
# Usage: run_molt help
#        run_molt doctor
run_molt() {
    run "$MOLT_BIN_DIR/molt" "$@"
}

# Source molt core libraries into the test shell
# Usage: load_molt_libs (call in setup or test body)
load_molt_libs() {
    source "$MOLT_LIB_DIR/constants.sh"
    source "$MOLT_LIB_DIR/molt.sh"
    source "$MOLT_LIB_DIR/liberator.sh"
    source "$MOLT_LIB_DIR/agent.sh"
    source "$MOLT_LIB_DIR/install.sh"
    source "$MOLT_LIB_DIR/env.sh"
    no_gsettings
}

# molt has looked for gsettings and found none, so the host's own cannot
# decide what a liberator says on Linux (issue 0047). load_molt_libs starts
# every test here.
no_gsettings() {
    _MOLT_GSETTINGS_STATUS=1
    # shellcheck disable=SC2034 # read by lib/molt.sh, which the test has sourced
    MOLT_GSETTINGS_FAULT="gsettings is not on PATH"
}

# Lets molt choose a gsettings from PATH again, for a test that has put its own
# fake there.
gsettings_from_path() {
    unset _MOLT_GSETTINGS_STATUS
}

# Load a specific liberator for function-level testing
# Usage: load_liberator zsh
load_liberator() {
    local name="$1"
    # Ensure core libs are loaded first
    if ! declare -f molt_info &>/dev/null; then
        load_molt_libs
    fi
    # shellcheck source=/dev/null # the liberator is named by the caller
    source "$MOLT_ROOT/liberators/${name}.sh"
}

# ============================================================================
# TEST DATA CREATION
# ============================================================================

# This sleeve's short hostname, the name of its instances/ directory, for a
# test to build the path it expects. Worked out here, not by molt_hostname: a
# test that computed its expected path with the code under test would agree
# with a wrong answer (issue 0020).
# Usage: vars="$repo/instances/$(test_hostname)/vars.sh"
test_hostname() {
    local name
    name="$(hostname -s 2>/dev/null || hostname)"
    echo "${name%%.*}"
}

# The permission bits of $1 in octal, eg 600, for a test to compare with the
# mode it expects. GNU stat first: its -f means --file-system, so BSD's form
# would print a block of filesystem facts on Linux.
test_file_mode() {
    stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

# Clone an origin made in the test directory, holding the executable files
# named relative to it, into dest, and set TEST_ORIGIN to the origin, so a test
# can unset the clone's upstream or remove the origin to make a pull fail.
# Usage: clone_test_origin "$UTILZ_HOME" bin/utilz
clone_test_origin() {
    local dest="$1" f
    shift
    TEST_ORIGIN="$BATS_TEST_TMPDIR/$(basename "$dest")-origin"
    mkdir -p "$TEST_ORIGIN"
    for f in "$@"; do
        mkdir -p "$TEST_ORIGIN/$(dirname "$f")"
        printf '#!/bin/bash\n' > "$TEST_ORIGIN/$f"
        chmod +x "$TEST_ORIGIN/$f"
    done
    : > "$TEST_ORIGIN/README"
    git -C "$TEST_ORIGIN" init -q
    git -C "$TEST_ORIGIN" add -A
    git -c user.name=test -c user.email=test@example.com -C "$TEST_ORIGIN" commit -qm init
    git clone -q "$TEST_ORIGIN" "$dest"
}

# An upgrade hook pulling the clone_test_origin repo at $repo reports it
# updated; with no upstream it warns and passes; with its origin gone it fails,
# naming the repo and git's reason (issue 0037).
# Usage: assert_upgrade_hook_pulls web_upgrade web "$repo"
assert_upgrade_hook_pulls() {
    local hook="$1" label="$2" repo="$3"
    run "$hook"
    assert_success
    assert_output_contains "$label repo updated."

    git -C "$repo" branch -q --unset-upstream
    run "$hook"
    assert_success
    assert_output_contains "$label pull skipped: $repo has no upstream branch"
    refute_output_contains "$label repo updated."

    git -C "$repo" branch -q --set-upstream-to="origin/$(git -C "$repo" branch --show-current)"
    rm -rf "$TEST_ORIGIN"
    run "$hook"
    assert_failure
    assert_output_contains "$label pull failed in $repo:"
    assert_output_contains "$TEST_ORIGIN"
    refute_output_contains "pull skipped"
    refute_output_contains "$label repo updated."
}

# Create a mock molt-{user} repo with config/ directory
# Usage: create_test_repo "$BATS_TEST_TMPDIR/molt-testuser"
create_test_repo() {
    local path="$1"
    mkdir -p "$path/config/zsh"
    mkdir -p "$path/config/git"
    mkdir -p "$path/config/tmux"
    mkdir -p "$path/instances"

    # Create minimal config files
    echo "# test zshrc" > "$path/config/zsh/zshrc"
    echo "# test zshenv" > "$path/config/zsh/zshenv"
    echo "# test zprofile" > "$path/config/zsh/zprofile"
    echo "# test gitconfig" > "$path/config/git/gitconfig"
    echo "# test tmux.conf" > "$path/config/tmux/tmux.conf"
}

# Create a test molt.toml manifest
# Usage: create_test_manifest "$BATS_TEST_TMPDIR/molt-testuser/molt.toml"
create_test_manifest() {
    local path="$1"
    cat > "$path" <<'TOML'
[stack]
name = "test-stack"
version = "0.1.0"

[[liberator]]
name = "zsh"
enabled = true
os = ["linux", "macos"]

[[liberator]]
name = "git"
enabled = true
os = ["linux", "macos"]

[[liberator]]
name = "keys"
enabled = false
os = ["linux"]

[[liberator]]
name = "desktop"
enabled = true
os = ["linux"]
TOML
}

# ============================================================================
# FAKE HOMEBREW
# ============================================================================

# Puts a fake sudo first on PATH: it logs each call to $BATS_TEST_TMPDIR/sudo.log
# and runs the command it is given, unless FAKE_SUDO_STATUS says otherwise.
install_fake_sudo() {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/sudo" <<'FAKE'
#!/usr/bin/env bash
echo "sudo $*" >> "$BATS_TEST_TMPDIR/sudo.log"
[ "${FAKE_SUDO_STATUS:-0}" -eq 0 ] || exit "$FAKE_SUDO_STATUS"
exec "$@"
FAKE
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo"
    case ":$PATH:" in
        *":$BATS_TEST_TMPDIR/bin:"*) ;;
        *) export PATH="$BATS_TEST_TMPDIR/bin:$PATH" ;;
    esac
}

# AppArmor in the test directory: $MOLT_APPARMOR_DIR, which setup points at
# $BATS_TEST_TMPDIR/apparmor.d, made here, and a fake apparmor_parser, bwrap and
# unshare go first on PATH, with the fake sudo. The parser logs each call to
# $BATS_TEST_TMPDIR/apparmor.log and exits FAKE_PARSER_STATUS, or
# FAKE_PARSER_CHECK_STATUS for a -Q parse that loads nothing; bwrap exits
# FAKE_BWRAP_STATUS, saying why on stderr as unshare does. Neither the real
# /etc/apparmor.d nor the kernel's policy is reached.
install_fake_apparmor() {
    install_fake_sudo
    mkdir -p "$MOLT_APPARMOR_DIR"
    cat > "$BATS_TEST_TMPDIR/bin/apparmor_parser" <<'FAKE'
#!/usr/bin/env bash
echo "apparmor_parser $*" >> "$BATS_TEST_TMPDIR/apparmor.log"
[ "$1" = -Q ] && exit "${FAKE_PARSER_CHECK_STATUS:-0}"
exit "${FAKE_PARSER_STATUS:-0}"
FAKE
    cat > "$BATS_TEST_TMPDIR/bin/bwrap" <<'FAKE'
#!/usr/bin/env bash
[ "${FAKE_BWRAP_STATUS:-0}" -eq 0 ] && exit 0
echo "unshare: write failed /proc/self/uid_map: Operation not permitted" >&2
exit "$FAKE_BWRAP_STATUS"
FAKE
    printf '#!/bin/sh\nexit 0\n' > "$BATS_TEST_TMPDIR/bin/unshare"
    chmod +x "$BATS_TEST_TMPDIR/bin/apparmor_parser" "$BATS_TEST_TMPDIR/bin/bwrap" "$BATS_TEST_TMPDIR/bin/unshare"
}

# pgrep and ps first on PATH, answering from a process table in the test
# directory, $FAKE_PROCS, never from this machine's, where a Claude Code may
# well be running. pgrep applies the pattern it is given, so what counts as
# Claude Code is decided here as it is in production, logs its arguments to
# $FAKE_PROCS.args, for a test of -a, and exits FAKE_PGREP_STATUS where that is
# set. The table starts empty; fake_processes fills it.
install_fake_process_table() {
    export FAKE_PROCS="$BATS_TEST_TMPDIR/procs"
    : > "$FAKE_PROCS"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/pgrep" <<'FAKE'
#!/bin/bash
# pgrep [-a] -u <uid> -f <pattern>: the pids in $FAKE_PROCS whose command line
# matches.
echo "$*" >> "$FAKE_PROCS.args"
[ -z "${FAKE_PGREP_STATUS:-}" ] || exit "$FAKE_PGREP_STATUS"
for pattern; do :; done
awk -v pat="$pattern" '{ args = $0; sub(/^[0-9]+ /, "", args) } args ~ pat { print $1; n++ } END { exit n ? 0 : 1 }' "$FAKE_PROCS"
FAKE
    cat > "$BATS_TEST_TMPDIR/bin/ps" <<'FAKE'
#!/bin/bash
# ps -o pid=,args= -p <pid,pid>: those rows of $FAKE_PROCS.
for pids; do :; done
awk -v pids=",$pids," 'index(pids, "," $1 ",")' "$FAKE_PROCS"
FAKE
    chmod +x "$BATS_TEST_TMPDIR/bin/pgrep" "$BATS_TEST_TMPDIR/bin/ps"
    case ":$PATH:" in
        *":$BATS_TEST_TMPDIR/bin:"*) ;;
        *) export PATH="$BATS_TEST_TMPDIR/bin:$PATH" ;;
    esac
}

# The process table the fake pgrep and ps answer from, one "pid command line"
# per argument.
fake_processes() {
    printf '%s\n' "$@" > "$FAKE_PROCS"
}

# A Homebrew prefix in the test directory holding one installed formula, and a
# brew stub first on PATH that answers from it. Nothing reaches the real brew.
# Usage: fake_brew_formula <name> <version> <command> [<utility>...]
# The command is the formula's own, printing "<command>:<version>" for
# --version; each utility is a symlink to it in the keg, as Utilz's are to its
# dispatcher. All of them are linked into the prefix's bin, as the formula's
# install_symlink does. Exports FAKE_PREFIX, FAKE_KEG (the keg's libexec) and
# FAKE_LOG, where the stub records every call that would change Homebrew. list
# answers only for this formula, by its name or tap/name. The stub has no trust
# gate until `touch "$FAKE_PREFIX/.gate"`; trust.json is its trust store and
# starts empty, and `touch "$FAKE_PREFIX/.store-unreadable"` makes reading it fail.
# taps lists the tapped taps, one per line, and starts empty; a bare tap prints
# it, and `touch "$FAKE_PREFIX/.tap-fails"` makes tapping fail as ssh does.
fake_brew_formula() {
    local name="$1" version="$2" cmd="$3" util
    shift 3
    export FAKE_NAME="$name"
    export FAKE_PREFIX="$BATS_TEST_TMPDIR/brew"
    export FAKE_LOG="$BATS_TEST_TMPDIR/calls.log"
    export FAKE_KEG="$FAKE_PREFIX/Cellar/$name/$version/libexec"
    mkdir -p "$BATS_TEST_TMPDIR/stub" "$FAKE_PREFIX/bin" "$FAKE_PREFIX/opt" "$FAKE_KEG/bin"
    ln -s "../Cellar/$name/$version" "$FAKE_PREFIX/opt/$name"
    printf '#!/bin/bash\n[[ "$1" == --version ]] && echo "%s:%s"\n' "$cmd" "$version" > "$FAKE_KEG/bin/$cmd"
    chmod +x "$FAKE_KEG/bin/$cmd"
    ln -s "../Cellar/$name/$version/libexec/bin/$cmd" "$FAKE_PREFIX/bin/$cmd"
    for util in "$@"; do
        ln -s "$cmd" "$FAKE_KEG/bin/$util"
        ln -s "../Cellar/$name/$version/libexec/bin/$util" "$FAKE_PREFIX/bin/$util"
    done
    touch "$FAKE_PREFIX/.installed"
    : > "$FAKE_PREFIX/taps"
    echo '{"taps":[],"formulae":[]}' > "$FAKE_PREFIX/trust.json"
    cat > "$BATS_TEST_TMPDIR/stub/brew" <<'EOF'
#!/bin/bash
case "$1" in
  --prefix) echo "$FAKE_PREFIX" ;;
  list)     [[ -e "$FAKE_PREFIX/.installed" ]] || exit 1
            case "$3" in "$FAKE_NAME" | */"$FAKE_NAME") ;; *) exit 1 ;; esac ;;
  install)  echo "brew $*" >> "$FAKE_LOG"; touch "$FAKE_PREFIX/.installed" ;;
  tap)      [[ $# -eq 1 ]] && { cat "$FAKE_PREFIX/taps"; exit 0; }
            echo "brew $*" >> "$FAKE_LOG"
            if [[ -e "$FAKE_PREFIX/.tap-fails" ]]; then
              echo "git@github.com: Permission denied (publickey)." >&2
              exit 1
            fi
            echo "$2" >> "$FAKE_PREFIX/taps" ;;
  upgrade | reinstall | uninstall | link | unlink | untap | pin | unpin)
            echo "brew $*" >> "$FAKE_LOG" ;;
  trust)
    case "$2" in
      --help)    [[ -e "$FAKE_PREFIX/.gate" ]] ;;
      --json=v1) [[ ! -e "$FAKE_PREFIX/.store-unreadable" ]] && cat "$FAKE_PREFIX/trust.json" ;;
      --formula) echo "brew $*" >> "$FAKE_LOG"
                 printf '{"taps":[],"formulae":["%s"]}\n' "$3" > "$FAKE_PREFIX/trust.json" ;;
      *)         exit 1 ;;
    esac ;;
  *)        exit 1 ;;
esac
EOF
    chmod +x "$BATS_TEST_TMPDIR/stub/brew"
    export PATH="$BATS_TEST_TMPDIR/stub:$FAKE_PREFIX/bin:$PATH"
}

# ============================================================================
# ASSERTION HELPERS
# ============================================================================

# Assert command succeeded (exit code 0)
assert_success() {
    # shellcheck disable=SC2154 # status and output are set by bats's run
    if [[ "$status" -ne 0 ]]; then
        fail "Expected success (exit 0) but got exit code: $status\nOutput: $output"
    fi
}

# Assert command failed (exit code non-zero)
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        fail "Expected failure (non-zero exit) but got exit code 0\nOutput: $output"
    fi
}

# Assert output contains a string
# Usage: assert_output_contains "expected text"
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        fail "Expected output to contain: '$expected'\nActual output:\n$output"
    fi
}

# Assert output does NOT contain a string
# Usage: refute_output_contains "unexpected text"
refute_output_contains() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        fail "Expected output NOT to contain: '$unexpected'\nActual output:\n$output"
    fi
}

# Assert file exists
# Usage: assert_file_exists "path/to/file"
assert_file_exists() {
    local filepath="$1"
    if [[ ! -f "$filepath" ]]; then
        fail "Expected file to exist: $filepath"
    fi
}

# Assert file does NOT exist
assert_file_not_exists() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        fail "Expected file NOT to exist: $filepath"
    fi
}

# Assert directory exists
assert_directory_exists() {
    local dirpath="$1"
    if [[ ! -d "$dirpath" ]]; then
        fail "Expected directory to exist: $dirpath"
    fi
}

# Assert symlink exists (optionally check target)
# Usage: assert_symlink_exists "path/to/link" ["target"]
assert_symlink_exists() {
    local link_path="$1"
    local expected_target="${2:-}"

    if [[ ! -L "$link_path" ]]; then
        fail "Expected symlink to exist: $link_path"
    fi

    if [[ -n "$expected_target" ]]; then
        local actual_target
        actual_target="$(readlink "$link_path")"
        if [[ "$actual_target" != "$expected_target" ]]; then
            fail "Expected symlink '$link_path' to point to '$expected_target' but points to '$actual_target'"
        fi
    fi
}

# Assert output matches regex
assert_output_matches() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        fail "Expected output to match pattern: '$pattern'\nActual output:\n$output"
    fi
}

# Explicit test failure with message
fail() {
    local message="$1"
    echo "FAILURE: $message" >&2
    return 1
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Skip test if command is not installed
# Usage: require_command "bats" "bats is required"
require_command() {
    local cmd="$1"
    local message="${2:-$cmd is required for this test}"
    if ! command -v "$cmd" &>/dev/null; then
        skip "$message"
    fi
}

# Print debug info (only when MOLT_TEST_DEBUG=1)
debug() {
    if [[ "${MOLT_TEST_DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}
