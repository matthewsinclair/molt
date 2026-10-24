#!/usr/bin/env bats
# liberator-names.bats — every liberator a shipped molt.toml names exists (issue 0051)

load "test_helper.bash"

# The name of each [[liberator]] table in the toml $1, one per line.
_named_liberators() {
    awk '/^\[/ { lib = ($0 == "[[liberator]]") }
         lib && /^name = "/ { split($0, q, "\""); print q[2] }' "$1"
}

# Prints each liberator $1 names that has no liberators/<name>.sh.
_missing_liberators() {
    local name
    while IFS= read -r name; do
        [ -f "$MOLT_ROOT/liberators/$name.sh" ] || echo "$name"
    done < <(_named_liberators "$1")
}

@test "every liberator molt.toml.example names exists" {
    local toml="$MOLT_ROOT/templates/molt.toml.example"
    [ -n "$(_named_liberators "$toml")" ]
    run _missing_liberators "$toml"
    assert_success
    [ -z "$output" ]
}

@test "every liberator the molt-user skeleton names exists" {
    local toml="$MOLT_ROOT/templates/molt-user/instances/__MOLT_HOSTNAME__/molt.toml"
    [ -n "$(_named_liberators "$toml")" ]
    run _missing_liberators "$toml"
    assert_success
    [ -z "$output" ]
}
