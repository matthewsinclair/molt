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

# Renders the file $3 of the home of the agent named $1, with the role $2, from
# the template $4, then what follows the render: the overlay $5 appended to
# AGENTS.md, and autoMemoryDirectory set in settings.json, so the agent's memory
# lives in its home and travels with it.
_agents_render_file() {
  local name="$1" role="$2" file="$3" template="$4" extra="$5" home host target why
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
  local name="$1" role="$2" home fault file template extra dir
  home="$(molt_agent_home "$name")"
  fault="$(molt_agent_role_fault "$role")"
  if [[ -n "$fault" ]]; then
    molt_error "agents: $name: $fault"
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
  local log="$1" prefix="$2" agents name role ok=0
  molt_report_faults "$log" "$prefix" "molt.toml" "$(molt_agent_manifest_faults)" || ok=1
  if ! agents="$(molt_homed_agents)"; then
    "$log" "${prefix}the [[agent]] entries in molt.toml could not be read"
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
  local agents name role failed=0
  molt_report_faults molt_error "agents: " "molt.toml" "$(molt_agent_manifest_faults)" || failed=1
  if ! agents="$(molt_homed_agents)"; then
    molt_error "agents: the [[agent]] entries in molt.toml could not be read"
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
