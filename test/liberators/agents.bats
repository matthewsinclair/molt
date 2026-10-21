#!/usr/bin/env bats
# agents.bats — agents liberator and molt agent list|config (ST0006 WP02)

load "../test_helper.bash"

setup_agents() {
    load_liberator agents

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export SLEEVE
    SLEEVE="$(hostname -s 2>/dev/null || hostname)"

    export TEST_USER_REPO="$BATS_TEST_TMPDIR/molt-testuser"
    export ROLE="$TEST_USER_REPO/config/agents/roles/sysadm"
    export INSTANCE="$TEST_USER_REPO/instances/$SLEEVE"
    mkdir -p "$ROLE" "$INSTANCE"
    eval "molt_find_user_repo() { echo \"$TEST_USER_REPO\"; }"
    # The managed settings and the user's, in the test directory: neither the
    # root-owned managed file nor any real config dir is read.
    eval "molt_claude_managed_dir() { echo \"$BATS_TEST_TMPDIR/managed\"; }"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude-config"

    cat > "$ROLE/AGENTS.md.tmpl" <<'EOF'
# ${MOLT_AGENT_NAME}

The ${MOLT_AGENT_ROLE} agent for ${MOLT_HOSTNAME}, at home in ${MOLT_AGENT_HOME}.
EOF
    cat > "$ROLE/settings.json.tmpl" <<'EOF'
{
  "permissions": { "allow": ["Bash(uptime)"], "deny": ["Bash(rm -rf:*)"] }
}
EOF
    # No MOLT_HOSTNAME here: the liberator exports it, so a sleeve whose vars.sh
    # does not declare it renders its name all the same.
    echo 'export MOLT_FONT_SIZE=12' > "$INSTANCE/vars.sh"
    write_manifest '[[agent]]' 'role = "sysadm"'

    export NAME="$SLEEVE-sysadm"
    export AGENT_HOME="$MOLT_AGT_DIR/$NAME"
}

# This sleeve's molt.toml, holding the lines given after its [stack] table.
write_manifest() {
    printf '%s\n' '[stack]' 'name = "test-stack"' '' "$@" > "$INSTANCE/molt.toml"
}

# A line of molt agent config's permissions, as it prints them.
permission_line() {
    printf '    %-6s %-44s %s' "$1" "$2" "$3"
}

# --- The home (AC005) ---

@test "an enabled [[agent]] gets its home: AGENTS.md from the role, CLAUDE.md importing it, settings.json with its memory in the home, memory/ and work/" {
    # AT028 (ST0006 AC005).
    setup_agents
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/AGENTS.md is missing"
    run agents_install
    assert_success
    assert_output_contains "Rendered: $ROLE/AGENTS.md.tmpl -> $AGENT_HOME/AGENTS.md"
    assert_output_contains "Rendered: $MOLT_ROOT/templates/agents/CLAUDE.md.tmpl -> $AGENT_HOME/CLAUDE.md"
    assert_output_contains "Rendered: $ROLE/settings.json.tmpl -> $AGENT_HOME/.claude/settings.json"
    [ "$(cat "$AGENT_HOME/AGENTS.md")" = "$(printf '# %s\n\nThe sysadm agent for %s, at home in %s.' "$NAME" "$SLEEVE" "$AGENT_HOME")" ]
    [ "$(cat "$AGENT_HOME/CLAUDE.md")" = "@AGENTS.md" ]
    [ "$(jq -r .autoMemoryDirectory "$AGENT_HOME/.claude/settings.json")" = "$AGENT_HOME/memory" ]
    [ "$(jq -c .permissions.deny "$AGENT_HOME/.claude/settings.json")" = '["Bash(rm -rf:*)"]' ]
    [ -d "$AGENT_HOME/memory" ]
    [ -d "$AGENT_HOME/work" ]
    run agents_check
    assert_success
    run agents_verify
    assert_success
}

@test "re-rendering while every digest matches writes nothing, and memory/ and work/ stay the agent's" {
    # AT029 (ST0006 AC005).
    setup_agents
    agents_install >/dev/null
    echo "remembered" > "$AGENT_HOME/memory/MEMORY.md"
    echo "draft" > "$AGENT_HOME/work/notes.md"
    run agents_install
    assert_success
    refute_output_contains "Rendered"
    [ -z "$(find "$AGENT_HOME" -name '*.molt-backup.*')" ]
    [ "$(cat "$AGENT_HOME/memory/MEMORY.md")" = "remembered" ]
    [ "$(cat "$AGENT_HOME/work/notes.md")" = "draft" ]
}

@test "a changed role template makes the home stale, and install renders it again" {
    # AT030 (ST0006 AC005).
    setup_agents
    agents_install >/dev/null
    echo "Patch on Tuesdays." >> "$ROLE/AGENTS.md.tmpl"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/AGENTS.md is stale"
    run agents_install
    assert_success
    grep -qx "Patch on Tuesdays." "$AGENT_HOME/AGENTS.md"
    run agents_check
    assert_success
}

