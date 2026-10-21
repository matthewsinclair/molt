#!/usr/bin/env bats
# ssh.bats — Tests for the ssh liberator's install.
#
# ssh_install ignored molt_install_config's return, so a refused render went on
# to append the config.d fragments and re-stamp the sidecar from the inputs that
# had failed, and ssh_check then reported ok on every later run (issue 0019).

load "../test_helper.bash"

_ssh_env() {
    load_liberator ssh
    local root="$BATS_TEST_TMPDIR"
    local host; host="$(test_hostname)"
    export HOME="$root/home"
    mkdir -p "$HOME/.ssh" "$root/repo/config/ssh" "$root/repo/instances/$host/ssh/config.d"
    # A key already exists, so ssh-keygen never runs.
    touch "$HOME/.ssh/id_ed25519"
    printf 'Host gyges\n  HostName gyges.local\n' > "$root/repo/instances/$host/ssh/config.d/gyges.conf"
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    SSH_ROOT="$root"
}

# An earlier render whose inputs have changed since. A refused render must
# leave the config and its sidecar as they were, so ssh_check goes on calling
# the render stale; the old install appended to the one and re-stamped the
# other, and the check then passed.
@test "ssh_install fails when its config render fails, and leaves the config and its sidecar as they were" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env
    printf 'Host *\n  ServerAliveInterval 60\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    printf 'Host *\n' > "$HOME/.ssh/config"
    printf 'rendered earlier\ndigest stale\n' > "$HOME/.ssh/config.molt-rendered"
    cp "$HOME/.ssh/config" "$SSH_ROOT/config.before"
    cp "$HOME/.ssh/config.molt-rendered" "$SSH_ROOT/sidecar.before"
    molt_render() { molt_error "render refused: $1"; return 1; }

    run ssh_install
    assert_failure
    assert_output_contains "render refused"
    refute_output_contains "Liberator complete"
    cmp "$SSH_ROOT/config.before" "$HOME/.ssh/config"
    cmp "$SSH_ROOT/sidecar.before" "$HOME/.ssh/config.molt-rendered"

    run ssh_check
    assert_failure
    assert_output_contains "re-rendering"
}

# A repo with no ssh config is allowed, and ssh_check passes it, so the install
# passes it too rather than failing on molt_install_config's "Config not found".
@test "ssh_install passes a user repo with no ssh config, as ssh_check does" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env

    run ssh_install
    assert_success
    assert_output_contains "Liberator complete"
    refute_output_contains "Config not found"

    run ssh_check
    assert_success
}
