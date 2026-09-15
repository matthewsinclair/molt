#!/usr/bin/env bats
# backup.bats — backup liberator (verdict honesty, run-history reading)
#
# The liberator reads SuperDuper's private state and a NAS it may not be able to
# reach. Every network-facing probe is stubbed per test; tiles.json, the
# scheduler log and the image's Info.plist are real files read by the real
# plutil, because the parsing is the part that has been wrong before.
#
# The verify arms fail on the pre-2026-09-15 liberator: it returned 0 and
# printed "Verified" away from home, where it had asserted nothing, and with the
# share unmounted, where it had skipped the attach budget.

load "../test_helper.bash"

# A user repo whose instance declares a backup, a share with an image on it, and
# SuperDuper state on disk. Nothing outside is stubbed yet -- each test says
# which part of the world it stands in for.
_backup_env() {
    require_command plutil "the backup liberator reads SuperDuper state with plutil (macOS)"
    load_liberator backup
    local root="$BATS_TEST_TMPDIR"
    local host; host="$(hostname -s 2>/dev/null || hostname)"
    mkdir -p "$root/repo/config" "$root/repo/instances/$host" "$root/share/img.sparsebundle"
    cat > "$root/repo/instances/$host/vars.sh" <<VARS
export MOLT_BACKUP_HOST="nas.test"
export MOLT_BACKUP_SHARE="bkp_test"
export MOLT_BACKUP_MOUNT="$root/share"
export MOLT_BACKUP_IMAGE="$root/share/img.sparsebundle"
export MOLT_BACKUP_WINDOW="03:00-05:00"
VARS
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    MOLT_SD_TILES="$root/tiles.json"
    MOLT_SD_SCHEDULER_LOG="$root/scheduler.log"
    : > "$MOLT_SD_SCHEDULER_LOG"
    # Stubbed by default, not left live: the machine running the suite may well
    # be mid-copy, and every history arm would then read differently.
    _backup_copying() { return 1; }
    # 10 bands of 1 GiB: a few seconds of a 600s budget, whatever the host disk.
    printf '{"band-size":1073741824,"size":10737418240}' > "$root/share/img.sparsebundle/Info.plist"
}

# _tile <binding> [OUTCOME:DAYS_AGO ...]
# binding: image (correct), share (fallen back, armed to delete), other (a job
# for some other share). Runs are oldest first, the order SuperDuper keeps them.
_tile() {
    local binding="$1"; shift
    local now; now="$(date +%s)"
    local runs="" r outcome days bytes
    for r in "$@"; do
        outcome="${r%%:*}" days="${r##*:}" bytes=""
        [[ "$outcome" == "SUCCEEDED" ]] && bytes='"bytesCopied":"42",'
        runs="${runs:+$runs,}{\"outcome\":\"OUTCOME_${outcome}\",${bytes}\"endedAtUnixNanos\":\"$(( (now - days * 86400) * 1000000000 ))\"}"
    done
    local dest
    case "$binding" in
        image) dest='{"diskImage":{"hostShareUrl":"smb://u@nas.test/bkp_test"}}' ;;
        share) dest='{"networkUrl":"smb://u@nas.test/bkp_test"}' ;;
        other) dest='{"diskImage":{"hostShareUrl":"smb://u@nas.test/bkp_elsewhere"}}' ;;
    esac
    # A plain assignment, not ${_TILE_SCHEDULE:-{...\}}: bash 3.2, the only bash
    # on GitHub's macOS runners, keeps the backslash before that closing brace,
    # so the fixture became invalid JSON and every tile read failed in CI.
    local schedule='{"scheduleOn":true,"minuteOfDay":180}'
    if [[ -n "${_TILE_SCHEDULE:-}" ]]; then
        schedule="$_TILE_SCHEDULE"
    fi
    local proto="{\"destination\":${dest},\"schedule\":${schedule},\"recentRuns\":[${runs}]}"
    printf '{"schemaVersion":5,"tiles":[{"proto":"%s"}]}' "${proto//\"/\\\"}" > "$MOLT_SD_TILES"
}

# The outside world, one switch each.
_away()             { _backup_home() { return 1; }; }
_at_home()          { _backup_home() { return 0; }; }
_share_unmounted()  { _backup_mounted() { return 1; }; }
_share_mounted()    { _backup_mounted() { return 0; }; _backup_dialect() { echo "SMB_3.1.1"; }; }
_copying()          { _backup_copying() { return 0; }; }

# Run a liberator function in a fresh bash under `set -euo pipefail`, the way
# bin/molt runs it, carrying this test's stubs. A command substitution that fails
# inside an assignment aborts there, and nothing inside bats' own `run` shows it.
_strict() {
    local script="$BATS_TEST_TMPDIR/strict.sh"
    {
        echo 'set -euo pipefail'
        echo "source \"$MOLT_LIB_DIR/constants.sh\""
        echo "source \"$MOLT_LIB_DIR/molt.sh\""
        echo "source \"$MOLT_LIB_DIR/liberator.sh\""
        echo "source \"$MOLT_ROOT/liberators/backup.sh\""
        echo "MOLT_USER_REPO_SEARCH_PATHS=(\"$BATS_TEST_TMPDIR/repo\")"
        echo "MOLT_SD_TILES=\"$MOLT_SD_TILES\""
        echo "MOLT_SD_SCHEDULER_LOG=\"$MOLT_SD_SCHEDULER_LOG\""
        declare -f _backup_home _backup_mounted _backup_dialect _backup_copying
        echo '"$@"'
    } > "$script"
    run bash "$script" "$@"
}

