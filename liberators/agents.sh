#!/usr/bin/env bash
# agents.sh — Liberator: sleeve agents
# Frees a machine's local agent from running in $HOME with nothing to hold its
# role: each [[agent]] entry in the sleeve's molt.toml gets a home under
# MOLT_AGT_DIR, rendered from the role the user repo defines (ST0006). The
# model, and molt agent list|config, are in lib/agent.sh.

# Renders the file $3 of the home of the agent named $1, with the role $2, from
# the template $4, then what follows the render: the overlay $5 appended to
# AGENTS.md, and autoMemoryDirectory set in settings.json, so the agent's memory
# lives in its home and travels with it.
_agents_render_file() {
  local name="$1" role="$2" file="$3" template="$4" extra="$5" home host target tmp
  home="$(molt_agent_home "$name")"
  host="$(molt_hostname)"
  target="$home/$file"
  # In a subshell, so the agent's variables reach molt_render's envsubst and go
  # no further.
  if ! (
    export MOLT_HOSTNAME="$host" MOLT_AGENT_NAME="$name" MOLT_AGENT_ROLE="$role" MOLT_AGENT_HOME="$home"
    molt_render "$template" "$target"
  ); then
    molt_error "agents: $name's $file was not rendered"
    return 1
  fi

  case "$file" in
    AGENTS.md)
      if [[ -n "$extra" && -f "$extra" ]] && ! { printf '\n'; cat "$extra"; } >> "$target"; then
        molt_error "agents: $(molt_tilde "$extra") was not appended to $name's AGENTS.md"
        return 1
      fi
      # The digest covers the overlay too, present or not, so adding, changing
      # or removing one makes the home stale.
      molt_config_record_digest "$target" "$template" ${extra:+"$extra"} ;;
    .claude/settings.json)
      tmp="$(mktemp "${target}.XXXXXX")" || return 1
      if ! jq --arg dir "$home/memory" '.autoMemoryDirectory = $dir' "$target" > "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        # Without its sidecar the file reads as stale, not as rendered.
        rm -f "${target}.molt-rendered"
        molt_error "agents: role $role's settings.json.tmpl does not render to a JSON object, so $name's settings are not usable"
        return 1
      fi
      if ! mv -f "$tmp" "$target"; then
        rm -f "$tmp"
        molt_error "agents: could not set autoMemoryDirectory in $name's settings.json"
        return 1
      fi ;;
  esac
}

# Renders the home of the agent named $1, with the role $2: each file that is
# missing or stale, then memory/ and work/ where they are missing. It does not
# wait for the claude liberator's move: on kovacs the home renders while
# kovacs-sysadm is still live and the move is refused, so it can copy its files
# in before hv runs the move (ST0006).
_agents_render() {
  local name="$1" role="$2" home role_dir file template extra dir
  home="$(molt_agent_home "$name")"
  role_dir="$(molt_agent_role_dir "$role")" || return 1
  if [[ ! -d "$role_dir" ]]; then
    molt_error "agents: $name: role $role is not defined: there is no $(molt_tilde "$role_dir")"
    return 1
  fi
  while IFS=$'\t' read -r file template extra; do
    [[ -n "$file" ]] || continue
    if [[ ! -f "$template" ]]; then
      molt_error "agents: $name: role $role has no $(molt_tilde "$template")"
      return 1
    fi
    if molt_render_stale "$template" "$home/$file" ${extra:+"$extra"}; then
      _agents_render_file "$name" "$role" "$file" "$template" "$extra" || return 1
    fi
  done <<< "$(molt_agent_files "$role")"
  for dir in "${_MOLT_AGENT_DIRS[@]}"; do
    if [[ ! -d "$home/$dir" ]] && ! mkdir -p "$home/$dir"; then
      molt_error "agents: could not create $(molt_tilde "$home/$dir")"
      return 1
    fi
  done
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, everything
# standing between this sleeve's agents and current homes. Returns non-zero
# when it reported anything.
_agents_report_faults() {
  local log="$1" prefix="$2" name role enabled harness ok=0
  molt_report_faults "$log" "$prefix" "molt.toml" "$(molt_agent_manifest_faults)" || ok=1
  while IFS=$'\t' read -r name role enabled harness; do
    [[ -n "$name" && "$enabled" == "true" && "$harness" == "claude" ]] || continue
    molt_report_faults "$log" "$prefix" "$name" "$(molt_agent_faults "$name" "$role")" || ok=1
  done <<< "$(molt_agents)"
  return $ok
}

agents_check() {
  _agents_report_faults molt_info "agents: "
}

agents_install() {
  local name role enabled harness failed=0
  molt_report_faults molt_error "agents: " "molt.toml" "$(molt_agent_manifest_faults)" || failed=1
  while IFS=$'\t' read -r name role enabled harness; do
    [[ -n "$name" && "$enabled" == "true" && "$harness" == "claude" ]] || continue
    _agents_render "$name" "$role" || failed=1
  done <<< "$(molt_agents)"
  if [[ $failed -ne 0 ]]; then
    return 1
  fi
  molt_info "Liberator complete: agents"
}

# Re-renders whatever has gone stale, for molt upgrade.
agents_upgrade() {
  agents_install
}

agents_verify() {
  if _agents_report_faults molt_error "VERIFY FAIL: agents: "; then
    molt_info "Verified: agents liberator is fully operational"
  else
    return 1
  fi
}
