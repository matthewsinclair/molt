#!/usr/bin/env bats
# pplr.bats — pplr liberator: pulling the Pplr checkout on upgrade

load "../test_helper.bash"

@test "pplr_upgrade reports Pplr updated, warns when it has no upstream, and fails, naming the repo and git's reason, when its pull fails" {
    load_liberator pplr
    export MOLT_PPLR_HOME="$BATS_TEST_TMPDIR/Pplr"
    clone_test_origin "$MOLT_PPLR_HOME" bin/pplr
    assert_upgrade_hook_pulls pplr_upgrade Pplr "$MOLT_PPLR_HOME"
}
