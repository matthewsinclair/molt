#!/usr/bin/env bats
# ssh.bats — Tests for the ssh liberator's install.
#
# ssh_install ignored molt_install_config's return, so a refused render went on
# to append the config.d fragments and re-stamp the sidecar from the inputs that
# had failed, and ssh_check then reported ok on every later run (issue 0019).

load "../test_helper.bash"

@test "ssh_install fails when its config render fails, and appends and stamps nothing" {
    load_liberator ssh
    local root="$BATS_TEST_TMPDIR"
    local host; host="$(hostname -s 2>/dev/null || hostname)"
    export HOME="$root/home"
    mkdir -p "$HOME/.ssh" "$root/repo/config/ssh" "$root/repo/instances/$host/ssh/config.d"
    # A key already exists, so ssh-keygen never runs.
    touch "$HOME/.ssh/id_ed25519"
    printf 'Host *\n  ServerAliveInterval 60\n' > "$root/repo/config/ssh/config.tmpl"
    printf 'Host gyges\n  HostName gyges.local\n' > "$root/repo/instances/$host/ssh/config.d/gyges.conf"
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    molt_render() { molt_error "render refused: $1"; return 1; }

    run ssh_install
    assert_failure
    refute_output_contains "Liberator complete"
    assert_file_not_exists "$HOME/.ssh/config"
    assert_file_not_exists "$HOME/.ssh/config.molt-rendered"
}