# ---------------------------------------------------------------------------
# verify -- a verdict must say what it actually checked
# ---------------------------------------------------------------------------

@test "backup_verify away from home does NOT report Verified or exit 0" {
    _backup_env; _tile image SUCCEEDED:0; _away
    run backup_verify
    [ "$status" -eq 2 ]
    assert_output_contains "VERIFY INCOMPLETE"
    assert_output_contains "nas.test not reachable"
    refute_output_contains "Verified:"
}

@test "backup_verify away from home still reads local SuperDuper state and fails on it" {
    _backup_env; _tile image SUCCEEDED:1 FAILED:0; _away
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "VERIFY FAIL: last copy did NOT succeed"
}

@test "backup_verify with the share unmounted does NOT report Verified or exit 0" {
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_unmounted
    run backup_verify
    [ "$status" -eq 2 ]
    assert_output_contains "not mounted"
    refute_output_contains "Verified:"
}

@test "backup_verify passes with exit 0 only when every check ran" {
    # The control arm: without it, every arm above passes on a verify that can
    # never pass at all.
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_mounted
    run backup_verify
    [ "$status" -eq 0 ]
    assert_output_contains "Verified:"
    refute_output_contains "INCOMPLETE"
    refute_output_contains "VERIFY FAIL"
}

@test "backup_verify FAILS on a share that is mounted but not answering" {
    # Previously folded into "not mounted; skipped" and then Verified.
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_mounted
    _backup_probe() { return 2; }
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "mounted but not answering"
}

@test "backup_verify FAILS when the mounted share holds no readable image" {
    # Previously the attach check was skipped in silence and the verdict passed.
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_mounted
    rm "$BATS_TEST_TMPDIR/share/img.sparsebundle/Info.plist"
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "attach budget is unknown"
    refute_output_contains "Verified:"
}

@test "backup_verify FAILS when a full image would blow the attach budget" {
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_mounted
    _backup_attach_projection() { _BACKUP_WORST_S=900 _BACKUP_WORST_BANDS=11000; return 0; }
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "needs ~900s to attach"
}

@test "backup_verify FAILS on a job that has fallen back to the share" {
    _backup_env; _tile share SUCCEEDED:0; _at_home; _share_mounted
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "no disk-image binding"
}

@test "backup_verify FAILS when no job has an image on the share" {
    _backup_env; _tile other SUCCEEDED:0; _away
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "no SuperDuper job has an image on the bkp_test share"
}

@test "backup_verify FAILS on a stale success" {
    _backup_env; _tile image SUCCEEDED:5; _away
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "last successful copy was 5 days ago"
}

@test "backup_verify reaches its verdict under set -euo pipefail when incomplete" {
    _backup_env; _tile image SUCCEEDED:0; _away
    _strict backup_verify
    [ "$status" -eq 2 ]
    assert_output_contains "Checked and passing"
}

@test "backup_verify reaches its verdict under set -euo pipefail when complete" {
    _backup_env; _tile image FAILED:2 SUCCEEDED:0; _at_home; _share_mounted
    _strict backup_verify
    [ "$status" -eq 0 ]
    assert_output_contains "Verified:"
}

# ---------------------------------------------------------------------------
# run history -- what the tile can and cannot tell us
# ---------------------------------------------------------------------------

@test "absent run history is reported as unknown, never as no backup" {
    _backup_env; _tile image; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "carries no run history"
    refute_output_contains "no backup exists"
    run backup_verify
    [ "$status" -eq 1 ]
    refute_output_contains "no backup exists"
}

@test "a failed latest run still reports the last successful copy" {
    _backup_env; _tile image SUCCEEDED:2 FAILED:1 CANCELLED:0 FAILED:0; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "last copy did NOT succeed (OUTCOME_FAILED)"
    assert_output_contains "last successful copy 2 day(s) ago"
}

@test "a run history with no success says so" {
    _backup_env; _tile image FAILED:1 FAILED:0; _away
    run backup_check
    assert_output_contains "none of the 2 runs SuperDuper keeps succeeded"
}

@test "the latest run is the LAST entry, not the first" {
    # Both orders present and distinguishable; the arm above is the mirror.
    _backup_env; _tile image FAILED:3 SUCCEEDED:0; _away
    run backup_verify
    [ "$status" -eq 2 ]
    refute_output_contains "VERIFY FAIL"
}

@test "check and verify give the same reading of a cancelled copy" {
    _backup_env; _tile image SUCCEEDED:1 CANCELLED:0; _away
    local sentence="last copy was cancelled 0 day(s) ago; last successful copy 1 day(s) ago"
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "$sentence"
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "$sentence"
}

