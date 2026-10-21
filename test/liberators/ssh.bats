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
    molt_render_text() { echo "render refused: $1"; return 1; }

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
@test "ssh_install passes a user repo with no ssh config and no config.d fragments, as ssh_check does" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env
    rm "$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/gyges.conf"

    run ssh_install
    assert_success
    assert_output_contains "Liberator complete"
    refute_output_contains "Config not found"

    run ssh_check
    assert_success
}

# A fragment that could not be read was appended as its sentinel alone, so every
# later run took it as present (issue 0021).
@test "ssh_install fails on a config.d fragment it cannot read, and leaves ~/.ssh/config as it was" {
    [[ "$(id -u)" -ne 0 ]] || skip "root reads any file"
    _ssh_env
    printf 'Host *\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    printf 'Host *\n' > "$HOME/.ssh/config"
    cp "$HOME/.ssh/config" "$SSH_ROOT/config.before"
    chmod 000 "$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/gyges.conf"

    run ssh_install
    assert_failure
    assert_output_contains "gyges.conf cannot be read"
    refute_output_contains "Liberator complete"
    cmp "$SSH_ROOT/config.before" "$HOME/.ssh/config"
    [ -z "$(find "$HOME/.ssh" -name 'config.molt-*')" ]
}

# The chmod 600's status was dropped, so a config ssh refuses still ended on
# "Liberator complete" (issue 0021).
@test "ssh_install fails when ~/.ssh/config cannot be made mode 600" {
    _ssh_env
    printf 'Host *\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    mkdir -p "$SSH_ROOT/bin"
    # A chmod that refuses this one call and passes every other through.
    printf '#!/bin/sh\n[ "$1" = 600 ] && [ "$2" = "%s/.ssh/config" ] && exit 1\nexec /bin/chmod "$@"\n' "$HOME" > "$SSH_ROOT/bin/chmod"
    /bin/chmod +x "$SSH_ROOT/bin/chmod"
    export PATH="$SSH_ROOT/bin:$PATH"

    run ssh_install
    assert_failure
    assert_output_contains "could not be made mode 600"
    refute_output_contains "Liberator complete"
}

# Issue 0024: ssh_install rendered ~/.ssh/config and appended its config.d
# fragments after molt_render had compared the render with the file on disk,
# which held them, so every install backed the file up and warned it had been
# changed, and a hand edit read the same as molt's own fragments. The whole
# file is built before the compare now.
_ssh_backups() {
    find "$HOME/.ssh" -name 'config.molt-backup.*' | wc -l | tr -d ' '
}

@test "a second ssh_install with nothing changed backs nothing up and leaves the file as it was" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env
    printf 'Host *\n  ServerAliveInterval 60\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    printf 'Host kovacs\n  HostName kovacs.local\n' > "$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/kovacs.conf"
    ssh_install >/dev/null
    printf 'Host *\n  ServerAliveInterval 60\n\n# --- molt config.d: gyges.conf ---\nHost gyges\n  HostName gyges.local\n\n# --- molt config.d: kovacs.conf ---\nHost kovacs\n  HostName kovacs.local\n' > "$SSH_ROOT/expected"
    cmp "$SSH_ROOT/expected" "$HOME/.ssh/config"

    run ssh_install
    assert_success
    refute_output_contains "backing up"
    [ "$(_ssh_backups)" = 0 ]
    cmp "$SSH_ROOT/expected" "$HOME/.ssh/config"
    [ "$(test_file_mode "$HOME/.ssh/config")" = 600 ]
    [ "$(test_file_mode "$HOME/.ssh/config.molt-rendered")" = 600 ]
    run ssh_check
    assert_success
}

# molt_render_place backs a file up whenever it differs from what molt would
# write, so a changed input takes one backup, of the render before it; the
# install after that, with nothing changed, takes none.
@test "a changed template or fragment re-renders ~/.ssh/config once, with each fragment once" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env
    local frag="$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/gyges.conf"
    printf 'Host *\n  ServerAliveInterval 60\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    ssh_install >/dev/null

    printf 'Host *\n  ServerAliveInterval 30\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    run ssh_check
    assert_failure
    ssh_install >/dev/null
    [ "$(_ssh_backups)" = 1 ]
    grep -qx '  ServerAliveInterval 30' "$HOME/.ssh/config"

    printf 'Host gyges\n  HostName gyges.lan\n' > "$frag"
    run ssh_check
    assert_failure
    ssh_install >/dev/null
    [ "$(_ssh_backups)" = 2 ]
    grep -qx '  HostName gyges.lan' "$HOME/.ssh/config"
    [ "$(grep -c 'molt config.d: gyges.conf' "$HOME/.ssh/config")" = 1 ]
    run grep -q 'gyges.local' "$HOME/.ssh/config"
    assert_failure

    run ssh_install
    assert_success
    [ "$(_ssh_backups)" = 2 ]
    run ssh_check
    assert_success
}