# kovacs-sysadm: the role's template is one file for every host, so a fact true
# of one machine needs a place of its own.
@test "the sleeve's overlay follows the role's contract in AGENTS.md, and adding or changing it makes the home stale" {
    # AT031 (ST0006 AC005).
    setup_agents
    agents_install >/dev/null
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "The sysadm agent for $SLEEVE, at home in $AGENT_HOME." ]
    mkdir -p "$INSTANCE/agents"
    printf '## This sleeve\n\nA VM on ext4; the Mac is at ~/mac.\n' > "$INSTANCE/agents/sysadm.md"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/AGENTS.md is stale"
    run agents_install
    assert_success
    grep -qx "# $NAME" "$AGENT_HOME/AGENTS.md"
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "A VM on ext4; the Mac is at ~/mac." ]
    run agents_check
    assert_success
    echo "Kernel 6.8." >> "$INSTANCE/agents/sysadm.md"
    run agents_check
    assert_failure
    assert_output_contains "AGENTS.md is stale"
    run agents_install
    assert_success
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "Kernel 6.8." ]
}

@test "a role the user repo does not define is a fault naming the role and where it was looked for" {
    # AT032 (ST0006 AC005).
    setup_agents
    write_manifest '[[agent]]' 'role = "ops"'
    run agents_check
    assert_failure
    assert_output_contains "agents: $SLEEVE-ops: role ops is not defined: there is no $TEST_USER_REPO/config/agents/roles/ops"
    run agents_install
    assert_failure
    assert_output_contains "role ops is not defined"
    [ ! -e "$MOLT_AGT_DIR/$SLEEVE-ops" ]
}

@test "an agent that is not enabled is not rendered" {
    # AT033 (ST0006 AC005).
    setup_agents
    write_manifest '[[agent]]' 'role = "sysadm"' 'enabled = false'
    run agents_check
    assert_success
    run agents_install
    assert_success
    [ ! -e "$AGENT_HOME" ]
}

# kovacs-sysadm H2: the first upgrade renders the home while the agent is still
# live from $HOME, so it can copy its files in before hv runs the move.
@test "a home renders while Claude Code's state is still in \$HOME, waiting on nothing the claude liberator does" {
    # AT034 (ST0006 AC005).
    setup_agents
    # Before the move nothing has published CLAUDE_CONFIG_DIR.
    unset CLAUDE_CONFIG_DIR
    printf 'export MOLT_CLAUDE_CONFIG_DIR="%s"\n' "$HOME/.config/claude" >> "$INSTANCE/vars.sh"
    mkdir -p "$HOME/.claude"
    echo '{}' > "$HOME/.claude.json"
    run agents_install
    assert_success
    [ -f "$AGENT_HOME/AGENTS.md" ]
    [ -d "$HOME/.claude" ]
    [ ! -e "$HOME/.config/claude" ]
}

# critic-shell, 21 Oct: jq passed an empty render through as nothing and turned
# null into an object, so either read current.
@test "a settings template that does not render to one JSON object, being broken, empty or null, fails the install and leaves the file reading stale" {
    # AT035 (ST0006 AC005).
    setup_agents
    echo '{"permissions": ' > "$ROLE/settings.json.tmpl"
    run agents_install
    assert_failure
    assert_output_contains "agents: $NAME's settings.json, from role sysadm's settings.json.tmpl, is not usable: the template does not render to one JSON object"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/.claude/settings.json is stale"
    printf '\n  \n' > "$ROLE/settings.json.tmpl"
    run agents_install
    assert_failure
    assert_output_contains "is not usable: the template does not render to one JSON object"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/.claude/settings.json is stale"
    echo 'null' > "$ROLE/settings.json.tmpl"
    run agents_install
    assert_failure
    assert_output_contains "is not usable: the template does not render to one JSON object"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/.claude/settings.json is stale"
}

# --- molt agent (AC006) ---

@test "molt agent list names every declared agent with its role, whether enabled, the state of its home, and the home" {
    # AT036 (ST0006 AC006).
    setup_agents
    write_manifest '[[agent]]' 'role = "sysadm"' '' '[[agent]]' 'role = "ops"' 'enabled = false'
    agents_install >/dev/null
    run cmd_agent list
    assert_success
    assert_output_contains "$(printf '%-28s %-8s %-8s %-14s %s' "$NAME" sysadm true current "$AGENT_HOME")"
    assert_output_contains "$(printf '%-28s %-8s %-8s %-14s %s' "$SLEEVE-ops" ops false "role undefined" "$MOLT_AGT_DIR/$SLEEVE-ops")"
    echo "Patch on Tuesdays." >> "$ROLE/AGENTS.md.tmpl"
    run cmd_agent list
    assert_success
    assert_output_contains "$(printf '%-28s %-8s %-8s %-14s %s' "$NAME" sysadm true stale "$AGENT_HOME")"
}

