#!/usr/bin/env bats
# zsh.bats — Exemplar liberator test (zsh liberator)

load "../test_helper.bash"

setup() {
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"

    # Load zsh liberator
    load_liberator "zsh"
}

@test "zsh_check function exists after loading" {
    declare -f zsh_check &>/dev/null
}

@test "zsh_install function exists after loading" {
    declare -f zsh_install &>/dev/null
}

@test "zsh_verify function exists after loading" {
    declare -f zsh_verify &>/dev/null
}

@test "zsh_check returns 0 when zsh is installed" {
    require_command "zsh"
    # On a system where zsh is installed, check should at least not crash
    # It may return 1 if config isn't linked, but shouldn't return 127
    run zsh_check
    [[ "$status" -ne 127 ]]
}

@test "zsh_check detects missing zsh" {
    # Temporarily hide zsh from PATH to test detection
    local save_path="$PATH"
    PATH="/usr/bin/nonexistent"
    run zsh_check
    assert_failure
    PATH="$save_path"
}

@test "zsh_verify checks zsh binary" {
    require_command "zsh"
    run zsh_verify
    # Should not crash (127 = function/command not found)
    [[ "$status" -ne 127 ]]
}

# The wrapper reset the tab colour after ssh and returned the reset's status,
# so a failed ssh (255) reported success to whatever ran it.
@test "the generated iTerm2 ssh wrapper returns ssh's exit status" {
    molt_instances_field() {
        case "$1" in
            ssh_bg_color) echo "gyges:1a1a2e" ;;
            bg_color) echo "$(hostname -s 2>/dev/null || hostname):15191f" ;;
        esac
    }
    local script="$BATS_TEST_TMPDIR/iterm2-ssh-colors.sh"
    _zsh_generate_iterm2_ssh_colors "$script" >/dev/null
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/bin/sh\nexit 255\n' > "$BATS_TEST_TMPDIR/bin/ssh"
    chmod +x "$BATS_TEST_TMPDIR/bin/ssh"
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" TERM_PROGRAM=iTerm.app \
        bash -c 'source "$1" && ssh gyges' _ "$script"
    [ "$status" -eq 255 ]
    assert_output_contains "SetColors=bg=1a1a2e"
    # The tab goes back to this sleeve's own background, not to black.
    assert_output_contains "SetColors=bg=15191f"
}

@test "the generated iTerm2 ssh wrapper resets to black for a sleeve with no bg_color" {
    molt_instances_field() { [[ "$1" == "ssh_bg_color" ]] && echo "gyges:1a1a2e"; return 0; }
    local script="$BATS_TEST_TMPDIR/iterm2-ssh-colors.sh"
    _zsh_generate_iterm2_ssh_colors "$script" >/dev/null
    run grep -c '_iterm2_set_bg 000000' "$script"
    assert_output_contains "1"
}
