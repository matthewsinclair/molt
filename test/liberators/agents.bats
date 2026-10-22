#!/usr/bin/env bats
# agents.bats — agents liberator and molt agent list|config (ST0006 WP02)

load "../test_helper.bash"

setup_agents() {
    load_liberator agents

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export SLEEVE
    SLEEVE="$(test_hostname)"

    export TEST_USER_REPO="$BATS_TEST_TMPDIR/molt-testuser"
    export ROLE="$TEST_USER_REPO/config/agents/roles/sysadm"
    export INSTANCE="$TEST_USER_REPO/instances/$SLEEVE"
    mkdir -p "$ROLE" "$INSTANCE"
    eval "molt_find_user_repo() { echo \"$TEST_USER_REPO\"; }"
    # The managed settings and the user's, in the test directory: neither the
    # root-owned managed file nor any real config dir is read.
    eval "molt_claude_managed_dir() { echo \"$BATS_TEST_TMPDIR/managed\"; }"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude-config"
    install_fake_sudo
    export FLOOR="$BATS_TEST_TMPDIR/managed/managed-settings.d/molt-sysadm.json"

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
    printf '%s\n' '{' '  "permissions": { "deny": ["Read(~/.ssh/id_*)", "Read(~/.aws/credentials)"] }' '}' > "$ROLE/floor.json"
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

# vc, 21 Oct: text common to every sleeve agent lives in one role-independent
# preamble, and in no role template (AC016).
@test "an agent's AGENTS.md is the preamble, rendered, then the role's contract, then the sleeve's overlay, and a changed preamble makes it stale" {
    # AT060 (ST0006 AC016).
    setup_agents
    mkdir -p "$TEST_USER_REPO/config/agents" "$INSTANCE/agents"
    printf '# Every sleeve agent\n\nYour home is your working directory: %s.\n' '${MOLT_AGENT_HOME}' > "$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    printf 'A VM on ext4.\n' > "$INSTANCE/agents/sysadm.md"
    run agents_install
    assert_success
    [ "$(cat "$AGENT_HOME/AGENTS.md")" = "$(printf '# Every sleeve agent\n\nYour home is your working directory: %s.\n\n# %s\n\nThe sysadm agent for %s, at home in %s.\n\nA VM on ext4.' "$AGENT_HOME" "$NAME" "$SLEEVE" "$AGENT_HOME")" ]
    run agents_check
    assert_success
    echo "Mind the backups." >> "$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/AGENTS.md is stale"
    run agents_install
    assert_success
    grep -qx "Mind the backups." "$AGENT_HOME/AGENTS.md"
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "A VM on ext4." ]
}

@test "with no preamble the role's contract opens AGENTS.md, and a preamble added later goes first with the overlay still last" {
    # AT061 (ST0006 AC016).
    setup_agents
    mkdir -p "$INSTANCE/agents"
    printf 'A VM on ext4.\n' > "$INSTANCE/agents/sysadm.md"
    run agents_install
    assert_success
    [ "$(head -n 1 "$AGENT_HOME/AGENTS.md")" = "# $NAME" ]
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "A VM on ext4." ]
    run agents_check
    assert_success
    mkdir -p "$TEST_USER_REPO/config/agents"
    printf '# Every sleeve agent\n' > "$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $AGENT_HOME/AGENTS.md is stale"
    run agents_install
    assert_success
    [ "$(head -n 1 "$AGENT_HOME/AGENTS.md")" = "# Every sleeve agent" ]
    [ "$(tail -n 1 "$AGENT_HOME/AGENTS.md")" = "A VM on ext4." ]
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

# --- Issue 0030: the home guard's hook in the home ---
#
# A session started without the config dir reads only project settings, so the
# home's settings.json runs the guard too, with the same entry the claude
# liberator writes into the user settings.

# The guard's command, as templates/claude/home-guard-hook.json names it.
GUARD='~/.config/molt/claude-home-guard.sh'

