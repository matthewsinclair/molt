#!/usr/bin/env bats
# claude.bats — claude liberator (keybindings, rules, ccstatusline layout,
# statusLine, attribution; and, on a sleeve that declares
# MOLT_CLAUDE_CONFIG_DIR, the config dir, the one-time move, its publication
# and the home guard: ST0006)

load "../test_helper.bash"

STATUSLINE='{"type":"command","command":"npx -y ccstatusline@latest","padding":0}'
ATTRIBUTION='{"commit":"(C) someone@example.com","pr":"(C) someone@example.com","sessionUrl":false}'

setup_claude() {
    load_liberator claude
    load_liberator env

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"
    # The agents root the home guard is rendered with, in the test directory
    # rather than the one constants.sh derived from this machine's MOLT_PRJ_DIR.
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    # The env liberator publishes what claude gives it, with the PATH of a
    # login shell faked here, never this machine's.
    export MOLT_LOCAL_BIN="$HOME/.local/bin"
    export MOLT_LOGIN_SHELL="$BATS_TEST_TMPDIR/login-shell"
    printf '#!/bin/sh\necho "molt-path:%s:/usr/bin:/bin"\n' "$MOLT_LOCAL_BIN" > "$MOLT_LOGIN_SHELL"
    chmod +x "$MOLT_LOGIN_SHELL"

    export TEST_USER_REPO="$BATS_TEST_TMPDIR/molt-testuser"
    mkdir -p "$TEST_USER_REPO/config/claude" "$TEST_USER_REPO/config/ccstatusline"
    eval "molt_find_user_repo() { echo \"$TEST_USER_REPO\"; }"

    echo '{"bindings": []}' > "$TEST_USER_REPO/config/claude/keybindings.json"
    echo '{"version": 3}' > "$TEST_USER_REPO/config/ccstatusline/settings.json"
    echo "$STATUSLINE" > "$TEST_USER_REPO/config/claude/statusline.json"

    # pgrep and ps answer from a process table in the test directory, which
    # fake_processes fills, never from this machine's, where a Claude Code may
    # well be running.
    install_fake_process_table
}

# Declares $1 as this sleeve's config dir in its vars.sh, as hv does sleeve by
# sleeve (ST0006 WP04).
declare_config_dir() {
    local vars="$TEST_USER_REPO/instances/$(test_hostname)"
    mkdir -p "$vars"
    printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$1" > "$vars/vars.sh"
}

# A sleeve that declares ~/.config/claude, with Claude Code's state still in
# $HOME: a transcript under ~/.claude, and the account in ~/.claude.json.
setup_declared() {
    setup_claude
    export CONFIG="$HOME/.config/claude"
    declare_config_dir "$CONFIG"
    mkdir -p "$HOME/.claude/projects"
    echo "transcript" > "$HOME/.claude/projects/session.jsonl"
    echo '{"userID": "u"}' > "$HOME/.claude.json"
}

# The same sleeve once its state has moved: nothing of Claude Code's in $HOME.
setup_moved() {
    setup_declared
    mkdir -p "$CONFIG"
    mv "$HOME/.claude/projects" "$CONFIG/"
    mv "$HOME/.claude.json" "$CONFIG/.claude.json"
    rm -rf "$HOME/.claude"
}

# The GUI file this platform publishes.
gui_file() {
    case "$(molt_platform)" in
        macos) echo "$HOME/Library/LaunchAgents/com.molt.env.plist" ;;
        *)     echo "$HOME/.config/environment.d/molt.conf" ;;
    esac
}

@test "claude_install links the layout and keybindings and writes the statusLine; check and verify pass" {
    setup_claude
    run claude_install
    assert_success
    assert_symlink_exists "$HOME/.config/ccstatusline/settings.json" "$TEST_USER_REPO/config/ccstatusline/settings.json"
    assert_symlink_exists "$HOME/.claude/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ "$(jq -cS . "$HOME/.claude/settings.json")" = "$(jq -cS '{statusLine: .}' <<<"$STATUSLINE")" ]
    run claude_check
    assert_success
    run claude_verify
    assert_success
}

# rhadamanth, 15 Oct: another tool replaced the statusLine, and molt could not put it back.
@test "claude_install puts back a replaced statusLine and leaves every other key alone" {
    setup_claude
    cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls:*)"] },
  "hooks": { "Stop": [] },
  "enabledPlugins": { "a@b": true },
  "statusLine": { "type": "command", "command": "~/.claude/starship-statusline.sh" }
}
JSON
    local others
    others="$(jq -S 'del(.statusLine)' "$HOME/.claude/settings.json")"
    run claude_install
    assert_success
    [ "$(jq -S 'del(.statusLine)' "$HOME/.claude/settings.json")" = "$others" ]
    [ "$(jq -cS .statusLine "$HOME/.claude/settings.json")" = "$(jq -cS . <<<"$STATUSLINE")" ]
    # The replaced file is kept, so the old statusLine can be recovered.
    run jq -r .statusLine.command "$HOME"/.claude/settings.json.molt-backup.*
    assert_output_contains "starship-statusline.sh"
}

@test "claude_check and claude_verify flag a statusLine that differs" {
    setup_claude
    claude_install >/dev/null
    echo '{"statusLine": {"type": "command", "command": "starship"}}' > "$HOME/.claude/settings.json"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude/settings.json has a different statusLine"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.claude/settings.json has a different statusLine"
}

# Issue 0040: attribution was hand-set per sleeve, and a sleeve without it
# writes AI attribution into history.
@test "claude_check and claude_verify name an attribution the settings do not carry" {
    setup_claude
    echo "$ATTRIBUTION" > "$TEST_USER_REPO/config/claude/attribution.json"
    echo "{\"statusLine\": $STATUSLINE}" > "$HOME/.claude/settings.json"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude/settings.json has no attribution"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.claude/settings.json has no attribution"
}

@test "claude_install writes the attribution and leaves every other key alone; check passes" {
    setup_claude
    echo "$ATTRIBUTION" > "$TEST_USER_REPO/config/claude/attribution.json"
    cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls:*)"] },
  "hooks": { "Stop": [] },
  "includeCoAuthoredBy": false
}
JSON
    local others
    others="$(jq -S 'del(.statusLine, .attribution)' "$HOME/.claude/settings.json")"
    run claude_install
    assert_success
    [ "$(jq -S 'del(.statusLine, .attribution)' "$HOME/.claude/settings.json")" = "$others" ]
    [ "$(jq -cS .attribution "$HOME/.claude/settings.json")" = "$(jq -cS . <<<"$ATTRIBUTION")" ]
    run claude_check
    assert_success
}

@test "claude_check and claude_verify flag an attribution that differs" {
    setup_claude
    echo "$ATTRIBUTION" > "$TEST_USER_REPO/config/claude/attribution.json"
    claude_install >/dev/null
    jq '.attribution.sessionUrl = true' "$HOME/.claude/settings.json" > "$BATS_TEST_TMPDIR/s.json"
    mv "$BATS_TEST_TMPDIR/s.json" "$HOME/.claude/settings.json"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude/settings.json has a different attribution"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.claude/settings.json has a different attribution"
}

