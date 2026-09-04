#!/usr/bin/env bats
# editors.bats — editors liberator (straight.el build-tree hygiene)

load "../test_helper.bash"

_make_straight() {
    local root="$1" version="$2"
    mkdir -p "$root/build-${version}/cider"
    : > "$root/build-${version}/cider/cider-history.el"
    ln -s "$root/build-${version}/cider/cider-history.el" \
          "$root/build-${version}/cider/cider-good.el"
}

@test "_editors_warn_stale_straight_links is silent on a clean build tree" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight1"
    _make_straight "$root" "31.1"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "_editors_warn_stale_straight_links reports a dangling build link" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight2"
    _make_straight "$root" "31.1"
    # Exactly kovacs's failure: upstream renamed the file, straight did not prune.
    ln -s "$root/build-31.1/cider/cider-repl-history.el" \
          "$root/build-31.1/cider/cider-repl-history-link.el"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    assert_output_contains "cider-repl-history-link.el"
    assert_output_contains "did not prune"
}

@test "_editors_warn_stale_straight_links ignores orphaned build dirs for other versions" {
    load_liberator editors
    local root="$BATS_TEST_TMPDIR/straight3"
    _make_straight "$root" "31.1"
    mkdir -p "$root/build-31.0.91/cider"
    ln -s "$root/build-31.0.91/cider/gone.el" "$root/build-31.0.91/cider/stale.el"
    MOLT_STRAIGHT_DIR="$root" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ -z "$output" ]
}

@test "_editors_warn_stale_straight_links is silent when there is no straight dir" {
    load_liberator editors
    MOLT_STRAIGHT_DIR="$BATS_TEST_TMPDIR/nope" MOLT_EMACS_VERSION="31.1" \
        run _editors_warn_stale_straight_links
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
