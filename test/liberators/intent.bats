#!/usr/bin/env bats
# intent.bats — intent liberator (repo discovery, dispatcher choice, link honesty)
#
# Every arm here fails on the pre-2026-09-08 liberator. That is the point: the
# old code found the repo by probing for bin/intent, linked the v2 dispatcher,
# and let intent_verify pass on a link pointing somewhere it never installed.

load "../test_helper.bash"

# A repo is identified by BEING a repo. The binaries are independently present
# or absent, because the whole transition is about them moving.
_make_intent_repo() {
    local root="$1" want_v2="$2" want_v3="$3"
    mkdir -p "$root/intent/.config"
    echo '{"project_name":"Intent"}' > "$root/intent/.config/config.json"
    if [[ "$want_v2" == "v2" ]]; then
        mkdir -p "$root/bin"
        printf '#!/bin/bash\necho v2-dispatcher\n' > "$root/bin/intent"
        chmod +x "$root/bin/intent"
    fi
    if [[ "$want_v3" == "v3" ]]; then
        mkdir -p "$root/native/rust/target/release"
        printf '#!/bin/bash\necho v3-binary\n' > "$root/native/rust/target/release/intent"
        chmod +x "$root/native/rust/target/release/intent"
    fi
}

# ---------------------------------------------------------------------------
# Repo discovery -- find the repo by the repo, not by one of its binaries
# ---------------------------------------------------------------------------

@test "_intent_find_repo finds a repo that has NO binaries at all" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-burned"
    # Exactly the state after Intent's flip-then-burn: config present, v2 script
    # deleted, nothing built yet. The old probe returned 1 here and sent the user
    # off to clone a repo that was sitting right there.
    _make_intent_repo "$root" "no-v2" "no-v3"
    MOLT_INTENT_HOME="$root" run _intent_find_repo
    [ "$status" -eq 0 ]
    [ "$output" = "$root" ]
}

@test "_intent_find_repo finds a repo by .git when there is no intent config" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-git"
    mkdir -p "$root/.git"
    MOLT_INTENT_HOME="$root" run _intent_find_repo
    [ "$status" -eq 0 ]
}

@test "_intent_find_repo rejects a directory that is not a repo" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/not-a-repo"
    mkdir -p "$root/bin"
    : > "$root/bin/intent"
    MOLT_INTENT_HOME="$root" run _intent_find_repo
    [ "$status" -ne 0 ]
}

@test "_intent_find_repo rejects a missing directory" {
    load_liberator intent
    MOLT_INTENT_HOME="$BATS_TEST_TMPDIR/nowhere" run _intent_find_repo
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Dispatcher choice -- prefer the release binary, ALWAYS
# ---------------------------------------------------------------------------

@test "_intent_dispatcher prefers the release binary when BOTH are present" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-both"
    # The control arm that matters: both candidates present and distinguishable.
    # A fixture with only one candidate cannot see a preference-order bug.
    _make_intent_repo "$root" "v2" "v3"
    run _intent_dispatcher "$root"
    [ "$status" -eq 0 ]
    [ "$output" = "$root/native/rust/target/release/intent" ]
}

@test "_intent_dispatcher falls back to bin/intent only when nothing is built" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-v2only"
    _make_intent_repo "$root" "v2" "no-v3"
    run _intent_dispatcher "$root"
    [ "$status" -eq 0 ]
    [ "$output" = "$root/bin/intent" ]
}

@test "_intent_dispatcher fails when the repo carries neither" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-none"
    _make_intent_repo "$root" "no-v2" "no-v3"
    run _intent_dispatcher "$root"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# install -- the two failures need two different instructions
# ---------------------------------------------------------------------------

@test "intent_install links the release binary, not the v2 dispatcher" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-inst"
    local lbin="$BATS_TEST_TMPDIR/localbin"
    _make_intent_repo "$root" "v2" "v3"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_install
    [ "$status" -eq 0 ]
    [ -L "$lbin/intent" ]
    [ "$(readlink "$lbin/intent")" = "$root/native/rust/target/release/intent" ]
}

@test "intent_install says BUILD -- not CLONE -- when the repo is present but unbuilt" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-unbuilt"
    local lbin="$BATS_TEST_TMPDIR/localbin2"
    # The arm that would otherwise go unwritten. "Clone it" for a repo already on
    # disk is a confusing, wrong message at exactly the wrong moment.
    _make_intent_repo "$root" "no-v2" "no-v3"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_install
    [ "$status" -ne 0 ]
    assert_output_contains "Build it"
    refute_output_contains "Clone it"
}

@test "intent_install says CLONE when the repo genuinely is not there" {
    load_liberator intent
    local lbin="$BATS_TEST_TMPDIR/localbin3"
    MOLT_INTENT_HOME="$BATS_TEST_TMPDIR/absent" MOLT_LOCAL_BIN="$lbin" run intent_install
    [ "$status" -ne 0 ]
    assert_output_contains "Clone it"
    refute_output_contains "Build it"
}

# ---------------------------------------------------------------------------
# verify -- must not pass on the state check warns about
# ---------------------------------------------------------------------------

@test "intent_verify FAILS on a link resolving to something it never installed" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-mismatch"
    local lbin="$BATS_TEST_TMPDIR/localbin4"
    _make_intent_repo "$root" "v2" "v3"
    mkdir -p "$lbin"
    # Healthy link, wrong target -- resolves perfectly, to the v2 script. The old
    # verify asked only molt_link_healthy and called this "fully operational"
    # while intent_check was warning about the very same link.
    ln -s "$root/bin/intent" "$lbin/intent"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_verify
    [ "$status" -ne 0 ]
    assert_output_contains "VERIFY FAIL"
    refute_output_contains "fully operational"
}

@test "intent_verify passes when the link points at the release binary" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-match"
    local lbin="$BATS_TEST_TMPDIR/localbin5"
    _make_intent_repo "$root" "v2" "v3"
    mkdir -p "$lbin"
    ln -s "$root/native/rust/target/release/intent" "$lbin/intent"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_verify
    [ "$status" -eq 0 ]
    assert_output_contains "fully operational"
}

@test "intent_verify FAILS on a repo with nothing built" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-verify-unbuilt"
    local lbin="$BATS_TEST_TMPDIR/localbin6"
    _make_intent_repo "$root" "no-v2" "no-v3"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_verify
    [ "$status" -ne 0 ]
    assert_output_contains "no built dispatcher"
}

# ---------------------------------------------------------------------------
# check -- reports the mismatch, and declines to repair it
# ---------------------------------------------------------------------------

@test "intent_check reports a mismatched link without repairing it" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-check"
    local lbin="$BATS_TEST_TMPDIR/localbin7"
    _make_intent_repo "$root" "v2" "v3"
    mkdir -p "$lbin"
    ln -s "$root/bin/intent" "$lbin/intent"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_check
    assert_output_contains "may be deliberate"
    # Not repairing means exactly that: the link is untouched afterwards.
    [ "$(readlink "$lbin/intent")" = "$root/bin/intent" ]
}

@test "intent_check fails when the repo is present but nothing is built" {
    load_liberator intent
    local root="$BATS_TEST_TMPDIR/intent-check-unbuilt"
    local lbin="$BATS_TEST_TMPDIR/localbin8"
    _make_intent_repo "$root" "no-v2" "no-v3"
    MOLT_INTENT_HOME="$root" MOLT_LOCAL_BIN="$lbin" run intent_check
    [ "$status" -ne 0 ]
    assert_output_contains "no built dispatcher"
}
