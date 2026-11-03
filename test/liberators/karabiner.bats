#!/usr/bin/env bats
# karabiner.bats — Tests for the karabiner liberator: ~/.config/karabiner linked
# whole from the user repo, a real directory there adopted, and Karabiner's
# agent restarted once the link is made, on macOS only (issue 0081).
#
# HOME and the user repo are in the test directory, and launchctl is faked
# first on PATH. Nothing here reaches the real ~/.config or launchd.

load "../test_helper.bash"

# A user repo with config/karabiner, and Karabiner's agent loaded. Each test
# then changes one thing.
_kb_env() {
    load_liberator karabiner
    local root="$BATS_TEST_TMPDIR"
    export HOME="$root/home"
    unset XDG_CONFIG_HOME
    KB_REPO="$root/repo"
    mkdir -p "$HOME" "$KB_REPO/config/karabiner"
    printf '{"profiles": [{"name": "repo"}]}\n' > "$KB_REPO/config/karabiner/karabiner.json"
    MOLT_USER_REPO_SEARCH_PATHS=("$KB_REPO")
    molt_platform() { echo "macos"; }

    # launchctl logs each call's arguments as one line. print answers for a
    # service only while AGENT_LOADED exists, as launchd fails print for a
    # service it does not hold; kickstart exits KICKSTART_STATUS, 0 unless a
    # test sets it.
    export LAUNCHCTL_LOG="$root/launchctl.log" AGENT_LOADED="$root/agent-loaded"
    : > "$LAUNCHCTL_LOG"
    touch "$AGENT_LOADED"
    mkdir -p "$root/launchctl-stub"
    cat > "$root/launchctl-stub/launchctl" <<'EOF'
#!/bin/sh
echo "$*" >> "$LAUNCHCTL_LOG"
case "$1" in
  print)     [ -e "$AGENT_LOADED" ] || exit 113 ;;
  kickstart) exit "${KICKSTART_STATUS:-0}" ;;
  *)         exit 1 ;;
esac
EOF
    chmod +x "$root/launchctl-stub/launchctl"
    export PATH="$root/launchctl-stub:$PATH"
    KB_SERVICE="gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server"
}

# A real ~/.config/karabiner, as Karabiner makes it, with karabiner.json $1.
_kb_live_dir() {
    KB_LIVE="$HOME/.config/karabiner"
    mkdir -p "$KB_LIVE/assets/complex_modifications" "$KB_LIVE/automatic_backups"
    printf '%s\n' "$1" > "$KB_LIVE/karabiner.json"
    printf 'rule\n' > "$KB_LIVE/assets/complex_modifications/rule.json"
    printf 'backup\n' > "$KB_LIVE/automatic_backups/karabiner_20261103.json"
}

@test "karabiner_check flags ~/.config/karabiner before install" {
    _kb_env
    run karabiner_check
    assert_failure
    assert_output_contains "karabiner: ~/.config/karabiner is missing"
}

@test "karabiner_install links the directory, then check and verify pass" {
    _kb_env
    run karabiner_install
    assert_success
    [ "$(readlink "$HOME/.config/karabiner")" = "$KB_REPO/config/karabiner" ]
    run karabiner_check
    assert_success
    run karabiner_verify
    assert_success
}

# Karabiner saves by writing a new file and renaming it over the old one.
@test "a save that renames a new karabiner.json into place lands in the repo" {
    _kb_env
    karabiner_install
    printf '{"profiles": [{"name": "saved"}]}\n' > "$HOME/.config/karabiner/karabiner.json.tmp"
    mv "$HOME/.config/karabiner/karabiner.json.tmp" "$HOME/.config/karabiner/karabiner.json"
    grep -qF '"saved"' "$KB_REPO/config/karabiner/karabiner.json"
    [ -L "$HOME/.config/karabiner" ]
}

@test "karabiner_install adopts a real ~/.config/karabiner whose karabiner.json is the repo's" {
    _kb_env
    _kb_live_dir '{"profiles": [{"name": "repo"}]}'
    run karabiner_install
    assert_success
    [ "$(readlink "$KB_LIVE")" = "$KB_REPO/config/karabiner" ]
    [ "$(cat "$KB_REPO/config/karabiner/assets/complex_modifications/rule.json")" = "rule" ]
    [ "$(cat "$KB_REPO/config/karabiner/automatic_backups/karabiner_20261103.json")" = "backup" ]
    grep -qF '"repo"' "$HOME"/.config/karabiner.molt-backup.*/karabiner.json
}

@test "karabiner_install adopts a real ~/.config/karabiner with no karabiner.json" {
    _kb_env
    _kb_live_dir 'unused'
    rm "$KB_LIVE/karabiner.json"
    run karabiner_install
    assert_success
    [ "$(readlink "$KB_LIVE")" = "$KB_REPO/config/karabiner" ]
    [ "$(cat "$KB_REPO/config/karabiner/automatic_backups/karabiner_20261103.json")" = "backup" ]
}