# The three layers the contract names, the home's settings.local.json, where
# Claude Code records what was approved in the home, and managed drop-ins.
@test "the permissions in effect are every rule from every layer, deny first, each tagged with its layer" {
    # AT037 (ST0006 AC006).
    setup_agents
    agents_install >/dev/null
    mkdir -p "$BATS_TEST_TMPDIR/managed/managed-settings.d" "$CLAUDE_CONFIG_DIR"
    echo '{"permissions": {"deny": ["Bash(sudo rm:*)"]}}' > "$BATS_TEST_TMPDIR/managed/managed-settings.json"
    echo '{"permissions": {"deny": ["Edit(/etc/**)"]}}' > "$BATS_TEST_TMPDIR/managed/managed-settings.d/50-sysadm.json"
    echo '{"permissions": {"allow": ["Bash(git status)"], "ask": ["Bash(git push:*)"]}, "model": "opus"}' > "$CLAUDE_CONFIG_DIR/settings.json"
    echo '{"permissions": {"allow": ["Bash(systemctl status:*)"]}}' > "$AGENT_HOME/.claude/settings.local.json"
    run molt_agent_permissions "$AGENT_HOME"
    assert_success
    [ "$output" = "$(printf '%s\t%s\t%s\n' \
        deny "Bash(sudo rm:*)" managed \
        deny "Edit(/etc/**)" managed \
        deny "Bash(rm -rf:*)" home \
        ask "Bash(git push:*)" user \
        allow "Bash(systemctl status:*)" local \
        allow "Bash(uptime)" home \
        allow "Bash(git status)" user)" ]
}

@test "molt agent config prints the role, the home, each file's state, the settings it read, and the tagged rules" {
    # AT038 (ST0006 AC006).
    setup_agents
    agents_install >/dev/null
    mkdir -p "$CLAUDE_CONFIG_DIR"
    echo '{"permissions": {"ask": ["Bash(git push:*)"]}}' > "$CLAUDE_CONFIG_DIR/settings.json"
    echo "Patch on Tuesdays." >> "$ROLE/AGENTS.md.tmpl"
    run cmd_agent config "$NAME"
    assert_success
    assert_output_contains "$NAME"
    assert_output_contains "$(printf '  %-9s %s' role sysadm)"
    assert_output_contains "$(printf '  %-9s %s' home "$AGENT_HOME")"
    assert_output_contains "$(printf '    %-24s %s' AGENTS.md stale)"
    assert_output_contains "$(printf '    %-24s %s' CLAUDE.md current)"
    assert_output_contains "$(printf '    %-24s %s' .claude/settings.json current)"
    assert_output_contains "$(printf '    %-8s %s (absent)' managed "$BATS_TEST_TMPDIR/managed/managed-settings.json")"
    assert_output_contains "$(printf '    %-8s %s' user "$CLAUDE_CONFIG_DIR/settings.json")"
    assert_output_contains "$(permission_line deny "Bash(rm -rf:*)" home)"
    assert_output_contains "$(permission_line ask "Bash(git push:*)" user)"
    assert_output_contains "$(permission_line allow "Bash(uptime)" home)"
}

@test "molt agent config fails on an undeclared name, listing the declared ones" {
    # AT039 (ST0006 AC006).
    setup_agents
    write_manifest '[[agent]]' 'role = "sysadm"' '' '[[agent]]' 'role = "ops"'
    run cmd_agent config kovacs-docs
    assert_failure
    assert_output_contains "kovacs-docs is not declared on this sleeve; declared: $SLEEVE-sysadm, $SLEEVE-ops"
}

@test "molt agent config fails, naming the file, when a settings layer is not JSON" {
    # AT040 (ST0006 AC006).
    setup_agents
    agents_install >/dev/null
    mkdir -p "$CLAUDE_CONFIG_DIR"
    printf '{"permissions": ' > "$CLAUDE_CONFIG_DIR/settings.json"
    run cmd_agent config "$NAME"
    assert_failure
    assert_output_contains "$CLAUDE_CONFIG_DIR/settings.json cannot be read as Claude Code settings"
}

# critic-shell, 21 Oct: every other molt agent test calls cmd_agent in the
# test's own shell; this one runs bin/molt, as hv does. It stops short of
# molt agent config on a declared agent, which reads this machine's managed
# settings.
@test "molt agent list and molt agent config run through bin/molt" {
    # AT047 (ST0006 AC006).
    setup_agents
    agents_install >/dev/null
    mkdir -p "$BATS_TEST_TMPDIR/cfg"
    ln -s "$TEST_USER_REPO" "$BATS_TEST_TMPDIR/cfg/Molt-$(whoami)"
    run env -u MOLT_PRJ_DIR HOME="$HOME" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" molt agent list
    assert_success
    assert_output_contains "$(printf '%-28s %-8s %-8s %-14s %s' "$NAME" sysadm true current "$AGENT_HOME")"
    run env -u MOLT_PRJ_DIR HOME="$HOME" MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg" molt agent config kovacs-docs
    assert_failure
    assert_output_contains "kovacs-docs is not declared on this sleeve; declared: $NAME"
}
