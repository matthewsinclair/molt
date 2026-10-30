#!/usr/bin/env bats
# herdr.bats — Tests for the herdr liberator: keys.json linked as a file, the
# hrdrcfg directory linked whole, on macOS only (issue 0074).

load "../test_helper.bash"

_herdr_env() {
    load_liberator herdr
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    HERDR_REPO="$root/repo"
    mkdir -p "$HOME" "$HERDR_REPO/config/herdr-app" "$HERDR_REPO/config/hrdrcfg/spaces"
    printf '{"global": {}}\n' > "$HERDR_REPO/config/herdr-app/keys.json"
    printf 'roots: []\n' > "$HERDR_REPO/config/hrdrcfg/config.yaml"
    printf 'name: estate\n' > "$HERDR_REPO/config/hrdrcfg/spaces/estate.hrdrcfg"
    MOLT_USER_REPO_SEARCH_PATHS=("$HERDR_REPO")
    molt_platform() { echo "macos"; }
}

@test "herdr_check flags keys.json and hrdrcfg before install" {
    _herdr_env
    run herdr_check
    assert_failure
    assert_output_contains "herdr: ~/.config/herdr-app/keys.json is missing"
    assert_output_contains "herdr: ~/.config/hrdrcfg is missing"
}

@test "herdr_install links keys.json as a file and hrdrcfg as a directory, then check and verify pass" {
    require_command jq "reading keys.json needs jq"
    _herdr_env
    run herdr_install
    assert_success
    [ "$(readlink "$HOME/.config/herdr-app/keys.json")" = "$HERDR_REPO/config/herdr-app/keys.json" ]
    [ "$(readlink "$HOME/.config/hrdrcfg")" = "$HERDR_REPO/config/hrdrcfg" ]
    [ ! -L "$HOME/.config/herdr-app" ]
    run herdr_check
    assert_success
    run herdr_verify
    assert_success
}

@test "a space hrdrcfg writes after install lands in the repo" {
    _herdr_env
    herdr_install
    printf 'name: new\n' > "$HOME/.config/hrdrcfg/spaces/new.hrdrcfg"
    [ "$(cat "$HERDR_REPO/config/hrdrcfg/spaces/new.hrdrcfg")" = "name: new" ]
}

@test "herdr_install backs up a plain keys.json and leaves the app's other files alone" {
    _herdr_env
    mkdir -p "$HOME/.config/herdr-app"
    printf 'old\n' > "$HOME/.config/herdr-app/keys.json"
    printf 'state\n' > "$HOME/.config/herdr-app/settings.json"
    run herdr_install
    assert_success
    [ -L "$HOME/.config/herdr-app/keys.json" ]
    [ "$(cat "$HOME"/.config/herdr-app/keys.json.molt-backup.*)" = "old" ]
    [ "$(cat "$HOME/.config/herdr-app/settings.json")" = "state" ]
}

@test "herdr_check and herdr_verify fail when keys.json is not valid JSON, giving jq's reason" {
    require_command jq "parsing keys.json needs jq"
    _herdr_env
    herdr_install
    printf '{"global": \n' > "$HERDR_REPO/config/herdr-app/keys.json"
    run herdr_check
    assert_failure
    assert_output_contains "keys.json is not one JSON object (jq: "
    run herdr_verify
    assert_failure
    assert_output_contains "VERIFY FAIL"
}

# jq empty passed each of these; Herdr reads none of them.
@test "herdr_check fails on an empty keys.json, two objects and a top-level array" {
    require_command jq "parsing keys.json needs jq"
    _herdr_env
    herdr_install
    local body
    for body in '' '{} {}' '[]'; do
        printf '%s' "$body" > "$HERDR_REPO/config/herdr-app/keys.json"
        run herdr_check
        assert_failure
        assert_output_contains "keys.json is not one JSON object"
    done
}

# check failing sends resleeve to install, which once linked, said complete
# and returned 0, so resleeve said "Sleeve ready" over the fault.
@test "herdr_install fails over a keys.json Herdr cannot read, and never says it is complete" {
    require_command jq "parsing keys.json needs jq"
    _herdr_env
    printf '{"global": \n' > "$HERDR_REPO/config/herdr-app/keys.json"
    run herdr_install
    assert_failure
    assert_output_contains "herdr: $HERDR_REPO/config/herdr-app/keys.json is not one JSON object"
    assert_output_contains "fix it in the user repo, then run molt resleeve"
    refute_output_contains "Liberator complete"
}

# A sleeve with no jq: `command -v jq` answers nothing.
@test "herdr_check and herdr_install name a missing jq, and install says how to get it" {
    _herdr_env
    command() { if [[ "$1" == -v && "$2" == jq ]]; then return 1; fi; builtin command "$@"; }
    run herdr_check
    assert_failure
    assert_output_contains "herdr: jq is not installed, so $HERDR_REPO/config/herdr-app/keys.json cannot be read"
    run herdr_install
    assert_failure
    assert_output_contains "install jq (eg brew install jq), then run molt resleeve"
    refute_output_contains "Liberator complete"
}

@test "herdr links nothing for a repo without its config" {
    _herdr_env
    rm -r "$HERDR_REPO/config/herdr-app" "$HERDR_REPO/config/hrdrcfg"
    run herdr_check
    assert_success
    run herdr_install
    assert_success
    [ ! -e "$HOME/.config/hrdrcfg" ]
    [ ! -e "$HOME/.config/herdr-app" ]
}

@test "herdr does nothing on Linux" {
    _herdr_env
    molt_platform() { echo "linux"; }
    run herdr_check
    assert_success
    run herdr_install
    assert_success
    run herdr_verify
    assert_success
    [ ! -e "$HOME/.config/hrdrcfg" ]
    [ ! -e "$HOME/.config/herdr-app" ]
}
