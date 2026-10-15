#!/usr/bin/env bats
# claude.bats — claude liberator (keybindings, ccstatusline layout, statusLine)

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
