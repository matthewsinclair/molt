#!/usr/bin/env bats
# bootstrap.bats — bin/bootstrap.sh on a fresh machine (issue 0049)

load "test_helper.bash"

# A fresh machine: empty prj and cfg dirs, and a fake git whose clone records
# its target, exact-case, and leaves a molt that the dry run can call.
_bootstrap_env() {
    export HOME="$BATS_TEST_TMPDIR/home"
    PRJ="$BATS_TEST_TMPDIR/prj"
    FAKES="$BATS_TEST_TMPDIR/fakes"
    CLONES="$BATS_TEST_TMPDIR/clones"
    mkdir -p "$HOME" "$FAKES"
    cat > "$FAKES/git" <<FAKE
#!/bin/sh
[ "\$1" = clone ] || exit 0
echo "\$3" >> "$CLONES"
mkdir -p "\$3/.git" "\$3/bin"
printf '#!/bin/sh\nexit 0\n' > "\$3/bin/molt"
chmod +x "\$3/bin/molt"
FAKE
    printf '#!/bin/sh\nexit 1\n' > "$FAKES/timeout"
    printf '#!/bin/sh\nexit 0\n' > "$FAKES/curl"
    chmod +x "$FAKES/git" "$FAKES/timeout" "$FAKES/curl"
}

@test "a fresh bootstrap clones the framework into exact-case Molt" {
    _bootstrap_env
    echo n > "$BATS_TEST_TMPDIR/answer"
    run env PATH="$FAKES:/bin:/usr/bin" MOLT_PRJ_DIR="$PRJ" bash "$MOLT_ROOT/bin/bootstrap.sh" < "$BATS_TEST_TMPDIR/answer"
    assert_success
    grep -qx "$PRJ/Molt" "$CLONES"
    [ "$(readlink "$HOME/.local/bin/molt")" = "$PRJ/Molt/bin/molt" ]
}