@test "claude_check and claude_verify flag a broken ccstatusline link" {
    setup_claude
    claude_install >/dev/null
    ln -sfn "$BATS_TEST_TMPDIR/moved/settings.json" "$HOME/.config/ccstatusline/settings.json"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/ccstatusline/settings.json is a broken symlink"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.config/ccstatusline/settings.json is a broken symlink"
}

# kovacs linked the layout by hand before the liberator managed it.
@test "claude adopts a hand-made link to the user repo's layout as it stands" {
    setup_claude
    mkdir -p "$HOME/.config/ccstatusline"
    ln -s "$TEST_USER_REPO/config/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
    run claude_check
    assert_failure
    assert_output_contains "keybindings.json is missing"
    refute_output_contains "ccstatusline"
    run claude_install
    assert_success
    refute_output_contains "ccstatusline"
    assert_symlink_exists "$HOME/.config/ccstatusline/settings.json" "$TEST_USER_REPO/config/ccstatusline/settings.json"
}

@test "a statusLine with its keys in another order matches, and install leaves the file alone" {
    setup_claude
    claude_install >/dev/null
    local settings='{"statusLine":{"padding":0,"command":"npx -y ccstatusline@latest","type":"command"},"model":"opus"}'
    printf '%s' "$settings" > "$HOME/.claude/settings.json"
    run claude_check
    assert_success
    run claude_install
    assert_success
    refute_output_contains "statusLine written"
    [ "$(cat "$HOME/.claude/settings.json")" = "$settings" ]
}

@test "claude_install fails, and leaves settings.json as it was, when settings.json is not JSON" {
    setup_claude
    printf '{"permissions": ' > "$HOME/.claude/settings.json"
    run claude_install
    assert_failure
    assert_output_contains "claude: ~/.claude/settings.json is not a JSON object"
    [ "$(cat "$HOME/.claude/settings.json")" = '{"permissions": ' ]
}

# A jq built without Oniguruma fails test(), which read as a malformed file
# (issue 0045).
@test "a jq with no regex support is named as that, not as a settings.json that is not a JSON object" {
    setup_claude
    printf '{"model": "opus"}' > "$HOME/.claude/settings.json"
    run _claude_home_paths "$HOME/.claude/settings.json" "$HOME/.claude"
    assert_success
    _claude_jq_regex() { return 1; }
    run _claude_home_paths "$HOME/.claude/settings.json" "$HOME/.claude"
    assert_failure
    assert_output_contains "cannot be checked: jq has no regex support"
    refute_output_contains "not a JSON object"
    printf '["opus"]' > "$HOME/.claude/settings.json"
    unset -f _claude_jq_regex
    load_liberator claude
    run _claude_home_paths "$HOME/.claude/settings.json" "$HOME/.claude"
    assert_failure
    assert_output_contains "is not a JSON object"
}

# Writing would replace the link with a copy, and edits to the linked file would
# silently stop reaching this sleeve.
@test "claude_install refuses to write a settings.json that is a symlink" {
    setup_claude
    mkdir -p "$BATS_TEST_TMPDIR/dotfiles"
    echo '{"model": "opus"}' > "$BATS_TEST_TMPDIR/dotfiles/settings.json"
    ln -s "$BATS_TEST_TMPDIR/dotfiles/settings.json" "$HOME/.claude/settings.json"
    run claude_install
    assert_failure
    assert_output_contains "settings.json is a symlink to $BATS_TEST_TMPDIR/dotfiles/settings.json"
    [ -L "$HOME/.claude/settings.json" ]
    [ "$(cat "$BATS_TEST_TMPDIR/dotfiles/settings.json")" = '{"model": "opus"}' ]
}

@test "claude_verify fails rather than passing when the user repo cannot be found" {
    setup_claude
    eval "molt_find_user_repo() { return 1; }"
    run claude_verify
    assert_failure
    assert_output_contains "no Claude Code config was checked"
}

# --- ST0006: the config dir ---

@test "with CLAUDE_CONFIG_DIR set, claude_install, check and verify use only it, and write nothing into ~/.claude" {
    # AT001 (ST0006 AC001).
    setup_claude
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/xdg/claude"
    run claude_install
    assert_success
    assert_symlink_exists "$CLAUDE_CONFIG_DIR/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ "$(jq -cS .statusLine "$CLAUDE_CONFIG_DIR/settings.json")" = "$(jq -cS . <<<"$STATUSLINE")" ]
    run claude_check
    assert_success
    run claude_verify
    assert_success
    # setup made ~/.claude, empty; it still is.
    [ -z "$(ls -A "$HOME/.claude")" ]
}

# The mkdir -p "$HOME/.claude" this replaced would have recreated exactly
# what doctor faults.
@test "with CLAUDE_CONFIG_DIR set and no ~/.claude, claude_install creates none" {
    # AT002 (ST0006 AC001).
    setup_claude
    rm -rf "$HOME/.claude"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/xdg/claude"
    run claude_install
    assert_success
    [ -d "$CLAUDE_CONFIG_DIR" ]
    [ ! -e "$HOME/.claude" ]
}

# molt can run in a shell that has not sourced env.sh yet.
@test "on a sleeve whose state has moved, claude_install writes only the config dir though this shell lacks CLAUDE_CONFIG_DIR" {
    # AT003 (ST0006 AC001).
    setup_moved
    run claude_install
    assert_success
    assert_output_contains "CLAUDE_CONFIG_DIR is not ~/.config/claude in this shell"
    [ ! -e "$HOME/.claude" ]
    [ ! -e "$HOME/.claude.json" ]
    assert_symlink_exists "$CONFIG/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ "$(jq -cS .statusLine "$CONFIG/settings.json")" = "$(jq -cS . <<<"$STATUSLINE")" ]
}

@test "the move refuses while Claude Code runs, names each process, cut to 100 characters, and moves and publishes nothing" {
    # AT004 (ST0006 AC002, AC011).
    setup_declared
    local long="4244 claude --append-system-prompt $(printf 'x%.0s' {1..80})yz"
    fake_processes "4242 claude --name kovacs-sysadm" "4243 /Users/x/.local/bin/claude --chrome-native-host" "77 -zsh" "$long"
    run claude_install
    assert_failure
    assert_output_contains "Claude Code is running"
    assert_output_contains "4242 claude --name kovacs-sysadm"
    assert_output_contains "4243 /Users/x/.local/bin/claude --chrome-native-host"
    assert_output_contains "${long:0:100}"
    refute_output_contains "${long:0:101}"
    refute_output_contains "77 -zsh"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ "$(jq -r .userID "$HOME/.claude.json")" = "u" ]
    # Not the config dir, not its copies, not env.sh: nothing under ~/.config.
    [ ! -e "$HOME/.config" ]
    [ ! -e "$(gui_file)" ]
}

@test "the move takes ~/.claude and ~/.claude.json into the config dir, copies both beside it first, then publishes it" {
    # AT005 (ST0006 AC002, AC011).
    setup_declared
    run claude_install
    assert_success
    [ ! -e "$HOME/.claude" ]
    [ ! -e "$HOME/.claude.json" ]
    [ "$(cat "$CONFIG/projects/session.jsonl")" = "transcript" ]
    [ "$(jq -r .userID "$CONFIG/.claude.json")" = "u" ]
    local backup
    backup="$(ls -d "$CONFIG".molt-backup.*)"
    [ "$(cat "$backup/.claude/projects/session.jsonl")" = "transcript" ]
    [ "$(jq -r .userID "$backup/.claude.json")" = "u" ]
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    grep -qF "$CONFIG" "$(gui_file)"
    # What the run wrote after the move went to the config dir.
    assert_symlink_exists "$CONFIG/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ ! -e "$HOME/.claude" ]
}

