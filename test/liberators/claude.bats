#!/usr/bin/env bats
# claude.bats — claude liberator (keybindings, rules, ccstatusline layout,
# statusLine; and, on a sleeve that declares MOLT_CLAUDE_CONFIG_DIR, the config
# dir, the one-time move, its publication and the home guard: ST0006)

load "../test_helper.bash"

STATUSLINE='{"type":"command","command":"npx -y ccstatusline@latest","padding":0}'

setup_claude() {
    load_liberator claude

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"

    export TEST_USER_REPO="$BATS_TEST_TMPDIR/molt-testuser"
    mkdir -p "$TEST_USER_REPO/config/claude" "$TEST_USER_REPO/config/ccstatusline"
    eval "molt_find_user_repo() { echo \"$TEST_USER_REPO\"; }"

    echo '{"bindings": []}' > "$TEST_USER_REPO/config/claude/keybindings.json"
    echo '{"version": 3}' > "$TEST_USER_REPO/config/ccstatusline/settings.json"
    echo "$STATUSLINE" > "$TEST_USER_REPO/config/claude/statusline.json"

    # pgrep and ps answer from a process table in the test directory, never from
    # this machine's, where a Claude Code may well be running. The pgrep stub
    # applies the liberator's own pattern, so what counts as Claude Code is
    # decided here as it is in production.
    export FAKE_PROCS="$BATS_TEST_TMPDIR/procs"
    : > "$FAKE_PROCS"
    mkdir -p "$BATS_TEST_TMPDIR/stub"
    cat > "$BATS_TEST_TMPDIR/stub/pgrep" <<'EOF'
#!/bin/bash
# pgrep -u <uid> -f <pattern>: the pids in $FAKE_PROCS whose command line matches.
for pattern; do :; done
awk -v pat="$pattern" '{ args = $0; sub(/^[0-9]+ /, "", args) } args ~ pat { print $1; n++ } END { exit n ? 0 : 1 }' "$FAKE_PROCS"
EOF
    cat > "$BATS_TEST_TMPDIR/stub/ps" <<'EOF'
#!/bin/bash
# ps -o pid=,args= -p <pid,pid>: those rows of $FAKE_PROCS.
for pids; do :; done
awk -v pids=",$pids," 'index(pids, "," $1 ",")' "$FAKE_PROCS"
EOF
    chmod +x "$BATS_TEST_TMPDIR/stub/pgrep" "$BATS_TEST_TMPDIR/stub/ps"
    export PATH="$BATS_TEST_TMPDIR/stub:$PATH"
}

# The process table the pgrep and ps stubs answer from, one "pid command line"
# per argument.
fake_processes() {
    printf '%s\n' "$@" > "$FAKE_PROCS"
}

# Declares $1 as this sleeve's config dir in its vars.sh, as hv does sleeve by
# sleeve (ST0006 WP04).
declare_config_dir() {
    local vars="$TEST_USER_REPO/instances/$(hostname -s 2>/dev/null || hostname)"
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
        macos) echo "$HOME/Library/LaunchAgents/com.molt.claude-config-dir.plist" ;;
        *)     echo "$HOME/.config/environment.d/claude.conf" ;;
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

# AC001
@test "with CLAUDE_CONFIG_DIR set, claude_install, check and verify use only it, and write nothing into ~/.claude" {
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

# AC001. The mkdir -p "$HOME/.claude" this replaced would have recreated exactly
# what doctor faults.
@test "with CLAUDE_CONFIG_DIR set and no ~/.claude, claude_install creates none" {
    setup_claude
    rm -rf "$HOME/.claude"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/xdg/claude"
    run claude_install
    assert_success
    [ -d "$CLAUDE_CONFIG_DIR" ]
    [ ! -e "$HOME/.claude" ]
}

# AC001. molt can run in a shell that has not sourced env.sh yet.
@test "on a sleeve whose state has moved, claude_install writes only the config dir though this shell lacks CLAUDE_CONFIG_DIR" {
    setup_moved
    run claude_install
    assert_success
    assert_output_contains "CLAUDE_CONFIG_DIR is not ~/.config/claude in this shell"
    [ ! -e "$HOME/.claude" ]
    [ ! -e "$HOME/.claude.json" ]
    assert_symlink_exists "$CONFIG/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ "$(jq -cS .statusLine "$CONFIG/settings.json")" = "$(jq -cS . <<<"$STATUSLINE")" ]
}

# AC002, AC011
@test "the move refuses while Claude Code runs, names each process, and moves and publishes nothing" {
    setup_declared
    fake_processes "4242 claude --name kovacs-sysadm" "4243 /Users/x/.local/bin/claude --chrome-native-host" "77 -zsh"
    run claude_install
    assert_failure
    assert_output_contains "Claude Code is running"
    assert_output_contains "4242 claude --name kovacs-sysadm"
    assert_output_contains "4243 /Users/x/.local/bin/claude --chrome-native-host"
    refute_output_contains "77 -zsh"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ "$(jq -r .userID "$HOME/.claude.json")" = "u" ]
    # Not the config dir, not its copies, not env.sh: nothing under ~/.config.
    [ ! -e "$HOME/.config" ]
    [ ! -e "$(gui_file)" ]
}

