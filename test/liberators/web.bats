#!/usr/bin/env bats
# web.bats — web liberator: repo detection + platform-binary linking

load "../test_helper.bash"

# Sandbox HOME + MOLT_OPT_DIR and load the web liberator.
setup_web() {
    load_molt_libs
    source "$MOLT_ROOT/liberators/web.sh"

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/bin"
    export MOLT_LOCAL_BIN="$HOME/bin"
    export MOLT_OPT_DIR="$BATS_TEST_TMPDIR/opt"
    mkdir -p "$MOLT_OPT_DIR/web"
    echo "module web" > "$MOLT_OPT_DIR/web/go.mod"
}

# The prebuilt binary name for the machine running the test.
_expected_web_bin() {
    local os
    case "$(molt_platform)" in
        macos) os="darwin" ;;
        linux) os="linux" ;;
    esac
    echo "web-${os}-$(molt_arch)"
}

@test "web_check fails with 'repo not found' when the repo is absent" {
    setup_web
    rm -rf "$MOLT_OPT_DIR/web"
    run web_check
    assert_failure
    assert_output_contains "repo not found"
}

@test "web liberator detects repo by go.mod (no built binary required)" {
    setup_web
    run web_repo
    assert_success
    assert_output_contains "$MOLT_OPT_DIR/web"
}

@test "web_install links the platform-specific prebuilt binary" {
    setup_web
    local b; b="$(_expected_web_bin)"
    printf '#!/bin/sh\necho web\n' > "$MOLT_OPT_DIR/web/$b"
    chmod +x "$MOLT_OPT_DIR/web/$b"

    run web_install
    assert_success
    assert_symlink_exists "$MOLT_LOCAL_BIN/web"
    [ "$(readlink "$MOLT_LOCAL_BIN/web")" = "$MOLT_OPT_DIR/web/$b" ]
}

@test "web_install prefers a locally built ./web over the prebuilt" {
    setup_web
    local b; b="$(_expected_web_bin)"
    printf '#!/bin/sh\necho prebuilt\n' > "$MOLT_OPT_DIR/web/$b"; chmod +x "$MOLT_OPT_DIR/web/$b"
    printf '#!/bin/sh\necho built\n' > "$MOLT_OPT_DIR/web/web"; chmod +x "$MOLT_OPT_DIR/web/web"

    run web_install
    assert_success
    [ "$(readlink "$MOLT_LOCAL_BIN/web")" = "$MOLT_OPT_DIR/web/web" ]
}

@test "web_install fails with a build hint when no usable binary exists" {
    setup_web
    run web_install
    assert_failure
    assert_output_contains "no usable binary"
}