# kovacs-sysadm's review: a command that merely names the package is not
# Claude Code, and procps prints only a name for pgrep -l.
@test "a native or node-run Claude Code counts as running; a grep, npm ls, ls or molt run naming it does not" {
    # AT006 (ST0006 AC002).
    setup_claude
    fake_processes "9 grep -r @anthropic-ai/claude-code ." \
        "10 node /usr/lib/node_modules/npm/bin/npm-cli.js ls @anthropic-ai/claude-code" \
        "11 /Applications/ClaudeUsage.app/Contents/MacOS/ClaudeUsage" \
        "12 bash /Users/x/Devel/prj/Molt/bin/molt upgrade claude" \
        "13 vim /tmp/claude.md" \
        "17 vim /Users/x/.config/claude" \
        "18 ls -la /Users/x/.config/claude" \
        "19 ssh host /usr/local/bin/claude"
    run _claude_processes
    assert_success
    [ -z "$output" ]
    fake_processes "12 bash /Users/x/Devel/prj/Molt/bin/molt upgrade claude" \
        "14 node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js --resume" \
        "15 /Users/x/Library/Application Support/Claude/claude-code/2.1.0/claude --print" \
        "16 claude" \
        "20 node /usr/local/bin/claude --continue"
    run _claude_processes
    assert_success
    [ "$output" = "$(printf '%s\n' \
        "14 node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js --resume" \
        "15 /Users/x/Library/Application Support/Claude/claude-code/2.1.0/claude --print" \
        "16 claude" \
        "20 node /usr/local/bin/claude --continue")" ]
}

# Found live on rhadamanth, 21 Oct: run without -a, macOS's pgrep did not
# list the Claude Code session it was run from.
@test "on macOS the process check counts molt's own ancestors, which pgrep leaves out unless asked; procps is not asked" {
    # AT023 (ST0006 AC002).
    setup_claude
    eval 'molt_platform() { echo macos; }'
    run _claude_processes
    assert_success
    grep -q -- '^-a -u ' "$FAKE_PROCS.args"
    rm "$FAKE_PROCS.args"
    eval 'molt_platform() { echo linux; }'
    run _claude_processes
    assert_success
    grep -q -- '^-u ' "$FAKE_PROCS.args"
}

# critic-shell, 21 Oct: a failure after the copies were taken must not also say
# that nothing was changed.
@test "a move that fails after its copies are taken names them, and does not say nothing was changed" {
    # AT024 (ST0006 AC002, AC011).
    setup_declared
    printf '#!/bin/bash\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/cp"
    chmod +x "$BATS_TEST_TMPDIR/bin/cp"
    run claude_install
    assert_failure
    assert_output_contains "could not copy ~/.claude into ~/.config/claude.molt-backup."
    assert_output_contains "so nothing was moved; the copies are in"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published: no env.sh or GUI file was written"
    refute_output_contains "nothing else was changed"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$CONFIG" ]
}

@test "a config dir that already holds anything is refused, named with its contents, and nothing is merged or published" {
    # AT007 (ST0006 AC011).
    setup_declared
    mkdir -p "$CONFIG/plugins"
    echo '{}' > "$CONFIG/settings.json"
    run claude_install
    assert_failure
    assert_output_contains "~/.config/claude already holds plugins, settings.json"
    assert_output_contains "molt never merges the two"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ "$(jq -r .userID "$HOME/.claude.json")" = "u" ]
    [ "$(ls -A "$CONFIG" | tr '\n' ' ')" = "plugins settings.json " ]
    [ "$(cat "$CONFIG/settings.json")" = '{}' ]
    [ ! -e "$HOME/.config/molt" ]
    [ ! -e "$(gui_file)" ]
}

@test "an empty config dir counts as absent, and the move goes ahead" {
    # AT008 (ST0006 AC011).
    setup_declared
    mkdir -p "$CONFIG"
    run claude_install
    assert_success
    [ "$(cat "$CONFIG/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$HOME/.claude" ]
}

@test "a ~/.claude that is a symlink is not moved, and nothing is published" {
    # AT009 (ST0006 AC011).
    setup_declared
    mv "$HOME/.claude" "$BATS_TEST_TMPDIR/elsewhere"
    ln -s "$BATS_TEST_TMPDIR/elsewhere" "$HOME/.claude"
    run claude_install
    assert_failure
    assert_output_contains "~/.claude is a symlink to $BATS_TEST_TMPDIR/elsewhere"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ -L "$HOME/.claude" ]
    [ ! -e "$HOME/.config" ]
    [ ! -e "$(gui_file)" ]
}

# A Claude Code once run with CLAUDE_CONFIG_DIR=~/.claude keeps its own
# .claude.json inside it, which the move would overwrite with ~/.claude.json.
@test "a ~/.claude holding its own .claude.json beside ~/.claude.json is not moved, and nothing is published" {
    # AT025 (ST0006 AC011).
    setup_declared
    echo '{"userID": "inner"}' > "$HOME/.claude/.claude.json"
    run claude_install
    assert_failure
    assert_output_contains "~/.claude/.claude.json and ~/.claude.json both exist, and molt will not choose between them"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ "$(jq -r .userID "$HOME/.claude/.claude.json")" = "inner" ]
    [ "$(jq -r .userID "$HOME/.claude.json")" = "u" ]
    [ ! -e "$HOME/.config" ]
}

# critic-shell, 21 Oct: after a move, declaring a new dir leaves the state
# in the old one, and publishing the new, empty one would start Claude afresh.
@test "a newly declared, empty config dir is not published while the variable names another dir that exists" {
    # AT026 (ST0006 AC011, AC004).
    setup_moved
    run claude_install
    assert_success
    run env_install
    assert_success
    local old="$CONFIG"
    declare_config_dir "$HOME/.local/claude"
    run claude_install
    assert_failure
    assert_output_contains "~/.local/claude holds nothing, and CLAUDE_CONFIG_DIR named ~/.config/claude, which exists"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$old\"" "$HOME/.config/molt/env.sh"
    [ ! -e "$HOME/.local/claude" ]
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.local/claude holds nothing, and CLAUDE_CONFIG_DIR named ~/.config/claude"
}

# critic-shell, 21 Oct: vars.sh is read as leniently as molt_render reads it,
# and only what it declares counts, not what molt's own shell inherited.
@test "a vars.sh ending in a false test, or a MOLT_CLAUDE_CONFIG_DIR only inherited, leaves a sleeve undeclared" {
    # AT027 (ST0006 AC011).
    setup_claude
    local vars="$TEST_USER_REPO/instances/$(test_hostname)"
    mkdir -p "$vars"
    printf 'export MOLT_FONT_SIZE=12\n[[ -d /nonexistent ]] && export MOLT_EXTRA=1\n' > "$vars/vars.sh"
    export MOLT_CLAUDE_CONFIG_DIR="$HOME/.config/claude"
    run claude_install
    assert_success
    run claude_check
    assert_success
    [ ! -e "$HOME/.config/claude" ]
    [ ! -e "$HOME/.config/molt" ]
}