# AC002, AC011
@test "the move takes ~/.claude and ~/.claude.json into the config dir, copies both beside it first, then publishes it" {
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
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    grep -qF "$CONFIG" "$(gui_file)"
    # What the run wrote after the move went to the config dir.
    assert_symlink_exists "$CONFIG/keybindings.json" "$TEST_USER_REPO/config/claude/keybindings.json"
    [ ! -e "$HOME/.claude" ]
}

# AC002. kovacs-sysadm's review: a command that merely names the package is not
# Claude Code, and procps prints only a name for pgrep -l.
@test "a native or node-run Claude Code counts as running; a grep, npm ls or molt run naming it does not" {
    setup_claude
    fake_processes "9 grep -r @anthropic-ai/claude-code ." \
        "10 node /usr/lib/node_modules/npm/bin/npm-cli.js ls @anthropic-ai/claude-code" \
        "11 /Applications/ClaudeUsage.app/Contents/MacOS/ClaudeUsage" \
        "12 bash /Users/x/Devel/prj/Molt/bin/molt upgrade claude" \
        "13 vim /tmp/claude.md"
    run _claude_processes
    assert_success
    [ -z "$output" ]
    fake_processes "12 bash /Users/x/Devel/prj/Molt/bin/molt upgrade claude" \
        "14 node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js --resume" \
        "15 /Users/x/Library/Application Support/Claude/claude-code/2.1.0/claude --print" \
        "16 claude"
    run _claude_processes
    assert_success
    [ "$output" = "$(printf '%s\n' \
        "14 node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js --resume" \
        "15 /Users/x/Library/Application Support/Claude/claude-code/2.1.0/claude --print" \
        "16 claude")" ]
}