# This sleeve declares its config dir, as hv does sleeve by sleeve.
declare_config_dir() {
    printf 'export MOLT_CLAUDE_CONFIG_DIR="%s"\n' "$HOME/.config/claude" >> "$INSTANCE/vars.sh"
}

@test "on a sleeve that declares its config dir, a home's settings.json runs the home guard once, beside the role's own hooks, however often it renders (issue 0030)" {
    setup_agents
    declare_config_dir
    cat > "$ROLE/settings.json.tmpl" <<'JSON'
{
  "permissions": { "deny": ["Bash(rm -rf:*)"] },
  "hooks": { "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "role-hook.sh" } ] } ] }
}
JSON
    run agents_install
    assert_success
    local settings="$AGENT_HOME/.claude/settings.json"
    [ "$(jq -c '[.hooks.UserPromptSubmit[].hooks[].command]' "$settings")" = "[\"role-hook.sh\",\"$GUARD\"]" ]
    [ "$(jq -r .autoMemoryDirectory "$settings")" = "$AGENT_HOME/memory" ]
    [ "$(jq -c .permissions.deny "$settings")" = '["Bash(rm -rf:*)"]' ]
    run agents_check
    assert_success
    run agents_install
    assert_success
    refute_output_contains "Rendered"
    echo '{"permissions": {}}' > "$ROLE/settings.json.tmpl"
    run agents_install
    assert_success
    [ "$(jq -c '[.hooks.UserPromptSubmit[].hooks[].command]' "$settings")" = "[\"$GUARD\"]" ]
}

@test "on a sleeve that declares no config dir, a home's settings.json runs no home guard, and molt agent config says why (issue 0030)" {
    setup_agents
    run agents_install
    assert_success
    [ "$(jq -c .hooks "$AGENT_HOME/.claude/settings.json")" = null ]
    run cmd_agent config "$NAME"
    assert_success
    assert_output_contains "$(printf '  %-9s %s' guard 'none: this sleeve declares no config dir for Claude Code')"
}

# kovacs and rhadamanth have homes rendered before this change: their digests
# covered the template and vars.sh, neither of which it touches.
@test "a home rendered without the guard's hook on a declaring sleeve, or with the hook taken out by hand, is stale, and install puts the hook in (issue 0030)" {
    setup_agents
    declare_config_dir
    agents_install >/dev/null
    local settings="$AGENT_HOME/.claude/settings.json"
    run cmd_agent config "$NAME"
    assert_output_contains "$(printf '  %-9s %s' guard "$GUARD, which is missing or not executable: the claude liberator publishes it once the move is done")"
    mkdir -p "$HOME/.config/molt"
    printf '#!/bin/sh\nexit 0\n' > "$HOME/.config/molt/claude-home-guard.sh"
    chmod 755 "$HOME/.config/molt/claude-home-guard.sh"
    run cmd_agent config "$NAME"
    assert_output_contains "$(printf '  %-9s %s\n' guard "$GUARD")"
    jq 'del(.hooks)' "$settings" > "$settings.new"
    mv "$settings.new" "$settings"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $settings is stale"
    run cmd_agent config "$NAME"
    assert_output_contains "$(printf '    %-24s %s' .claude/settings.json stale)"
    assert_output_contains "$(printf '  %-9s %s' guard 'missing from .claude/settings.json: re-run molt upgrade')"
    run agents_install
    assert_success
    [ "$(jq -c '[.hooks.UserPromptSubmit[].hooks[].command]' "$settings")" = "[\"$GUARD\"]" ]
    # The guard's command in an entry that is otherwise not the guard's is not
    # the hook, as the claude liberator reads the user settings.
    jq '.hooks.UserPromptSubmit[0].hooks[0].timeout = 1' "$settings" > "$settings.new"
    mv "$settings.new" "$settings"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $settings is stale"
    run agents_install
    assert_success
    [ "$(jq -c '.hooks.UserPromptSubmit[0].hooks[0] | has("timeout")' "$settings")" = false ]
    # The hook in place, and the digest a render before issue 0030 wrote, of
    # the template and vars.sh alone: stale on the digest by itself.
    printf 'digest %s\n' "$(cat "$ROLE/settings.json.tmpl" "$INSTANCE/vars.sh" | shasum -a 256 | awk '{print $1}')" > "$settings.molt-rendered"
    run agents_check
    assert_failure
    assert_output_contains "agents: $NAME: $settings is stale"
    run agents_install
    assert_success
    [ "$(jq -c '[.hooks.UserPromptSubmit[].hooks[].command]' "$settings")" = "[\"$GUARD\"]" ]
    run agents_check
    assert_success
}

# critic-shell, 21 Oct: jq passed an empty render through as nothing and turned
# null into an object, so either read current; two objects would have
# installed the first and dropped the second without a word. The file is built
# whole before it is put in place, so a failed one leaves what was there.
@test "a settings template that does not render to one JSON object, being broken, empty, null or two objects, fails the install and leaves the file as it was: missing on a first install, as last rendered after" {
    # AT035 (ST0006 AC005).
    setup_agents
    local bad
    cp "$ROLE/settings.json.tmpl" "$BATS_TEST_TMPDIR/settings.json.tmpl"
    echo '{"permissions": ' > "$ROLE/settings.json.tmpl"
    run agents_install
    assert_failure
    assert_output_contains "agents: $NAME's settings.json, from role sysadm's settings.json.tmpl, is not usable: the template does not render to one JSON object"
    [ ! -e "$AGENT_HOME/.claude/settings.json" ]
    cp "$BATS_TEST_TMPDIR/settings.json.tmpl" "$ROLE/settings.json.tmpl"
    agents_install >/dev/null
    cp "$AGENT_HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/installed.json"
    for bad in '{"permissions": ' '\n  \n' 'null' '{"permissions": {}}\n{"model": "opus"}'; do
        printf '%b\n' "$bad" > "$ROLE/settings.json.tmpl"
        run agents_install
        assert_failure
        assert_output_contains "is not usable: the template does not render to one JSON object"
        cmp "$BATS_TEST_TMPDIR/installed.json" "$AGENT_HOME/.claude/settings.json"
        run agents_check
        assert_failure
        assert_output_contains "agents: $NAME: $AGENT_HOME/.claude/settings.json is stale"
    done
    [ -z "$(find "$AGENT_HOME" -name '*.molt-tmp*' -o -name '*.molt-backup.*')" ]
}

# critic-shell, 21 Oct: only the claude liberator checked the root, while this
# one, which makes the homes, made them under whatever it was given: a quoted ~
# put them in a directory named ~ wherever molt ran. The root is compared as
# the disk spells it, as the home guard compares it: a spelling of HOME through
# a symlink passed a comparison of spellings, and the guard then refused every
# project.
@test "agents check and install refuse an agents root that is unset, relative, untidy or holds a line break, that reaches HOME or a parent of a project or config root by any spelling, or that is in Claude Code's config dir, and make no home" {
    # AT059 (ST0006 AC005, AC014).
    setup_agents
    local root="$MOLT_AGT_DIR"
    export MOLT_AGT_DIR=""
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR cannot be resolved: MOLT_PRJ_DIR is unset"
    export MOLT_AGT_DIR="~/Devel/agt"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR is not an absolute path (a quoted ~ is not expanded): ~/Devel/agt"
    # Derived, it is named so, and no ~ is blamed.
    export MOLT_PRJ_DIR="Devel/prj" MOLT_AGT_DIR="Devel/agt"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, the agt/ sibling of MOLT_PRJ_DIR Devel/prj, is not an absolute path: Devel/agt"
    unset MOLT_PRJ_DIR
    export MOLT_AGT_DIR="$root/"
    run agents_check
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR is not a canonical path, with no trailing slash, // or . or .. component: $root/"
    export MOLT_AGT_DIR="$root"$'\n'"x"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR holds a line break"
    export MOLT_AGT_DIR=/
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, /, is at or above ~: the home guard would refuse"
    export MOLT_AGT_DIR="$HOME"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, ~, is at or above ~: the home guard would refuse"
    ln -s "$HOME" "$BATS_TEST_TMPDIR/home-link"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/home-link"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, $BATS_TEST_TMPDIR/home-link, is at or above ~: the home guard would refuse"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/Devel/prj" MOLT_AGT_DIR="$BATS_TEST_TMPDIR/Devel"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, $BATS_TEST_TMPDIR/Devel, is at or above $BATS_TEST_TMPDIR/Devel/prj"
    unset MOLT_PRJ_DIR
    export MOLT_CFG_DIR="$BATS_TEST_TMPDIR/Devel/cfg"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, $BATS_TEST_TMPDIR/Devel, is at or above $BATS_TEST_TMPDIR/Devel/cfg"
    unset MOLT_CFG_DIR
    export MOLT_AGT_DIR="$HOME/.claude/agt"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, ~/.claude/agt, is at or under ~/.claude, where Claude Code keeps its state"
    export MOLT_AGT_DIR="$CLAUDE_CONFIG_DIR/agt"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, $CLAUDE_CONFIG_DIR/agt, is at or under $CLAUDE_CONFIG_DIR, where Claude Code keeps its state"
    [ ! -e "$root" ]
    [ ! -e "$BATS_TEST_TMPDIR/~" ]
    [ ! -e "$BATS_TEST_TMPDIR/Devel" ]
    [ ! -e "$HOME/$NAME" ]
    [ ! -e "$HOME/.claude" ]
    [ ! -e "$CLAUDE_CONFIG_DIR" ]
}

# critic-shell, 21 Oct: molt_render_text sources vars.sh with MOLT_AGT_DIR
# exported already, so a plain assignment, a += or an unset there reached the
# guard's envsubst, while the check counted only an export.
@test "agents install refuses a vars.sh that sets, appends to or unsets MOLT_AGT_DIR, or cannot be read, and a declared config dir holding the root, and makes no home" {
    # AT062 (ST0006 AC014).
    setup_agents
    local vars="$INSTANCE/vars.sh" line
    cp "$vars" "$BATS_TEST_TMPDIR/vars.sh"
    for line in "export MOLT_AGT_DIR=$BATS_TEST_TMPDIR/elsewhere" "MOLT_AGT_DIR=$BATS_TEST_TMPDIR/elsewhere"; do
        { cat "$BATS_TEST_TMPDIR/vars.sh"; echo "$line"; } > "$vars"
        run agents_install
        assert_failure
        assert_output_contains "agents: this sleeve's vars.sh sets MOLT_AGT_DIR to $BATS_TEST_TMPDIR/elsewhere, but molt resolves it as $MOLT_AGT_DIR: drop it from vars.sh"
    done
    { cat "$BATS_TEST_TMPDIR/vars.sh"; echo 'MOLT_AGT_DIR+=/sub'; } > "$vars"
    run agents_install
    assert_failure
    assert_output_contains "agents: this sleeve's vars.sh sets MOLT_AGT_DIR to $MOLT_AGT_DIR/sub, but molt resolves it as $MOLT_AGT_DIR"
    { cat "$BATS_TEST_TMPDIR/vars.sh"; echo 'unset MOLT_AGT_DIR'; } > "$vars"
    run agents_install
    assert_failure
    assert_output_contains "agents: this sleeve's vars.sh unsets MOLT_AGT_DIR, empties it or stops exporting it, while molt resolves it as $MOLT_AGT_DIR"
    { cat "$BATS_TEST_TMPDIR/vars.sh"; echo 'if then'; } > "$vars"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR could not be checked against this sleeve's vars.sh: $vars does not parse"
    { cat "$BATS_TEST_TMPDIR/vars.sh"; printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$BATS_TEST_TMPDIR"; } > "$vars"
    run agents_install
    assert_failure
    assert_output_contains "agents: MOLT_AGT_DIR, $MOLT_AGT_DIR, is at or under $BATS_TEST_TMPDIR, the config dir this sleeve declares for Claude Code"
    [ ! -e "$MOLT_AGT_DIR" ]
    [ ! -e "$BATS_TEST_TMPDIR/elsewhere" ]
}

# Runs $@ on a host that gives no name.
on_a_host_with_no_name() {
    molt_hostname() { return 1; }
    "$@"
}

# Runs $@ with the role's files unlisted.
with_role_files_unlisted() {
    molt_agent_files() { return 1; }
    "$@"
}

# critic-shell, 21 Oct: no test went red with these answers taken away.
@test "on a host with no name, or with a role's files unlisted, check, install and molt agent config fail and say which, rather than reading as no agents or no files" {
    # AT063 (ST0006 AC005, AC006).
    setup_agents
    run on_a_host_with_no_name agents_install
    assert_failure
    assert_output_contains "agents: the [[agent]] entries in molt.toml could not be read"
    run on_a_host_with_no_name agents_check
    assert_failure
    assert_output_contains "agents: the [[agent]] entries in molt.toml could not be read"
    run on_a_host_with_no_name cmd_agent config "$NAME"
    assert_failure
    assert_output_contains "molt agent: the [[agent]] entries in molt.toml could not be read"
    [ ! -e "$AGENT_HOME" ]
    agents_install >/dev/null
    run with_role_files_unlisted agents_check
    assert_failure
    assert_output_contains "agents: $NAME: the files of role sysadm cannot be listed"
    run with_role_files_unlisted agents_install
    assert_failure
    assert_output_contains "agents: $NAME: the files of role sysadm cannot be listed"
    run with_role_files_unlisted cmd_agent config "$NAME"
    assert_failure
    assert_output_contains "molt agent: the files of role sysadm cannot be listed"
}

# critic-shell, 21 Oct: AGENTS.md was the role's layer, put in place, and then
# the rest around it, so a layer that failed after it left a live agent's
# contract half-built, and one the || exit missed doubled the preamble.
@test "a layer of AGENTS.md that cannot be rendered fails the install, names it, and leaves AGENTS.md as it was" {
    # AT064 (ST0006 AC016).
    setup_agents
    [ "$(id -u)" -ne 0 ] || skip "root reads a file whatever its mode"
    local preamble="$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    mkdir -p "$TEST_USER_REPO/config/agents" "$INSTANCE/agents"
    printf '# Every sleeve agent\n' > "$preamble"
    printf 'A VM on ext4.\n' > "$INSTANCE/agents/sysadm.md"
    agents_install >/dev/null
    cp "$AGENT_HOME/AGENTS.md" "$BATS_TEST_TMPDIR/AGENTS.md"
    echo "Patch on Tuesdays." >> "$ROLE/AGENTS.md.tmpl"
    chmod 000 "$ROLE/AGENTS.md.tmpl"
    run agents_install
    chmod 644 "$ROLE/AGENTS.md.tmpl"
    assert_failure
    assert_output_contains "agents: $NAME's AGENTS.md was not rendered: $ROLE/AGENTS.md.tmpl could not be rendered"
    cmp "$BATS_TEST_TMPDIR/AGENTS.md" "$AGENT_HOME/AGENTS.md"
    chmod 000 "$preamble"
    run agents_install
    chmod 644 "$preamble"
    assert_failure
    assert_output_contains "agents: $NAME's AGENTS.md was not rendered: $preamble could not be rendered"
    cmp "$BATS_TEST_TMPDIR/AGENTS.md" "$AGENT_HOME/AGENTS.md"
    chmod 000 "$INSTANCE/agents/sysadm.md"
    run agents_install
    chmod 644 "$INSTANCE/agents/sysadm.md"
    assert_failure
    assert_output_contains "agents: $NAME's AGENTS.md was not rendered: $INSTANCE/agents/sysadm.md could not be put after it"
    cmp "$BATS_TEST_TMPDIR/AGENTS.md" "$AGENT_HOME/AGENTS.md"
    [ -z "$(find "$AGENT_HOME" -name '*.molt-tmp*' -o -name '*.molt-before' -o -name '*.molt-joined')" ]
    run agents_install
    assert_success
    [ "$(grep -c '^# Every sleeve agent$' "$AGENT_HOME/AGENTS.md")" -eq 1 ]
    grep -qx "Patch on Tuesdays." "$AGENT_HOME/AGENTS.md"
}

# critic-shell, 21 Oct: molt_render kept what was above the marker, the
# preamble now among it, and the preamble was then put ahead again: 2, 3, then
# 4 copies.
@test "a role whose contract carries @@MOLT:BEGIN@@ keeps one copy of the preamble however often its home renders" {
    # AT066 (ST0006 AC016).
    setup_agents
    mkdir -p "$TEST_USER_REPO/config/agents"
    printf '# Every sleeve agent\n' > "$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    { echo '# @@MOLT:BEGIN@@ managed by molt'; cat "$ROLE/AGENTS.md.tmpl"; } > "$BATS_TEST_TMPDIR/role.tmpl"
    mv "$BATS_TEST_TMPDIR/role.tmpl" "$ROLE/AGENTS.md.tmpl"
    local size
    for size in 11 12 13; do
        echo "export MOLT_FONT_SIZE=$size" > "$INSTANCE/vars.sh"
        run agents_install
        assert_success
        assert_output_contains "Rendered: $ROLE/AGENTS.md.tmpl -> $AGENT_HOME/AGENTS.md"
        refute_output_contains "are not kept"
    done
    [ "$(grep -c '^# Every sleeve agent$' "$AGENT_HOME/AGENTS.md")" -eq 1 ]
    [ "$(head -n 1 "$AGENT_HOME/AGENTS.md")" = "# Every sleeve agent" ]
}

# critic-shell, 21 Oct: molt_render compared the bare role layer with the whole
# AGENTS.md, and the rendered settings.json with the one jq had since given its
# memory dir, so each re-render backed both up and warned of a change, and a
# real hand edit hid among the false ones. A file is backed up whenever it
# differs from what molt would write, so a hand edit is.
@test "a re-render that would write a home's files as they are backs nothing up, with a preamble, an overlay and settings.json's memory dir in place, and one over a hand edit backs the edit up" {
    # AT067 (ST0006 AC005, AC016).
    setup_agents
    mkdir -p "$TEST_USER_REPO/config/agents" "$INSTANCE/agents"
    printf '# Every sleeve agent\n' > "$TEST_USER_REPO/config/agents/AGENTS.md.tmpl"
    printf 'A VM on ext4.\n' > "$INSTANCE/agents/sysadm.md"
    agents_install >/dev/null
    echo 'export MOLT_FONT_SIZE=13' > "$INSTANCE/vars.sh"
    run agents_install
    assert_success
    assert_output_contains "Rendered: $ROLE/AGENTS.md.tmpl -> $AGENT_HOME/AGENTS.md"
    assert_output_contains "Rendered: $ROLE/settings.json.tmpl -> $AGENT_HOME/.claude/settings.json"
    refute_output_contains "backing up"
    [ -z "$(find "$AGENT_HOME" -name '*.molt-backup.*')" ]
    run agents_check
    assert_success
    echo "A note of the agent's own." >> "$AGENT_HOME/AGENTS.md"
    echo 'export MOLT_FONT_SIZE=14' > "$INSTANCE/vars.sh"
    run agents_install
    assert_success
    assert_output_contains "Rendered file changed since last render, backing up: $AGENT_HOME/AGENTS.md -> $AGENT_HOME/AGENTS.md.molt-backup."
    [ "$(find "$AGENT_HOME" -name '*.molt-backup.*' | wc -l | tr -d ' ')" = 1 ]
    grep -qx "A note of the agent's own." "$AGENT_HOME"/AGENTS.md.molt-backup.*
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
    declare_config_dir
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
        deny "Read(~/.ssh/id_*)" managed \
        deny "Read(~/.aws/credentials)" managed \
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

# --- The managed floor (WP06) ---

# An ops role, the sysadm role's files under another name, so a sleeve can have
# an agent and no sysadm.
_ops_role() {
    mkdir -p "$TEST_USER_REPO/config/agents/roles/ops"
    cp "$ROLE/AGENTS.md.tmpl" "$ROLE/settings.json.tmpl" "$TEST_USER_REPO/config/agents/roles/ops/"
}

@test "agents install renders floor.json's bytes as the managed drop-in through sudo, mode 644, with molt's sidecar, and a second run writes nothing" {
    # AT068 (ST0006 AC010).
    setup_agents
    declare_config_dir
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: $FLOOR is missing"
    run agents_install
    assert_success
    assert_output_contains "Rendered: $ROLE/floor.json -> $FLOOR"
    cmp "$ROLE/floor.json" "$FLOOR"
    [ "$(test_file_mode "$FLOOR")" = 644 ]
    [ "$(test_file_mode "$FLOOR.molt-rendered")" = 644 ]
    grep -q "^digest " "$FLOOR.molt-rendered"
    grep -q "^sudo install -m 644 .* $FLOOR\$" "$BATS_TEST_TMPDIR/sudo.log"
    run agents_check
    assert_success
    rm -f "$BATS_TEST_TMPDIR/sudo.log"
    run agents_install
    assert_success
    refute_output_contains "molt-sysadm.json"
    [ ! -e "$BATS_TEST_TMPDIR/sudo.log" ]

    printf '{"permissions": {"deny": ["Read(~/.ssh/id_*)"]}}\n' > "$ROLE/floor.json"
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: $FLOOR is not $ROLE/floor.json"
    run agents_install
    assert_success
    cmp "$ROLE/floor.json" "$FLOOR"

    # A drop-in that cannot be read is named, not taken for a stale one.
    chmod 000 "$FLOOR"
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: $FLOOR could not be compared with $ROLE/floor.json"
    run agents_install
    assert_failure
    assert_output_contains "$FLOOR could not be compared with $ROLE/floor.json, so nothing was written"
    chmod 644 "$FLOOR"
}

@test "molt agent config shows the floor's rules tagged managed above the user layer where it is, and no managed rule where it is not" {
    # AT069 (ST0006 AC010).
    setup_agents
    declare_config_dir
    agents_install >/dev/null
    mkdir -p "$CLAUDE_CONFIG_DIR"
    echo '{"permissions": {"deny": ["Bash(curl:*)"]}}' > "$CLAUDE_CONFIG_DIR/settings.json"
    run cmd_agent config "$NAME"
    assert_success
    assert_output_contains "$(printf '    %-8s %s' managed "$FLOOR")"
    assert_output_contains "$(permission_line deny "Read(~/.ssh/id_*)" managed)"
    assert_output_contains "$(permission_line deny "Read(~/.aws/credentials)" managed)"
    [ "$(printf '%s\n' "$output" | grep -n 'Read(~/.aws/credentials)' | cut -d: -f1)" -lt \
      "$(printf '%s\n' "$output" | grep -n 'Bash(curl:\*)' | cut -d: -f1)" ]

    _ops_role
    write_manifest '[[agent]]' 'role = "ops"'
    agents_install >/dev/null
    run cmd_agent config "$SLEEVE-ops"
    assert_success
    run grep -c managed <<< "$(printf '%s\n' "$output" | grep -E '^    (deny|ask|allow) ')"
    [ "$output" = 0 ]
}

@test "with no enabled sysadm agent, or no declared config dir, install renders no floor and removes molt's, and leaves, naming it, one molt did not write" {
    # AT070 (ST0006 AC017).
    setup_agents
    local vars="$INSTANCE/vars.sh"
    cp "$vars" "$BATS_TEST_TMPDIR/vars.sh"
    # A sysadm agent on a sleeve that declares no config dir gets no floor.
    run agents_install
    assert_success
    [ ! -e "$FLOOR" ]
    declare_config_dir
    agents_install >/dev/null
    [ -f "$FLOOR.molt-rendered" ]
    # A vars.sh that cannot be read is a failure, not a sleeve with no floor:
    # molt's floor stays.
    echo 'if then' >> "$vars"
    run molt_agent_floor_state
    assert_failure
    assert_output_contains "MOLT_CLAUDE_CONFIG_DIR could not be read: $vars does not parse"
    run agents_install
    assert_failure
    [ -f "$FLOOR" ]
    [ -f "$FLOOR.molt-rendered" ]
    cp "$BATS_TEST_TMPDIR/vars.sh" "$vars"
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: $FLOOR is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR"
    run agents_install
    assert_success
    assert_output_contains "Removed the managed floor: $FLOOR"
    [ ! -e "$FLOOR" ]
    [ ! -e "$FLOOR.molt-rendered" ]

    declare_config_dir
    _ops_role
    write_manifest '[[agent]]' 'role = "ops"'
    run agents_install
    assert_success
    [ ! -e "$FLOOR" ]

    write_manifest '[[agent]]' 'role = "sysadm"'
    agents_install >/dev/null
    write_manifest '[[agent]]' 'role = "sysadm"' 'enabled = false' '' '[[agent]]' 'role = "ops"'
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: $FLOOR is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR"
    run agents_install
    assert_success
    assert_output_contains "Removed the managed floor: $FLOOR"
    [ ! -e "$FLOOR" ]
    [ ! -e "$FLOOR.molt-rendered" ]

    echo '{"permissions": {"deny": ["Bash(theirs)"]}}' > "$FLOOR"
    run agents_check
    assert_success
    run agents_install
    assert_success
    assert_output_contains "agents: managed floor: $FLOOR was not written by molt, which leaves it"
    [ "$(cat "$FLOOR")" = '{"permissions": {"deny": ["Bash(theirs)"]}}' ]

    # Nor is one molt did not write replaced where the floor is wanted.
    write_manifest '[[agent]]' 'role = "sysadm"'
    run agents_install
    assert_failure
    assert_output_contains "$FLOOR was not written by molt, which leaves it, so the floor is not in place"
    [ "$(cat "$FLOOR")" = '{"permissions": {"deny": ["Bash(theirs)"]}}' ]
}

@test "a sysadm sleeve with no floor.json, or one that is not one object holding only permissions.deny, fails check and install naming it, and nothing is written" {
    # AT071 (ST0006 AC018).
    setup_agents
    declare_config_dir
    local bad
    rm "$ROLE/floor.json"
    run agents_check
    assert_failure
    assert_output_contains "agents: managed floor: a sysadm agent needs its managed floor, and there is no $ROLE/floor.json"
    run agents_install
    assert_failure
    assert_output_contains "there is no $ROLE/floor.json, so nothing was written"
    [ ! -e "$AGENT_HOME" ]
    [ ! -e "$BATS_TEST_TMPDIR/managed" ]
    for bad in '' '[]' '"deny"' '{"permissions": {"deny": ["Read(x)"]}} {}' \
        '{"permissions": {"deny": ["Read(x)"], "allow": ["Bash(y)"]}}' \
        '{"permissions": {"deny": [1]}}' '{"permissions": {"deny": "Read(x)"}}' \
        '{"permissions": {"deny": []}, "model": "opus"}'; do
        printf '%s\n' "$bad" > "$ROLE/floor.json"
        run agents_check
        assert_failure
        assert_output_contains "agents: managed floor: $ROLE/floor.json is not one object holding only permissions.deny, a list of strings"
        run agents_install
        assert_failure
        [ ! -e "$AGENT_HOME" ]
        [ ! -e "$BATS_TEST_TMPDIR/managed" ]
    done
}