# vc, 21 Oct: sourcing stops at a syntax error, at an exit or a return, and at
# an error under the file's own set -u, so each read as undeclared after that
# point, and install then recreated ~/.claude on a sleeve whose state had moved.
@test "a vars.sh that does not parse, or stops before its end when sourced, is refused, and a moved sleeve gets no ~/.claude back" {
    # AT045 (ST0006 AC011).
    setup_moved
    run claude_install
    assert_success
    local vars="$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    printf 'fi\nexport MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" > "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars does not parse (line 1: syntax error"
    [ ! -e "$HOME/.claude" ]
    run claude_check
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars does not parse"
    printf 'set -u\nexport MOLT_FONT_SIZE="$MOLT_NOT_DECLARED"\nexport MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" > "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars stops before its end when sourced (line 2: MOLT_NOT_DECLARED: unbound variable)"
    [ ! -e "$HOME/.claude" ]
    printf '[ -n "$MOLT_ANYTHING" ] || exit 0\nexport MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" > "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars stops before its end when sourced"
    [ ! -e "$HOME/.claude" ]
    # An include guard's return ends only the file, and is caught all the same.
    printf '[ -n "${MOLT_VARS_LOADED:-}" ] || return 0\nexport MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" > "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars stops before its end when sourced"
    [ ! -e "$HOME/.claude" ]
    [ "$(cat "$CONFIG/projects/session.jsonl")" = "transcript" ]
}

# As root every file can be read, so this half has a test of its own to skip.
@test "a vars.sh that cannot be read is refused, and a moved sleeve gets no ~/.claude back" {
    # AT048 (ST0006 AC011).
    setup_moved
    run claude_install
    assert_success
    local vars="$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    chmod 000 "$vars"
    [ ! -r "$vars" ] || skip "this user can read a file whatever its mode"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_CLAUDE_CONFIG_DIR could not be read: $vars cannot be read"
    [ ! -e "$HOME/.claude" ]
    [ "$(cat "$CONFIG/projects/session.jsonl")" = "transcript" ]
}

# Each value is written as it stands into env.sh, a plist and an environment.d
# file, and read back from env.sh (vc, 21 Oct: a trailing slash trimmed in the
# reader alone matched none of them, and $() trimmed a trailing line break the
# files kept).
@test "a declared config dir that is relative, not canonical, holds a quote or a line break, ends in a space, or is ~/.claude itself is refused before anything moves" {
    # AT010 (ST0006 AC011).
    setup_declared
    declare_config_dir "$HOME/.config/claude"$'\n'
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR could not be read: $TEST_USER_REPO/instances/$(test_hostname)/vars.sh exports MOLT_CLAUDE_CONFIG_DIR with a line break in it"
    declare_config_dir "relative/claude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR is not an absolute path: relative/claude"
    declare_config_dir "$HOME/.config/claude/"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR is not a canonical path, with no trailing slash, // or . or .. component: $HOME/.config/claude/"
    declare_config_dir "$HOME/.config/../.claude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR is not a canonical path, with no trailing slash, // or . or .. component: $HOME/.config/../.claude"
    declare_config_dir "$HOME/.config/cl\"aude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR holds a character env.sh, a plist or environment.d would read as syntax"
    declare_config_dir "$HOME/.config/claude "
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR ends in whitespace, which environment.d would strip: '$HOME/.config/claude '"
    declare_config_dir "$HOME/.claude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR must be a directory of its own, not ~/.claude"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$HOME/.config" ]
    [ ! -e "$(gui_file)" ]
}

# No state anywhere, so nothing to split.
@test "on a sleeve Claude Code has not run on, install creates the config dir and publishes it" {
    # AT011 (ST0006 AC011).
    setup_declared
    rm -rf "$HOME/.claude" "$HOME/.claude.json"
    run claude_install
    assert_success
    [ -d "$CONFIG" ]
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    [ ! -e "$HOME/.claude" ]
    [ -z "$(ls -d "$CONFIG".molt-backup.* 2>/dev/null)" ]
}

