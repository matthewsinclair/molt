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
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"
}

# Per-test teardown — runs after each test
teardown() {
    if [[ -n "$ORIGINAL_PWD" && -d "$ORIGINAL_PWD" ]]; then
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
}

# Load a specific liberator for function-level testing
# Usage: load_liberator zsh
load_liberator() {
    local name="$1"
    # Ensure core libs are loaded first
    if ! declare -f molt_info &>/dev/null; then
        load_molt_libs
    fi
    source "$MOLT_ROOT/liberators/${name}.sh"
}

# ============================================================================
# TEST DATA CREATION
# ============================================================================

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
# starts empty.
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
    echo '{"taps":[],"formulae":[]}' > "$FAKE_PREFIX/trust.json"
    cat > "$BATS_TEST_TMPDIR/stub/brew" <<'EOF'
#!/bin/bash
case "$1" in
  --prefix) echo "$FAKE_PREFIX" ;;
  list)     [[ -e "$FAKE_PREFIX/.installed" ]] || exit 1
            case "$3" in "$FAKE_NAME" | */"$FAKE_NAME") ;; *) exit 1 ;; esac ;;
  install)  echo "brew $*" >> "$FAKE_LOG"; touch "$FAKE_PREFIX/.installed" ;;
  upgrade | reinstall | uninstall | link | unlink | tap | untap | pin | unpin)
            echo "brew $*" >> "$FAKE_LOG" ;;
  trust)
    case "$2" in
      --help)    [[ -e "$FAKE_PREFIX/.gate" ]] ;;
      --json=v1) cat "$FAKE_PREFIX/trust.json" ;;
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
