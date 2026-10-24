#!/usr/bin/env bats
# bootstrap.bats — bin/bootstrap.sh on a fresh machine (issues 0049, 0050)

load "test_helper.bash"

# A fresh machine: empty prj and cfg dirs, and a fake git whose clone records
# its target, exact-case, and leaves a molt that records each run's arguments.
# TTY stands in for the terminal and answers no.
_bootstrap_env() {
    export HOME="$BATS_TEST_TMPDIR/home"
    PRJ="$BATS_TEST_TMPDIR/prj"
    FAKES="$BATS_TEST_TMPDIR/fakes"
    CLONES="$BATS_TEST_TMPDIR/clones"
    RUNS="$BATS_TEST_TMPDIR/molt-runs"
    TTY="$BATS_TEST_TMPDIR/tty"
    mkdir -p "$HOME" "$FAKES"
    cat > "$FAKES/git" <<FAKE
#!/bin/sh
[ "\$1" = clone ] || exit 0
echo "\$3" >> "$CLONES"
mkdir -p "\$3/.git" "\$3/bin"
printf '#!/bin/sh\necho "\$*" >> "$RUNS"\n' > "\$3/bin/molt"
chmod +x "\$3/bin/molt"
FAKE
    printf '#!/bin/sh\nexit 1\n' > "$FAKES/timeout"
    printf '#!/bin/sh\nexit 0\n' > "$FAKES/curl"
    chmod +x "$FAKES/git" "$FAKES/timeout" "$FAKES/curl"
    echo n > "$TTY"
}

_bootstrap() {
    env PATH="$FAKES:/bin:/usr/bin" MOLT_PRJ_DIR="$PRJ" MOLT_BOOTSTRAP_TTY="$TTY" "$@"
}

@test "a fresh bootstrap clones the framework into exact-case Molt" {
    _bootstrap_env
    run _bootstrap bash "$MOLT_ROOT/bin/bootstrap.sh"
    assert_success
    grep -qx "$PRJ/Molt" "$CLONES"
    [ "$(readlink "$HOME/.local/bin/molt")" = "$PRJ/Molt/bin/molt" ]
}

@test "piped into bash, bootstrap asks the terminal, not the rest of its own source" {
    _bootstrap_env
    run _bootstrap bash < "$MOLT_ROOT/bin/bootstrap.sh"
    assert_success
    assert_output_contains "Skipped. Run 'molt resleeve' when ready."
    [ "$(cat "$RUNS")" = "resleeve --dry-run" ]
}

@test "with no terminal to ask, bootstrap fails by name and runs no resleeve" {
    _bootstrap_env
    TTY="$BATS_TEST_TMPDIR/no-tty"
    run _bootstrap bash "$MOLT_ROOT/bin/bootstrap.sh"
    assert_failure
    assert_output_contains "no terminal ($TTY) to ask whether to run molt resleeve"
    [ "$(cat "$RUNS")" = "resleeve --dry-run" ]
}