# , and hv's ruling that nothing anti-brew is rendered (WP01 4b).
@test "the GUI file is a LaunchAgent on macOS and an environment.d file on Linux, and nothing published names Molt's checkout" {
    # AT012 (ST0006 AC011).
    setup_moved
    eval 'molt_platform() { echo macos; }'
    run claude_install
    assert_success
    run env_install
    assert_success
    local plist="$HOME/Library/LaunchAgents/com.molt.env.plist"
    grep -qF "<string>com.molt.env</string>" "$plist"
    grep -qF "<string>setenv</string>" "$plist"
    grep -qF "<string>$CONFIG</string>" "$plist"
    if command -v plutil >/dev/null; then
        plutil -lint "$plist"
    fi
    eval 'molt_platform() { echo linux; }'
    run env_install
    assert_success
    grep -qxF "CLAUDE_CONFIG_DIR=$CONFIG" "$HOME/.config/environment.d/molt.conf"
    # The templates take the sleeve's config dir and the agents root (AC014),
    # and nothing else of molt's, so no install of Molt can put its own path
    # into them.
    run grep -ohE '\$\{?MOLT_[A-Z_]*' "$MOLT_ROOT"/templates/claude/*
    assert_success
    [ "$(printf '%s\n' "$output" | sort -u)" = "$(printf '%s\n' '${MOLT_AGT_DIR' '${MOLT_CLAUDE_CONFIG_DIR')" ]
    run grep -lE '\$\{?MOLT_|/Molt' "$HOME/.config/molt/env.sh" "$HOME/.config/molt/claude-home-guard.sh" \
        "$plist" "$HOME/.config/environment.d/molt.conf"
    assert_failure
    [ -z "$output" ]
}

# --- Issue 0038: paths into ~/.claude in the settings the move takes ---
#
# The move took ~/.claude whole, but a hook on rhadamanth named its script in it
# by path: the script moved, the line did not, and every Bash call in every
# session was refused (23 Oct).

@test "the move rewrites each path into ~/.claude that settings.json names, in its own spelling, naming each with its key, and leaves a .claude outside ~/.claude alone (issue 0038)" {
    setup_declared
    # The sleeve's own statusLine: one the user repo declared would replace it.
    rm "$TEST_USER_REPO/config/claude/statusline.json"
    # $HOME expands here, into an absolute path; \$HOME, \${HOME} and
    # \$CLAUDE_PROJECT_DIR are left for the shell that runs the hook, and a
    # path may start a value's second line. A permission rule spells an
    # absolute path from //, and a backup volume's copy of the home is not it.
    cat > "$HOME/.claude/settings.json" <<JSON
{
  "hooks": {
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "python3 $HOME/.claude/hooks/guard.py" } ] } ],
    "SessionStart": [ { "hooks": [ { "type": "command", "command": "\"\$HOME/.claude/hooks/x.sh\" \${HOME}/.claude/hooks/y.sh" } ] } ],
    "Notification": [ { "hooks": [ { "type": "command", "command": "set -e\n~/.claude/hooks/notify.sh" } ] } ],
    "Stop": [ { "hooks": [ { "type": "command", "command": "\$CLAUDE_PROJECT_DIR/.claude/hooks/stop.sh" } ] } ]
  },
  "permissions": { "allow": [ "Read(/$HOME/.claude/**)", "Read(/Volumes/Backup$HOME/.claude/**)" ] },
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
}
JSON
    local settings="$CONFIG/settings.json" original backup written
    original="$(cat "$HOME/.claude/settings.json")"
    run claude_install
    assert_success
    [ "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$settings")" = "python3 $CONFIG/hooks/guard.py" ]
    [ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$settings")" = '"$HOME/.config/claude/hooks/x.sh" ${HOME}/.config/claude/hooks/y.sh' ]
    [ "$(jq -r '.hooks.Notification[0].hooks[0].command' "$settings")" = $'set -e\n~/.config/claude/hooks/notify.sh' ]
    [ "$(jq -r .statusLine.command "$settings")" = "~/.config/claude/statusline.sh" ]
    [ "$(jq -r '.hooks.Stop[0].hooks[0].command' "$settings")" = '$CLAUDE_PROJECT_DIR/.claude/hooks/stop.sh' ]
    [ "$(jq -r '.permissions.allow[0]' "$settings")" = "Read(/$CONFIG/**)" ]
    [ "$(jq -r '.permissions.allow[1]' "$settings")" = "Read(/Volumes/Backup$HOME/.claude/**)" ]
    assert_output_contains "claude: rewrote .hooks.PreToolUse[0].hooks[0].command in ~/.config/claude/settings.json: \"python3 $HOME/.claude/hooks/guard.py\" -> \"python3 $CONFIG/hooks/guard.py\""
    assert_output_contains 'claude: rewrote .hooks.SessionStart[0].hooks[0].command in ~/.config/claude/settings.json: "\"$HOME/.claude/hooks/x.sh\" ${HOME}/.claude/hooks/y.sh" -> "\"$HOME/.config/claude/hooks/x.sh\" ${HOME}/.config/claude/hooks/y.sh"'
    assert_output_contains 'claude: rewrote .hooks.Notification[0].hooks[0].command in ~/.config/claude/settings.json: "set -e\n~/.claude/hooks/notify.sh" -> "set -e\n~/.config/claude/hooks/notify.sh"'
    assert_output_contains 'claude: rewrote .statusLine.command in ~/.config/claude/settings.json: "~/.claude/statusline.sh" -> "~/.config/claude/statusline.sh"'
    assert_output_contains "claude: rewrote .permissions.allow[0] in ~/.config/claude/settings.json: \"Read(/$HOME/.claude/**)\" -> \"Read(/$CONFIG/**)\""
    refute_output_contains ".hooks.Stop"
    refute_output_contains ".permissions.allow[1]"
    # The move's copy holds the file as it was.
    backup="$(ls -d "$CONFIG".molt-backup.*)"
    [ "$(cat "$backup/.claude/settings.json")" = "$original" ]
    # Doctor finds nothing left, and a second run rewrites nothing.
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_check
    assert_success
    written="$(cat "$settings")"
    run claude_install
    assert_success
    refute_output_contains "claude: rewrote"
    [ "$(cat "$settings")" = "$written" ]
}

@test "check and verify name a path into ~/.claude that settings.json names after the move, with its key, install leaves it, and a sleeve that declares no config dir hears nothing of it (issue 0038)" {
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_check
    assert_success
    local settings="$CONFIG/settings.json" planted
    jq --arg command "bash $HOME/.claude/hooks/late.sh" \
        '.hooks.SessionStart = [{hooks: [{type: "command", command: $command}]}]' \
        "$settings" > "$BATS_TEST_TMPDIR/settings.json"
    mv "$BATS_TEST_TMPDIR/settings.json" "$settings"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/claude/settings.json .hooks.SessionStart[0].hooks[0].command still names a path under ~/.claude, and this sleeve's config dir is ~/.config/claude: \"bash $HOME/.claude/hooks/late.sh\""
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.config/claude/settings.json .hooks.SessionStart[0].hooks[0].command still names a path under ~/.claude"
    # The move answers for the paths it moved; one named after it is the
    # user's to change.
    planted="$(cat "$settings")"
    run claude_install
    assert_success
    [ "$(cat "$settings")" = "$planted" ]
    # A sleeve that declares no config dir had nothing moved, and hears nothing.
    rm "$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    run claude_check
    assert_success
}

# critic-shell, 23 Oct: spliced into a command, a config dir with a space in it
# splits the command there, and doctor would pass the value, since it no longer
# names ~/.claude.
@test "a config dir a shell would split or expand is not spliced into settings.json: the value is left and named, the run fails, and doctor names it (issue 0038)" {
    setup_declared
    local dir="$BATS_TEST_TMPDIR/claude config" command="python3 $HOME/.claude/hooks/guard.py"
    declare_config_dir "$dir"
    jq -n --arg command "$command" '{hooks: {PreToolUse: [{matcher: "Bash", hooks: [{type: "command", command: $command}]}]}}' \
        > "$HOME/.claude/settings.json"
    run claude_install
    assert_failure
    assert_output_contains "claude: $dir/settings.json was left: $dir holds a character a shell would split or expand"
    assert_output_contains "  .hooks.PreToolUse[0].hooks[0].command: \"$command\""
    [ "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$dir/settings.json")" = "$command" ]
    # The state is in the dir, so it is published all the same.
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$dir\"" "$HOME/.config/molt/env.sh"
    export CLAUDE_CONFIG_DIR="$dir"
    run claude_check
    assert_failure
    assert_output_contains "claude: $dir/settings.json .hooks.PreToolUse[0].hooks[0].command still names a path under ~/.claude, and this sleeve's config dir is $dir: \"$command\""
}

# --- ST0006: the home guard ---

# Where the session was launched is CLAUDE_PROJECT_DIR, which stays put; the cwd
# in the hook's input follows every cd (vc, 21 Oct), and is not what is tested.
@test "the home guard exits 2 with the agent-home message for a session launched in \$HOME, wherever it has cd'd since, and 0 for one launched anywhere else" {
    # AT013 (ST0006 AC003).
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh"
    [ -x "$guard" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$HOME" "$guard" <<< "{\"cwd\": \"$HOME/work\", \"prompt\": \"hello\"}"
    [ "$status" -eq 2 ]
    [ "$output" = "launch from an agent home: molt agent start <role>" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$HOME/" "$guard" <<< '{"prompt": "a trailing slash is still home"}'
    [ "$status" -eq 2 ]
    ln -s "$HOME" "$BATS_TEST_TMPDIR/home-link"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/home-link" "$guard" < /dev/null
    [ "$status" -eq 2 ]
    mkdir -p "$BATS_TEST_TMPDIR/agt/kovacs-sysadm"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/agt/kovacs-sysadm" "$guard" <<< "{\"cwd\": \"$HOME\", \"prompt\": \"after a cd into \$HOME\"}"
    assert_success
    [ -z "$output" ]
}

# Exit 1 blocks nothing, and Claude Code shows what it printed. The guard needs
# nothing on PATH: with none it still refuses $HOME.
@test "the home guard exits 1, saying so, when the hook has no CLAUDE_PROJECT_DIR or HOME, or a relative one, and needs nothing on PATH" {
    # AT014 (ST0006 AC003).
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh"
    run env -u CLAUDE_PROJECT_DIR "$guard" <<< "{\"cwd\": \"$HOME\"}"
    [ "$status" -eq 1 ]
    [ "$output" = "claude-home-guard: the hook has no CLAUDE_PROJECT_DIR, so the launch directory was not checked" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR= "$guard" <<< "{\"cwd\": \"$HOME\"}"
    [ "$status" -eq 1 ]
    assert_output_contains "the hook has no CLAUDE_PROJECT_DIR"
    run env PATH=/nonexistent CLAUDE_PROJECT_DIR="$HOME" "$guard" <<< "{\"cwd\": \"$HOME\"}"
    [ "$status" -eq 2 ]
    # Run from the launch directory, where cd "" or cd . stays put: an agent
    # home would read as $HOME, and $HOME as anywhere (critic-shell, 21 Oct).
    local agent_home="$BATS_TEST_TMPDIR/agt/kovacs-sysadm"
    mkdir -p "$agent_home"
    run bash -c 'cd "$1" && env -u HOME CLAUDE_PROJECT_DIR="$1" "$2" < /dev/null' _ "$agent_home" "$guard"
    [ "$status" -eq 1 ]
    [ "$output" = "claude-home-guard: the hook has no HOME, so the launch directory was not checked" ]
    run bash -c 'cd "$1" && env HOME= CLAUDE_PROJECT_DIR="$1" "$2" < /dev/null' _ "$agent_home" "$guard"
    [ "$status" -eq 1 ]
    assert_output_contains "the hook has no HOME"
    run bash -c 'cd "$1" && env HOME=. CLAUDE_PROJECT_DIR="$1" "$2" < /dev/null' _ "$agent_home" "$guard"
    [ "$status" -eq 1 ]
    assert_output_contains "claude-home-guard: HOME is not an absolute path"
    run bash -c 'cd "$1" && env CLAUDE_PROJECT_DIR=. "$2" < /dev/null' _ "$HOME" "$guard"
    [ "$status" -eq 1 ]
    assert_output_contains "claude-home-guard: CLAUDE_PROJECT_DIR is not an absolute path"
}

# --- ST0006 AC014: the home guard under MOLT_AGT_DIR ---
#
# Claude Code reads CLAUDE.md up the tree but project settings only from the
# launch directory's .claude/, so a session launched below a home keeps the
# home's contract and loses its fence (vc, 21 Oct).

@test "the home guard passes a session launched in an agent home itself, wherever in the home it has cd'd since" {
    # AT053 (ST0006 AC014).
    setup_moved
    run claude_install
    assert_success
    local agent_home="$MOLT_AGT_DIR/kovacs-sysadm"
    mkdir -p "$agent_home/work/x"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$agent_home" "$HOME/.config/molt/claude-home-guard.sh" <<< "{\"cwd\": \"$agent_home/work/x\", \"prompt\": \"hello\"}"
    assert_success
    [ -z "$output" ]
}

@test "the home guard refuses a session launched in the agents root itself" {
    # AT054 (ST0006 AC014).
    setup_moved
    run claude_install
    assert_success
    mkdir -p "$MOLT_AGT_DIR"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$MOLT_AGT_DIR" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "launch from an agent home, not the agents root: molt agent start <role>" ]
}

@test "the home guard refuses a session launched below an agent home, by any spelling, naming the agent to start" {
    # AT055 (ST0006 AC014).
    setup_moved
    run claude_install
    assert_success
    local agent_home="$MOLT_AGT_DIR/kovacs-sysadm"
    mkdir -p "$agent_home/work/x"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$agent_home/work/x" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "launch from the agent home itself: molt agent start ${agent_home##*/}" ]
    ln -s "$agent_home/work" "$BATS_TEST_TMPDIR/work-link"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/work-link" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "launch from the agent home itself: molt agent start ${agent_home##*/}" ]
}

