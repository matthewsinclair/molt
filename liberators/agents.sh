#!/usr/bin/env bash
# agents.sh — Liberator: sleeve agents
# Frees a machine's local agent from running in $HOME with nothing to hold its
# role: each [[agent]] entry in the sleeve's molt.toml gets a home under
# MOLT_AGT_DIR, rendered from the role the user repo defines (ST0006). The
# model, and molt agent list|config, are in lib/agent.sh.

# Sets autoMemoryDirectory to $2 in the rendered settings.json $1, which must
# hold one JSON object: jq passes an empty render through as nothing and turns
# null into an object, and either would leave settings that read current but
# are not the role's. Fails, printing why instead, with $1 as it was.
_agents_memory_dir_set() {
  local target="$1" dir="$2" tmp
  if ! command -v jq &>/dev/null; then
    echo "jq is not installed"
    return 1
  fi
  if ! tmp="$(mktemp "${target}.XXXXXX")"; then
    echo "no temporary file could be made beside it"
    return 1
  fi
  if ! jq -s --arg dir "$dir" \
      'if length == 1 and (.[0] | type) == "object" then .[0] | .autoMemoryDirectory = $dir else error("not one JSON object") end' \
      "$target" > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    echo "the template does not render to one JSON object"
    return 1
  fi
  if ! mv -f "$tmp" "$target"; then
    rm -f "$tmp"
    echo "it could not be replaced"
    return 1
  fi
}

# Puts the template $1, rendered as molt_render renders, ahead of the file $2,
# a blank line between. Fails, saying why, with $2 as it was.
_agents_prepend() {
  local template="$1" target="$2" why
  if ! why="$(molt_render_text "$template" "${target}.molt-before")"; then
    molt_error "agents: could not render $(molt_tilde "$template")${why:+: $why}"
    return 1
  fi
  if ! { cat "${target}.molt-before" && printf '\n' && cat "$target"; } > "${target}.molt-joined" \
      || ! mv -f "${target}.molt-joined" "$target"; then
    rm -f "${target}.molt-before" "${target}.molt-joined"
    molt_error "agents: could not put $(molt_tilde "$template") ahead of $(molt_tilde "$target")"
    return 1
  fi
  rm -f "${target}.molt-before"
}

# Renders the file $3 of the home of the agent named $1, with the role $2, from
# the template $4, with what goes around it: the template $5 rendered and put
# ahead of it, the file $6 appended after it, and autoMemoryDirectory set in
# settings.json, so the agent's memory lives in its home and travels with it.
_agents_render_file() {
  local name="$1" role="$2" file="$3" template="$4" before="$5" after="$6" home host target why
  home="$(molt_agent_home "$name")"
  if ! host="$(molt_hostname)"; then
    molt_error "agents: this host gives no name, so $name's $file was not rendered"
    return 1
  fi
  target="$home/$file"
  # In a subshell, so the agent's variables reach molt_render's envsubst and go
  # no further.
  if ! (
    export MOLT_HOSTNAME="$host" MOLT_AGENT_NAME="$name" MOLT_AGENT_ROLE="$role" MOLT_AGENT_HOME="$home"
    molt_render "$template" "$target" || exit
    if [[ -n "$before" && -f "$before" ]]; then
      _agents_prepend "$before" "$target"
    fi
  ); then
    molt_error "agents: $name's $file was not rendered"
    return 1
  fi

  if [[ -n "$after" && -f "$after" ]] && ! { printf '\n'; cat "$after"; } >> "$target"; then
    molt_error "agents: $(molt_tilde "$after") was not appended to $name's $file"
    return 1
  fi
  if [[ -n "$before" || -n "$after" ]]; then
    # The digest covers what went around the template, present or not.
    molt_config_record_digest "$target" "$template" ${before:+"$before"} ${after:+"$after"}
  fi

  case "$file" in
    .claude/settings.json)
      if ! why="$(_agents_memory_dir_set "$target" "$home/memory")"; then
        # Without its sidecar the file reads as stale, not as rendered, and the
        # next install renders it again.
        rm -f "${target}.molt-rendered"
        molt_error "agents: $name's settings.json, from role $role's settings.json.tmpl, is not usable: $why"
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
  local name="$1" role="$2" home fault files file template before after dir
  home="$(molt_agent_home "$name")"
  fault="$(molt_agent_role_fault "$role")"
  if [[ -n "$fault" ]]; then
    molt_error "agents: $name: $fault"
    return 1
  fi
  if ! files="$(molt_agent_files "$role")"; then
    molt_error "agents: $name: the files of role $role cannot be listed"
    return 1
  fi
  while IFS=$'\t' read -r file template before after; do
    [[ -n "$file" ]] || continue
    if [[ ! -f "$template" ]]; then
      molt_error "agents: $name: role $role has no $(molt_tilde "$template")"
      return 1
    fi
    if molt_render_stale "$template" "$home/$file" ${before:+"$before"} ${after:+"$after"}; then
      _agents_render_file "$name" "$role" "$file" "$template" "$before" "$after" || return 1
    fi
  done <<< "$files"
  for dir in "${_MOLT_AGENT_DIRS[@]}"; do
    if [[ ! -d "$home/$dir" ]] && ! mkdir -p "$home/$dir"; then
      molt_error "agents: could not create $(molt_tilde "$home/$dir")"
      return 1
    fi
  done
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, everything
# standing between this sleeve's agents and current homes. Returns non-zero
# when it reported anything. An agents root that cannot hold homes is the whole
# answer for a sleeve with agents to home.
_agents_report_faults() {
  local log="$1" prefix="$2" agents fault name role ok=0
  molt_report_faults "$log" "$prefix" "molt.toml" "$(molt_agent_manifest_faults)" || ok=1
  if ! agents="$(molt_homed_agents)"; then
    "$log" "${prefix}the [[agent]] entries in molt.toml could not be read"
    return 1
  fi
  fault="$(molt_agt_dir_fault)"
  if [[ -n "$agents" && -n "$fault" ]]; then
    "$log" "${prefix}$fault"
    return 1
  fi
  while IFS=$'\t' read -r name role; do
    [[ -n "$name" ]] || continue
    molt_report_faults "$log" "$prefix" "$name" "$(molt_agent_faults "$name" "$role")" || ok=1
  done <<< "$agents"
  return $ok
}

agents_check() {
  _agents_report_faults molt_info "agents: "
}

agents_install() {
  local agents fault name role failed=0
  molt_report_faults molt_error "agents: " "molt.toml" "$(molt_agent_manifest_faults)" || failed=1
  if ! agents="$(molt_homed_agents)"; then
    molt_error "agents: the [[agent]] entries in molt.toml could not be read"
    return 1
  fi
  # No home is made under a root that cannot hold one.
  fault="$(molt_agt_dir_fault)"
  if [[ -n "$agents" && -n "$fault" ]]; then
    molt_error "agents: $fault"
    return 1
  fi
  while IFS=$'\t' read -r name role; do
    [[ -n "$name" ]] || continue
    _agents_render "$name" "$role" || failed=1
  done <<< "$agents"
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