@test "backup_check reaches its verdict under set -euo pipefail on a failed run with no bytes" {
    _backup_env; _tile image FAILED:0; _away
    _strict backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "none of the 1 runs SuperDuper keeps succeeded"
}

# ---------------------------------------------------------------------------
# a running copy -- invisible in recentRuns, so it must be looked for
# ---------------------------------------------------------------------------

@test "a copy running after interrupted runs is named and is not a fault" {
    # Exactly 15 Sep 2026: a good copy, the copy stopped for an OS install, a
    # couple of failed restarts, and a fresh copy now running.
    _backup_env; _tile image SUCCEEDED:0 CANCELLED:0 FAILED:0; _copying; _away
    run backup_check
    [ "$status" -eq 0 ]
    assert_output_contains "a SuperDuper copy is running now; last successful copy 0 day(s) ago"
    refute_output_contains "[error]"
    run backup_verify
    [ "$status" -eq 2 ]
    refute_output_contains "VERIFY FAIL"
}

@test "the same history with no copy running is still a failure" {
    # The mirror arm: without it, the one above passes on a liberator that
    # simply stopped reporting failed runs.
    _backup_env; _tile image SUCCEEDED:0 CANCELLED:0 FAILED:0; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "last copy did NOT succeed (OUTCOME_FAILED)"
    refute_output_contains "running now"
}

@test "a running copy does not excuse a stale backup" {
    _backup_env; _tile image SUCCEEDED:9 FAILED:0; _copying; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "last successful copy 9 day(s) ago; a SuperDuper copy is running now"
    run backup_verify
    [ "$status" -eq 1 ]
}

@test "a running copy does not excuse a history with no success" {
    _backup_env; _tile image FAILED:1 FAILED:0; _copying; _away
    run backup_verify
    [ "$status" -eq 1 ]
    assert_output_contains "none of the 2 runs SuperDuper keeps succeeded; a SuperDuper copy is running now"
}

@test "a new job's first copy running is named, and still no backup can be read" {
    _backup_env; _tile image; _copying; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "carries no run history"
    assert_output_contains "a SuperDuper copy is running now"
}

@test "a running copy is named when the latest run succeeded" {
    _backup_env; _tile image SUCCEEDED:0; _copying; _away
    run backup_check
    [ "$status" -eq 0 ]
    assert_output_contains "last copy succeeded 0 day(s) ago, 42 bytes; a SuperDuper copy is running now"
}

@test "backup_check reaches its verdict under set -euo pipefail with a copy running" {
    _backup_env; _tile image SUCCEEDED:1 CANCELLED:0; _copying; _away
    _strict backup_check
    [ "$status" -eq 0 ]
    assert_output_contains "a SuperDuper copy is running now"
}

@test "backup_maintain asks _backup_copying, not its own process probe" {
    # The copy-running probe has one home. With it stubbed false, maintain must
    # get past it to the next refusal -- on a mid-copy machine a private pgrep
    # would stop at the first one instead. Both refusals return before umount.
    _backup_env; _tile image SUCCEEDED:0; _at_home
    _backup_attached() { return 0; }
    run backup_maintain
    [ "$status" -eq 1 ]
    assert_output_contains "is open — refusing"
    refute_output_contains "copy is running"
}

# ---------------------------------------------------------------------------
# check -- local state is read wherever the laptop is
# ---------------------------------------------------------------------------

@test "backup_check away from home still reports a stale backup" {
    # Previously: "away from home, nothing to check", exit 0.
    _backup_env; _tile image SUCCEEDED:9; _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "last successful copy was 9 days ago"
    refute_output_contains "nothing to check"
}

@test "backup_check passes on a healthy job at home with the share unmounted" {
    _backup_env; _tile image SUCCEEDED:0; _at_home; _share_unmounted
    run backup_check
    [ "$status" -eq 0 ]
    assert_output_contains "last copy succeeded 0 day(s) ago, 42 bytes"
}

@test "backup_check flags a schedule block the scheduler ignores" {
    # Exactly the 7 Sep 2026 tiles: a time, no scheduleOn.
    _backup_env
    _TILE_SCHEDULE='{"weeks":[1,2,3,4,5],"minuteOfDay":1380}' _tile image SUCCEEDED:0
    _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "not actually scheduled"
}

@test "backup_check flags a schedule outside this sleeve's window" {
    _backup_env
    _TILE_SCHEDULE='{"scheduleOn":true,"minuteOfDay":1380}' _tile image SUCCEEDED:0
    _away
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "scheduled at 23:00"
    assert_output_contains "outside this sleeve's window 03:00-05:00"
}

@test "backup_check reports a locked SuperDuper daemon from its log" {
    _backup_env; _tile image SUCCEEDED:0; _away
    echo "scheduler: fire skipped, daemon is LOCKED" > "$MOLT_SD_SCHEDULER_LOG"
    run backup_check
    [ "$status" -ne 0 ]
    assert_output_contains "skipping scheduled copies"
}