# A root spelt in another letter case than the disk's is the same directory on
# a disk that ignores case, as APFS does by default: bash's own pwd -P kept the
# spelling it was given, and the guard fenced nothing; and molt_agt_dir_fault,
# comparing spellings, passed HOME spelt so (critic-shell, 21 Oct).
@test "on a disk that ignores letter case, the home guard and molt_agt_dir_fault take a root spelt in another case for the directory the disk names" {
    # AT065 (ST0006 AC014).
    setup_moved
    local agent_home="$MOLT_AGT_DIR/kovacs-sysadm" upper="${MOLT_AGT_DIR%/*}/AGT"
    mkdir -p "$agent_home/work/x"
    [ -d "$upper" ] || skip "this disk tells letter case apart"
    export MOLT_AGT_DIR="$upper"
    run claude_install
    assert_success
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$agent_home/work/x" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "launch from the agent home itself: molt agent start kovacs-sysadm" ]
    export MOLT_AGT_DIR="${HOME%/*}/FAKEHOME"
    run molt_agt_dir_fault
    assert_output_contains "MOLT_AGT_DIR, ${HOME%/*}/FAKEHOME, is at or above ~: the home guard would refuse"
}

@test "the home guard passes a session launched outside the agents root, a sibling sharing its name's start included" {
    # AT056 (ST0006 AC014).
    setup_moved
    run claude_install
    assert_success
    mkdir -p "$MOLT_AGT_DIR" "$BATS_TEST_TMPDIR/projects/molt" "$MOLT_AGT_DIR-old/kovacs-sysadm/work"
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/projects/molt" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    assert_success
    [ -z "$output" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$MOLT_AGT_DIR-old/kovacs-sysadm/work" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    assert_success
    [ -z "$output" ]
    # The root is data to the guard, never a pattern or an expansion: a root
    # with * and $ in it fences itself and not a sibling that a pattern made of
    # it would match (critic-shell, 21 Oct).
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/a*b\$c"
    mkdir -p "$MOLT_AGT_DIR/kovacs-sysadm/work" "$BATS_TEST_TMPDIR/aXb\$c/kovacs-sysadm/work"
    run claude_install
    assert_success
    [ "$(_claude_guard_line "$HOME/.config/molt/claude-home-guard.sh" MOLT_AGENTS_ROOT)" = "$MOLT_AGT_DIR" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/aXb\$c/kovacs-sysadm/work" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    assert_success
    [ -z "$output" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$MOLT_AGT_DIR/kovacs-sysadm/work" "$HOME/.config/molt/claude-home-guard.sh" < /dev/null
    [ "$status" -eq 2 ]
}

# vc, 21 Oct: the guard is rendered with the agents root as it stands, and
# molt_agt_dir_fault, which the agents liberator asks too, refuses a root that
# is relative, untidy, at or above HOME or a project root, where the guard
# would refuse every project, or one vars.sh exports apart from constants.sh.
@test "an agents root molt_agt_dir_fault refuses is refused before anything moves" {
    # AT057 (ST0006 AC014).
    setup_declared
    export MOLT_AGT_DIR="agt"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_AGT_DIR is not an absolute path: agt"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt/"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_AGT_DIR is not a canonical path, with no trailing slash, // or . or .. component: $BATS_TEST_TMPDIR/agt/"
    export MOLT_AGT_DIR="$HOME"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_AGT_DIR, ~, is at or above ~: the home guard would refuse"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/Devel/prj" MOLT_AGT_DIR="$BATS_TEST_TMPDIR/Devel"
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_AGT_DIR, $BATS_TEST_TMPDIR/Devel, is at or above $BATS_TEST_TMPDIR/Devel/prj"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    local vars="$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    printf 'export MOLT_AGT_DIR=%q\n' "$BATS_TEST_TMPDIR/elsewhere" >> "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: this sleeve's vars.sh sets MOLT_AGT_DIR to $BATS_TEST_TMPDIR/elsewhere, but molt resolves it as $BATS_TEST_TMPDIR/agt"
    # Without an export it still reached the guard, since MOLT_AGT_DIR is
    # exported where molt renders (critic-shell, 21 Oct).
    declare_config_dir "$CONFIG"
    printf 'MOLT_AGT_DIR=%q\n' "$BATS_TEST_TMPDIR/elsewhere" >> "$vars"
    run claude_install
    assert_failure
    assert_output_contains "claude: this sleeve's vars.sh sets MOLT_AGT_DIR to $BATS_TEST_TMPDIR/elsewhere, but molt resolves it as $BATS_TEST_TMPDIR/agt"
    # Asked on a sleeve with no agents too: a Molt sleeve always has
    # MOLT_PRJ_DIR (vc, 21 Oct).
    declare_config_dir "$CONFIG"
    unset MOLT_PRJ_DIR
    export MOLT_AGT_DIR=""
    run claude_install
    assert_failure
    assert_output_contains "claude: MOLT_AGT_DIR cannot be resolved: MOLT_PRJ_DIR is unset"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$HOME/.config" ]
    [ ! -e "$(gui_file)" ]
}

# vc, 21 Oct: the guard's digest covers its template and vars.sh, not the
# agents root, so a root that moved after the render would go unnoticed.
@test "check reports a home guard rendered with an agents root that is no longer MOLT_AGT_DIR, and install renders it again" {
    # AT058 (ST0006 AC014).
    setup_moved
    run claude_install
    assert_success
    local old="$MOLT_AGT_DIR" guard="$HOME/.config/molt/claude-home-guard.sh"
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_check
    assert_success
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agents"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh refuses launches under $old, but MOLT_AGT_DIR is $MOLT_AGT_DIR: re-run molt upgrade"
    run claude_install
    assert_success
    [ "$(_claude_guard_line "$guard" MOLT_AGENTS_ROOT)" = "$MOLT_AGT_DIR" ]
    run claude_check
    assert_success
}

# --- Issue 0030: the home guard and the config dir ---
#
# A session started from a shell opened before the move gets no
# CLAUDE_CONFIG_DIR and starts Claude Code afresh in $HOME; the user settings
# that run the guard are in the config dir it missed, so only an agent home's
# copy of the hook runs, and the guard has to tell (kovacs, 21 Oct).

@test "the home guard refuses a session that did not get this sleeve's config dir, or got another, and passes one naming it by any spelling, under sh too (issue 0030)" {
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh" agent_home="$MOLT_AGT_DIR/kovacs-sysadm" shell
    local missed="this Claude Code did not get CLAUDE_CONFIG_DIR (want $CONFIG): quit it, open a new shell, or log out and in, and start it with molt agent start <role>"
    mkdir -p "$agent_home"
    run env -u CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "$missed" ]
    run env CLAUDE_CONFIG_DIR= CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "$missed" ]
    run env CLAUDE_CONFIG_DIR="$HOME/.claude" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    [ "$status" -eq 2 ]
    [ "$output" = "this Claude Code has CLAUDE_CONFIG_DIR $HOME/.claude, not $CONFIG: quit it, open a new shell, or log out and in, and start it with molt agent start <role>" ]
    run env CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/nowhere" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    [ "$status" -eq 2 ]
    run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    assert_success
    [ -z "$output" ]
    run env CLAUDE_CONFIG_DIR="$CONFIG/" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    assert_success
    ln -s "$CONFIG" "$BATS_TEST_TMPDIR/config-link"
    run env CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/config-link" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
    assert_success
    [ -z "$output" ]
    for shell in sh dash; do
        command -v "$shell" >/dev/null || continue
        run env -u CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR="$agent_home" "$shell" "$guard" < /dev/null
        [ "$status" -eq 2 ]
        [ "$output" = "$missed" ]
        run env CLAUDE_CONFIG_DIR="$CONFIG" CLAUDE_PROJECT_DIR="$agent_home" "$shell" "$guard" < /dev/null
        assert_success
    done
}

@test "a home guard rendered with no config dir passes a session whatever CLAUDE_CONFIG_DIR holds (issue 0030)" {
    setup_claude
    local guard="$BATS_TEST_TMPDIR/guard.sh" agent_home="$MOLT_AGT_DIR/kovacs-sysadm" value
    mkdir -p "$agent_home"
    # Undeclared, envsubst leaves the reference as it is; declared empty, it
    # renders an empty line. Neither is an absolute path.
    for value in unset empty; do
        if [ "$value" = empty ]; then
            export MOLT_CLAUDE_CONFIG_DIR=
        else
            unset MOLT_CLAUDE_CONFIG_DIR
        fi
        run molt_render "$MOLT_ROOT/templates/claude/claude-home-guard.sh.tmpl" "$guard"
        assert_success
        chmod 755 "$guard"
        run env -u CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
        assert_success
        [ -z "$output" ]
        run env CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/anywhere" CLAUDE_PROJECT_DIR="$agent_home" "$guard" < /dev/null
        assert_success
        [ -z "$output" ]
    done
}

# The digest covers the template and vars.sh, and vars.sh can build the config
# dir from XDG_CONFIG_HOME, so a guard can name a dir no digest change shows.
@test "check reports a home guard rendered with another config dir, or none, and install renders it again (issue 0030)" {
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh"
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_check
    assert_success
    [ "$(_claude_guard_line "$guard" MOLT_CLAUDE_CONFIG_DIR)" = "$CONFIG" ]
    awk -v old="$CONFIG" -v new="$BATS_TEST_TMPDIR/elsewhere" '$0 == old { $0 = new } { print }' "$guard" > "$guard.new"
    mv "$guard.new" "$guard"
    chmod 755 "$guard"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh checks sessions for config dir $BATS_TEST_TMPDIR/elsewhere, but this sleeve's is ~/.config/claude: re-run molt upgrade"
    run claude_install
    assert_success
    [ "$(_claude_guard_line "$guard" MOLT_CLAUDE_CONFIG_DIR)" = "$CONFIG" ]
    run claude_check
    assert_success
    # A guard rendered before issue 0030 has no such line.
    awk '/<<.MOLT_CLAUDE_CONFIG_DIR.$/ { skip = 3 } skip { skip--; next } { print }' "$guard" > "$guard.new"
    mv "$guard.new" "$guard"
    chmod 755 "$guard"
    run grep -q MOLT_CLAUDE_CONFIG_DIR "$guard"
    assert_failure
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh checks sessions for no config dir, but this sleeve's is ~/.config/claude: re-run molt upgrade"
    run claude_install
    assert_success
    run claude_check
    assert_success
}

@test "the hook merge adds the guard once, keeps every other key and hook as it was, and a second install writes nothing" {
    # AT015 (ST0006 AC003).
    setup_moved
    cat > "$CONFIG/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls:*)"], "deny": ["Read(./.env)"] },
  "hooks": {
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "audit.sh" } ] } ],
    "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "someone-elses.sh" } ] } ]
  },
  "enabledPlugins": { "a@b": true }
}
JSON
    local others written
    others="$(jq -S 'del(.hooks.UserPromptSubmit, .statusLine)' "$CONFIG/settings.json")"
    run claude_install
    assert_success
    [ "$(jq -S 'del(.hooks.UserPromptSubmit, .statusLine)' "$CONFIG/settings.json")" = "$others" ]
    [ "$(jq -c '[.hooks.UserPromptSubmit[].hooks[].command]' "$CONFIG/settings.json")" \
        = '["someone-elses.sh","~/.config/molt/claude-home-guard.sh"]' ]
    written="$(cat "$CONFIG/settings.json")"
    run claude_install
    assert_success
    refute_output_contains "written into"
    [ "$(cat "$CONFIG/settings.json")" = "$written" ]
}