@test "karabiner_install adopts the live karabiner.json into a repo directory without one" {
    _kb_env
    rm "$KB_REPO/config/karabiner/karabiner.json"
    _kb_live_dir '{"profiles": [{"name": "live"}]}'
    run karabiner_install
    assert_success
    refute_output_contains "differs"
    [ "$(readlink "$KB_LIVE")" = "$KB_REPO/config/karabiner" ]
    grep -qF '"live"' "$KB_REPO/config/karabiner/karabiner.json"
    [ "$(cat "$KB_REPO/config/karabiner/automatic_backups/karabiner_20261103.json")" = "backup" ]
}

@test "an entry the repo already has stays in the backup, not merged into the repo" {
    _kb_env
    _kb_live_dir '{"profiles": [{"name": "repo"}]}'
    mkdir -p "$KB_REPO/config/karabiner/assets"
    run karabiner_install
    assert_success
    [ ! -e "$KB_REPO/config/karabiner/assets/complex_modifications" ]
    [ "$(cat "$HOME"/.config/karabiner.molt-backup.*/assets/complex_modifications/rule.json)" = "rule" ]
    [ "$(cat "$KB_REPO/config/karabiner/automatic_backups/karabiner_20261103.json")" = "backup" ]
}

@test "karabiner_install refuses a real ~/.config/karabiner whose karabiner.json differs, moving nothing" {
    _kb_env
    _kb_live_dir '{"profiles": [{"name": "live"}]}'
    run karabiner_install
    assert_failure
    assert_output_contains "karabiner: ~/.config/karabiner/karabiner.json differs from $KB_REPO/config/karabiner/karabiner.json, so nothing was moved or linked"
    [ ! -L "$KB_LIVE" ]
    grep -qF '"live"' "$KB_LIVE/karabiner.json"
    [ "$(cat "$KB_LIVE/assets/complex_modifications/rule.json")" = "rule" ]
    [ "$(cat "$KB_LIVE/automatic_backups/karabiner_20261103.json")" = "backup" ]
    [ ! -e "$KB_REPO/config/karabiner/assets" ]
    [ ! -e "$KB_REPO/config/karabiner/automatic_backups" ]
    [ ! -s "$LAUNCHCTL_LOG" ]
}

@test "karabiner links nothing for a repo without its config" {
    _kb_env
    rm -r "$KB_REPO/config/karabiner"
    run karabiner_check
    assert_success
    run karabiner_install
    assert_success
    [ ! -e "$HOME/.config/karabiner" ]
    [ ! -s "$LAUNCHCTL_LOG" ]
}

@test "karabiner does nothing off macOS" {
    _kb_env
    molt_platform() { echo "linux"; }
    run karabiner_check
    assert_success
    run karabiner_install
    assert_success
    run karabiner_verify
    assert_success
    [ ! -e "$HOME/.config/karabiner" ]
    [ ! -s "$LAUNCHCTL_LOG" ]
}

@test "karabiner_install restarts Karabiner's agent when it makes the link, and not on a re-run" {
    _kb_env
    run karabiner_install
    assert_success
    [ "$(cat "$LAUNCHCTL_LOG")" = "$(printf 'print %s\nkickstart -k %s' "$KB_SERVICE" "$KB_SERVICE")" ]
    run karabiner_install
    assert_success
    [ "$(cat "$LAUNCHCTL_LOG")" = "$(printf 'print %s\nkickstart -k %s' "$KB_SERVICE" "$KB_SERVICE")" ]
}

@test "karabiner_install leaves an agent that is not loaded alone" {
    _kb_env
    rm "$AGENT_LOADED"
    run karabiner_install
    assert_success
    [ "$(readlink "$HOME/.config/karabiner")" = "$KB_REPO/config/karabiner" ]
    [ "$(cat "$LAUNCHCTL_LOG")" = "print $KB_SERVICE" ]
}

@test "a failed restart fails karabiner_install and names the command to run" {
    _kb_env
    export KICKSTART_STATUS=1
    run karabiner_install
    assert_failure
    assert_output_contains "run: launchctl kickstart -k $KB_SERVICE"
    [ "$(readlink "$HOME/.config/karabiner")" = "$KB_REPO/config/karabiner" ]
}

@test "karabiner links under an absolute XDG_CONFIG_HOME" {
    _kb_env
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
    run karabiner_install
    assert_success
    [ "$(readlink "$XDG_CONFIG_HOME/karabiner")" = "$KB_REPO/config/karabiner" ]
    [ ! -e "$HOME/.config/karabiner" ]
}