# AC011
@test "a config dir that already holds anything is refused, named with its contents, and nothing is merged or published" {
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

# AC011
@test "an empty config dir counts as absent, and the move goes ahead" {
    setup_declared
    mkdir -p "$CONFIG"
    run claude_install
    assert_success
    [ "$(cat "$CONFIG/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$HOME/.claude" ]
}

# AC011
@test "a ~/.claude that is a symlink is not moved, and nothing is published" {
    setup_declared
    mv "$HOME/.claude" "$BATS_TEST_TMPDIR/elsewhere"
    ln -s "$BATS_TEST_TMPDIR/elsewhere" "$HOME/.claude"
    run claude_install
    assert_failure
    assert_output_contains "~/.claude is a symlink to $BATS_TEST_TMPDIR/elsewhere"
    assert_output_contains "CLAUDE_CONFIG_DIR was not published"
    [ -L "$HOME/.claude" ]
    [ ! -e "$HOME/.config" ]
}

# AC011. Each value is written into env.sh, a plist and an environment.d file.
@test "a declared config dir that is relative, holds a quote, or is ~/.claude itself is refused before anything moves" {
    setup_declared
    declare_config_dir "relative/claude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR is not an absolute path: relative/claude"
    declare_config_dir "$HOME/.config/cl\"aude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR holds a character env.sh, a plist or environment.d would read as syntax"
    declare_config_dir "$HOME/.claude"
    run claude_install
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR must be a directory of its own, not ~/.claude"
    [ "$(cat "$HOME/.claude/projects/session.jsonl")" = "transcript" ]
    [ ! -e "$HOME/.config" ]
}

# AC011. No state anywhere, so nothing to split.
@test "on a sleeve Claude Code has not run on, install creates the config dir and publishes it" {
    setup_declared
    rm -rf "$HOME/.claude" "$HOME/.claude.json"
    run claude_install
    assert_success
    [ -d "$CONFIG" ]
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    [ ! -e "$HOME/.claude" ]
    [ -z "$(ls -d "$CONFIG".molt-backup.* 2>/dev/null)" ]
}

# AC011, and hv's ruling that nothing anti-brew is rendered (WP01 4b).
@test "the GUI file is a LaunchAgent on macOS and an environment.d file on Linux, and nothing published names Molt's checkout" {
    setup_moved
    eval 'molt_platform() { echo macos; }'
    run claude_install
    assert_success
    local plist="$HOME/Library/LaunchAgents/com.molt.claude-config-dir.plist"
    grep -qF "<string>com.molt.claude-config-dir</string>" "$plist"
    grep -qF "<string>setenv</string>" "$plist"
    grep -qF "<string>$CONFIG</string>" "$plist"
    if command -v plutil >/dev/null; then
        plutil -lint "$plist"
    fi
    eval 'molt_platform() { echo linux; }'
    run claude_install
    assert_success
    grep -qxF "CLAUDE_CONFIG_DIR=$CONFIG" "$HOME/.config/environment.d/claude.conf"
    run grep -lF "$MOLT_ROOT" "$HOME/.config/molt/env.sh" "$HOME/.config/molt/claude-home-guard.sh" \
        "$plist" "$HOME/.config/environment.d/claude.conf"
    assert_failure
    [ -z "$output" ]
}

# --- ST0006: the home guard ---

# AC003
@test "the home guard exits 2 with the agent-home message when cwd is \$HOME, and 0 anywhere else" {
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh"
    [ -x "$guard" ]
    run "$guard" <<< "{\"cwd\": \"$HOME\", \"prompt\": \"hello\"}"
    [ "$status" -eq 2 ]
    [ "$output" = "launch from an agent home: molt agent list" ]
    run "$guard" <<< "{\"cwd\": \"$HOME/\", \"prompt\": \"a trailing slash is still home\"}"
    [ "$status" -eq 2 ]
    ln -s "$HOME" "$BATS_TEST_TMPDIR/home-link"
    run "$guard" <<< "{\"cwd\": \"$BATS_TEST_TMPDIR/home-link\"}"
    [ "$status" -eq 2 ]
    mkdir -p "$BATS_TEST_TMPDIR/agt/kovacs-sysadm"
    run "$guard" <<< "{\"cwd\": \"$BATS_TEST_TMPDIR/agt/kovacs-sysadm\", \"prompt\": \"hello\"}"
    assert_success
    [ -z "$output" ]
}

# AC003. Exit 1 blocks nothing, and Claude Code shows what it printed.
@test "the home guard exits 1, saying so, when jq is missing or the input names no cwd" {
    setup_moved
    run claude_install
    assert_success
    local guard="$HOME/.config/molt/claude-home-guard.sh"
    run "$guard" <<< '{"prompt": "no cwd"}'
    [ "$status" -eq 1 ]
    assert_output_contains "the hook input names no cwd"
    run env PATH=/nonexistent "$guard" <<< "{\"cwd\": \"$HOME\"}"
    [ "$status" -eq 1 ]
    assert_output_contains "jq is not on PATH"
}

# AC003
@test "the hook merge adds the guard once, keeps every other key and hook as it was, and a second install writes nothing" {
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

# AC004
@test "check reports CLAUDE_CONFIG_DIR unset where molt runs, or naming another dir, and passes once it names the config dir" {
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
}

# AC004. The sign that a launch path missed the variable.
@test "check reports ~/.claude or ~/.claude.json present while the config dir is elsewhere, whether a directory, a file or a link" {
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

# AC004. The native installer keeps its binary and versions under ~/.local and
# ~/.cache, wherever the config dir is.
@test "the native installer's own paths under ~/.local and ~/.cache are not faults" {
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/claude/versions" "$HOME/.local/state/claude" "$HOME/.cache/claude"
    ln -s "$HOME/.local/share/claude/versions/2.1.306" "$HOME/.local/bin/claude"
    run claude_check
    assert_success
}

# AC004
@test "check and verify report env.sh, the GUI file or the guard missing or stale, and the hook missing from settings.json" {
    setup_moved
    run claude_install
    assert_success
    export CLAUDE_CONFIG_DIR="$CONFIG"
    local gui
    gui="$(gui_file)"
    rm "$HOME/.config/molt/env.sh" "$gui"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/env.sh is missing"
    assert_output_contains "claude: $(molt_tilde "$gui") is missing"
    run claude_install
    assert_success
    echo 'export MOLT_FONT_SIZE=12' >> "$TEST_USER_REPO/instances/$(hostname -s 2>/dev/null || hostname)/vars.sh"
    run claude_check
    assert_failure
    assert_output_contains "claude: ~/.config/molt/env.sh differs from its template or this sleeve's vars.sh"
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

# AC004
@test "check and verify report a move still pending, naming what is in \$HOME" {
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

# AC012
@test "CLAUDE.md and AGENTS.md are linked into the config dir, and a regular file there is backed up first" {
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

# AC012
@test "check and verify report a CLAUDE.md link that is broken" {
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