# --- ST0006: what doctor reports ---

@test "check reports CLAUDE_CONFIG_DIR unset where molt runs, or naming another dir, and passes once it names the config dir, in any spelling the home guard takes for it" {
    # AT016 (ST0006 AC004).
    setup_moved
    run claude_install
    assert_success
    run claude_check
    assert_failure
    assert_output_contains "claude: CLAUDE_CONFIG_DIR is not set where molt runs"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/other"
    run claude_check
    assert_failure
    assert_output_contains "claude: CLAUDE_CONFIG_DIR is $BATS_TEST_TMPDIR/other, not this sleeve's config dir ~/.config/claude"
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_check
    assert_success
    run claude_verify
    assert_success
    # The guard resolves both before it compares, so a link to the config dir,
    # or a trailing slash, is the config dir.
    ln -s "$CONFIG" "$BATS_TEST_TMPDIR/linked"
    for CLAUDE_CONFIG_DIR in "$BATS_TEST_TMPDIR/linked" "$CONFIG/"; do
        run claude_check
        assert_success
    done
}

# The sign that a launch path missed the variable.
@test "check reports ~/.claude or ~/.claude.json present while the config dir is elsewhere, whether a directory, a file or a link" {
    # AT017 (ST0006 AC004).
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    mkdir "$HOME/.claude"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude is present while the config dir is ~/.config/claude: a launch path missed CLAUDE_CONFIG_DIR"
    echo '{}' > "$HOME/.claude.json"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude and ~/.claude.json are present while the config dir is ~/.config/claude"
    rmdir "$HOME/.claude"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude.json is present while the config dir is ~/.config/claude"
    rm "$HOME/.claude.json"
    ln -s "$CONFIG" "$HOME/.claude"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude is a symlink to $CONFIG"
}