@test "a hand edit below the config.d fragments is backed up once, with the warning" {
    _ssh_env
    printf 'Host *\n  ServerAliveInterval 60\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"
    ssh_install >/dev/null
    echo "Host by-hand" >> "$HOME/.ssh/config"

    run ssh_install
    assert_success
    assert_output_contains "Rendered file changed since last render, backing up: $HOME/.ssh/config -> $HOME/.ssh/config.molt-backup."
    [ "$(_ssh_backups)" = 1 ]
    grep -qx "Host by-hand" "$HOME"/.ssh/config.molt-backup.*
    run grep -q "Host by-hand" "$HOME/.ssh/config"
    assert_failure

    run ssh_install
    assert_success
    refute_output_contains "backing up"
    [ "$(_ssh_backups)" = 1 ]
}

# Issue 0027: a static config/ssh/config was linked, and check and verify
# refuse a linked ~/.ssh/config, which sshd will not read, so the sleeve never
# settled; fragments went through the link into the user repo. A static config
# is refused instead: as config.tmpl it renders as it stands.
STATIC_REFUSAL="ssh: config/ssh/config is static, and ssh refuses ~/.ssh/config as the link molt would make of it: rename it config/ssh/config.tmpl, which renders it as it stands"

_ssh_static_env() {
    _ssh_env
    printf 'Host *\n  ServerAliveInterval 60\n' > "$SSH_ROOT/repo/config/ssh/config"
    cp "$SSH_ROOT/repo/config/ssh/config" "$SSH_ROOT/static.before"
    printf 'Host mine\n' > "$HOME/.ssh/config"
    cp "$HOME/.ssh/config" "$SSH_ROOT/config.before"
}

_ssh_nothing_written() {
    cmp "$SSH_ROOT/static.before" "$SSH_ROOT/repo/config/ssh/config"
    [ ! -L "$HOME/.ssh/config" ]
    cmp "$SSH_ROOT/config.before" "$HOME/.ssh/config"
    [ -z "$(find "$HOME/.ssh" -name 'config.molt-*')" ]
}

@test "check, install and verify refuse a static config/ssh/config, and install writes nothing" {
    require_command ssh "ssh_check needs ssh"
    _ssh_static_env
    rm "$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/gyges.conf"

    run ssh_check
    assert_failure
    assert_output_contains "$STATIC_REFUSAL"
    run ssh_install
    assert_failure
    assert_output_contains "$STATIC_REFUSAL"
    refute_output_contains "Liberator complete"
    _ssh_nothing_written
    run ssh_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: $STATIC_REFUSAL"
}

@test "a static config/ssh/config with config.d fragments is refused, naming the fragments, and install writes nothing" {
    _ssh_static_env

    run ssh_install
    assert_failure
    assert_output_contains "$STATIC_REFUSAL; 1 config.d fragment(s) were not applied"
    refute_output_contains "Liberator complete"
    _ssh_nothing_written
}

@test "a static config/ssh/config renamed config.tmpl renders as it stands, and check then passes" {
    require_command ssh "ssh_check needs ssh"
    _ssh_static_env
    rm "$SSH_ROOT/repo/instances/$(test_hostname)/ssh/config.d/gyges.conf"
    mv "$SSH_ROOT/repo/config/ssh/config" "$SSH_ROOT/repo/config/ssh/config.tmpl"

    run ssh_install
    assert_success
    cmp "$SSH_ROOT/static.before" "$HOME/.ssh/config"
    run ssh_check
    assert_success
}

# Both files, as Molt-matts has: the template is the config, as before.
@test "a user repo with config/ssh/config.tmpl beside a static config/ssh/config renders the template" {
    _ssh_static_env
    printf 'Host *\n  ServerAliveInterval 30\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"

    run ssh_install
    assert_success
    refute_output_contains "is static"
    grep -qx '  ServerAliveInterval 30' "$HOME/.ssh/config"
}

# Fragments had been appended to a ~/.ssh/config of fragments alone when the
# repo had no ssh config; building the file from its template, they would be
# dropped without a word. Check and install both say so instead.
@test "ssh_check and ssh_install refuse config.d fragments when the user repo has no ssh config" {
    require_command ssh "ssh_check needs ssh"
    _ssh_env

    run ssh_check
    assert_failure
    assert_output_contains "ssh: config.d fragments need config/ssh/config.tmpl; the user repo has no ssh config, so 1 fragment(s) were not applied"
    run ssh_install
    assert_failure
    assert_output_contains "ssh: config.d fragments need config/ssh/config.tmpl; the user repo has no ssh config, so 1 fragment(s) were not applied"
    refute_output_contains "Liberator complete"
    [ ! -e "$HOME/.ssh/config" ]
}

@test "with no vars.sh, ssh_install warns as every render does" {
    _ssh_env
    printf 'Host *\n' > "$SSH_ROOT/repo/config/ssh/config.tmpl"

    run ssh_install
    assert_success
    assert_output_contains "No vars.sh for instance $(test_hostname)"
}