# The native installer keeps its binary and versions under ~/.local and
# ~/.cache, wherever the config dir is.
@test "the native installer's own paths under ~/.local and ~/.cache are not faults" {
    # AT018 (ST0006 AC004).
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/claude/versions" "$HOME/.local/state/claude" "$HOME/.cache/claude"
    ln -s "$HOME/.local/share/claude/versions/2.1.306" "$HOME/.local/bin/claude"
    run claude_check
    assert_success
}

@test "check and verify report the guard missing or stale, and the hook missing from settings.json" {
    # AT019 (ST0006 AC004); env.sh and the GUI file are the env liberator's (env.bats).
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    rm "$HOME/.config/molt/claude-home-guard.sh"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh is missing"
    run claude_install
    assert_success
    echo 'export MOLT_FONT_SIZE=12' >> "$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh differs from its template or this sleeve's vars.sh"
    run claude_install
    assert_success
    chmod 644 "$HOME/.config/molt/claude-home-guard.sh"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/claude-home-guard.sh is not executable"
    run claude_install
    assert_success
    jq 'del(.hooks)' "$CONFIG/settings.json" > "$BATS_TEST_TMPDIR/settings.json"
    mv "$BATS_TEST_TMPDIR/settings.json" "$CONFIG/settings.json"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.config/claude/settings.json has no home-launch hook"
    run claude_install
    assert_success
    run claude_check
    assert_success
}

@test "check and verify report a move still pending, naming what is in \$HOME" {
    # AT020 (ST0006 AC004).
    setup_declared
    run claude_check
    assert_failure
    assert_output_contains "claude: Claude Code's state is still in ~/.claude and ~/.claude.json, and this sleeve's config dir is ~/.config/claude"
    rm "$HOME/.claude.json"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: Claude Code's state is still in ~/.claude, and"
}

# --- ST0006: the user-scope rules ---

@test "CLAUDE.md and AGENTS.md are linked into the config dir, and a regular file there is backed up first" {
    # AT021 (ST0006 AC012).
    setup_claude
    echo "# rules" > "$TEST_USER_REPO/config/claude/CLAUDE.md"
    echo "# contract" > "$TEST_USER_REPO/config/claude/AGENTS.md"
    echo "# hand-written" > "$HOME/.claude/CLAUDE.md"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude/CLAUDE.md is not a symlink"
    assert_output_contains "claude: ~/.claude/AGENTS.md is missing"
    run claude_install
    assert_success
    assert_symlink_exists "$HOME/.claude/CLAUDE.md" "$TEST_USER_REPO/config/claude/CLAUDE.md"
    assert_symlink_exists "$HOME/.claude/AGENTS.md" "$TEST_USER_REPO/config/claude/AGENTS.md"
    run cat "$HOME"/.claude/CLAUDE.md.molt-backup.*
    [ "$output" = "# hand-written" ]
    run claude_check
    assert_success
}

@test "check and verify report a CLAUDE.md link that is broken" {
    # AT022 (ST0006 AC012).
    setup_claude
    echo "# rules" > "$TEST_USER_REPO/config/claude/CLAUDE.md"
    claude_install >/dev/null
    ln -sfn "$BATS_TEST_TMPDIR/moved/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.claude/CLAUDE.md is a broken symlink"
    run claude_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: ~/.claude/CLAUDE.md is a broken symlink"
}

# vc, 24 Oct: once the env liberator publishes CLAUDE_CONFIG_DIR, a molt.toml
# without it would stop publishing it, silently.
@test "a sleeve that declares a config dir and whose molt.toml does not enable env fails check and install by name" {
    setup_moved
    local manifest="$TEST_USER_REPO/instances/$(test_hostname)/molt.toml"
    printf '[[liberator]]\nname = "claude"\n' > "$manifest"
    export CLAUDE_CONFIG_DIR="$CONFIG"
    run claude_install
    assert_failure
    assert_output_contains "claude: CLAUDE_CONFIG_DIR is published by the env liberator, which $(molt_tilde "$manifest") does not enable: add a [[liberator]] named env after claude"
    run claude_check
    assert_failure
    assert_output_contains "does not enable: add a [[liberator]] named env after claude"
    printf '[[liberator]]\nname = "claude"\n\n[[liberator]]\nname = "env"\n' > "$manifest"
    run claude_install
    assert_success
    run claude_check
    assert_success
}
