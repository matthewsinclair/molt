#!/usr/bin/env bash
# agents.sh — Liberator: sleeve agents
# Frees a machine's local agent from running in $HOME with nothing to hold its
# role: each [[agent]] entry in the sleeve's molt.toml gets a home under
# MOLT_AGT_DIR, rendered from the role the user repo defines (ST0006). The
# model, and the molt agent command, are in lib/agent.sh.

# Sets autoMemoryDirectory to $2 in the rendered settings.json $1, and, when $3
# names the home guard's hook entry, writes it in as the claude liberator writes
# it into the user settings, keeping every other hook (issue 0030). $1 must
# hold one JSON object: jq passes an empty render through as nothing and turns
# null into an object, and either would leave settings that read current but
# are not the role's, so that is checked before molt_settings_write writes it.
# Fails, printing why instead, with $1 as it was.
_agents_settings_set() {
  local target="$1" dir="$2" hook="$3" want=null
  if ! command -v jq &>/dev/null; then
    echo "jq is not installed"
    return 1
  fi
  if [[ -n "$hook" ]] && ! want="$(jq -eS 'select(type == "object")' "$hook" 2>/dev/null)"; then
    echo "$(molt_tilde "$hook") holds no hook object"
    return 1
  fi
  if ! jq -es 'length == 1 and (.[0] | type) == "object"' "$target" >/dev/null 2>&1; then
    echo "the template does not render to one JSON object"
    return 1
  fi
  # shellcheck disable=SC2016 # $dir and $want are jq's, not the shell's
  molt_settings_write "$target" jq --arg dir "$dir" --argjson want "$want" \
    '.autoMemoryDirectory = $dir | if $want == null then . else '"$MOLT_CLAUDE_HOOK_SET"' end' "$target"
}

# Builds the whole of the file $2 of a home in ${2}.molt-tmp, from the template
# $1: the template $3 rendered and put ahead of it, and the file $4 after it, a
# blank line before each, where they are there. molt_render_place then
# compares, backs up and moves the whole, so a re-render is compared with what
# is on disk, and a layer that fails leaves $2 as it was (critic-shell, 21
# Oct: built in more than one place, AGENTS.md was backed up at every render
# once it had a preamble or an overlay). Fails, printing why, with no
# .molt-tmp left.
_agents_build() {
  local template="$1" target="$2" before="$3" after="$4" tmp="${2}.molt-tmp" why
  if ! why="$(molt_render_text "$template" "$tmp")"; then
    echo "$(molt_tilde "$template") could not be rendered${why:+: $why}"
    return 1
  fi
  if [[ -n "$before" && -f "$before" ]]; then
    if ! why="$(molt_render_text "$before" "${target}.molt-before")"; then
      rm -f "$tmp"
      echo "$(molt_tilde "$before") could not be rendered${why:+: $why}"
      return 1
    fi
    if ! { cat "${target}.molt-before" && printf '\n' && cat "$tmp"; } > "${target}.molt-joined" \
        || ! mv -f "${target}.molt-joined" "$tmp"; then
      rm -f "$tmp" "${target}.molt-before" "${target}.molt-joined"
      echo "$(molt_tilde "$before") could not be put ahead of it"
      return 1
    fi
    rm -f "${target}.molt-before"
  fi
  if [[ -n "$after" && -f "$after" ]] && ! { printf '\n'; cat "$after"; } >> "$tmp"; then
    rm -f "$tmp"
    echo "$(molt_tilde "$after") could not be put after it"
    return 1
  fi
}

# Renders the file $3 of the home of the agent named $1, with the role $2, from
# the template $4, with what goes around it: the template $5 rendered and put
# ahead of it, the file $6 appended after it, and autoMemoryDirectory set in
# settings.json, so the agent's memory lives in its home and travels with it,
# with the home guard's hook where molt_agent_guard_hook names it. All of it
# is built before molt_render_place sees it, settings.json's memory dir
# included, which was set after the compare and backed the file up at every
# render.
_agents_render_file() {
  local name="$1" role="$2" file="$3" template="$4" before="$5" after="$6" home host target hook why
  home="$(molt_agent_home "$name")"
  if ! host="$(molt_hostname)"; then
    molt_error "agents: this host gives no name, so $name's $file was not rendered"
    return 1
  fi
  if ! hook="$(molt_agent_guard_hook "$file")"; then
    molt_error "agents: $name's $file was not rendered: $hook"
    return 1
  fi
  target="$home/$file"
  # In a subshell, so the agent's variables reach envsubst and go no further.
  if ! why="$(
    export MOLT_HOSTNAME="$host" MOLT_AGENT_NAME="$name" MOLT_AGENT_ROLE="$role" MOLT_AGENT_HOME="$home"
    _agents_build "$template" "$target" "$before" "$after"
  )"; then
    molt_error "agents: $name's $file was not rendered: $why"
    return 1
  fi
  case "$file" in
    .claude/settings.json)
      if ! why="$(_agents_settings_set "${target}.molt-tmp" "$home/memory" "$hook")"; then
        rm -f "${target}.molt-tmp"
        molt_error "agents: $name's settings.json, from role $role's settings.json.tmpl, is not usable: $why"
        return 1
      fi ;;
  esac
  # The digest covers what went around the template, present or not, and the
  # hook entry, so a home rendered without it is stale.
  molt_render_place "$template" "$target" ${before:+"$before"} ${after:+"$after"} ${hook:+"$hook"}
}

# Renders the home of the agent named $1, with the role $2: each file that is
# missing or stale, then memory/ and work/ where they are missing. It does not
# wait for the claude liberator's move: on kovacs the home rendered while
# kovacs-sysadm was still live and the move was refused, so it could copy its
# files in before hv ran the move (ST0006).
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
    if molt_agent_file_stale "$home" "$file" "$template" "$before" "$after"; then
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
  molt_report_faults "$log" "$prefix" "managed floor" "$(molt_agent_floor_faults)" || ok=1
  molt_report_faults "$log" "$prefix" "sandbox profile" "$(molt_agent_sandbox_faults)" || ok=1
  return $ok
}

# Puts this sleeve's managed floor right: installs floor.json's bytes as the
# drop-in, its sidecar first, so a drop-in beside molt's sidecar is always one
# molt wrote, where a sysadm agent has a home and the floor is missing or
# stale; removes molt's drop-in, then its sidecar, where none has; and leaves,
# naming it, a drop-in molt did not write.
_agents_floor() {
  local state target src why
  target="$(molt_agent_floor_target)"
  if ! state="$(molt_agent_floor_state)"; then
    molt_error "agents: managed floor: $state, so nothing was written"
    return 1
  fi
  case "$state" in
    current | absent) return 0 ;;
    foreign)
      molt_error "agents: managed floor: $(molt_tilde "$target") was not written by molt, which leaves it, so the floor is not in place"
      return 1 ;;
    unowned)
      molt_warn "agents: managed floor: $(molt_tilde "$target") was not written by molt, which leaves it"
      return 0 ;;
    leftover)
      if ! why="$(molt_root_file_remove "$target")"; then
        molt_error "agents: managed floor: $why"
        return 1
      fi
      molt_info "Removed the managed floor: $(molt_tilde "$target")"
      return 0 ;;
  esac
  if ! src="$(molt_agent_floor_source)"; then
    molt_error "agents: managed floor: the user repo cannot be found, so nothing was written"
    return 1
  fi
  if ! why="$(molt_root_file_install "$src" "$target")"; then
    molt_error "agents: managed floor: $why"
    return 1
  fi
  molt_info "Rendered: $src -> $target"
}

# Loads molt's sandbox profile at $1 and tries bwrap under it. A bwrap that is
# not installed is a warning, since the profile is in place and nothing could
# be tried; bwrap's children still refused is a failure.
_agents_sandbox_take() {
  local why status=0
  if ! why="$(molt_apparmor_load "$1")"; then
    molt_error "agents: sandbox profile: $why"
    return 1
  fi
  molt_info "Loaded: $(molt_tilde "$1")"
  why="$(molt_agent_sandbox_probe)" || status=$?
  case $status in
    0) ;;
    2) molt_warn "agents: sandbox profile: $why" ;;
    *)
      molt_error "agents: sandbox profile: $why"
      return 1 ;;
  esac
}

# Puts this sleeve's sandbox profile right. Where a Linux sleeve gives an ops or
# docs agent a home: checks this sleeve's AppArmor parses molt's, keeps the
# distro's profile once as .molt-orig, installs molt's, its sidecar first, then
# loads it and tries bwrap; loads molt's again where it is in place but bwrap's
# children are still refused. Where none is wanted and molt's is in place: puts
# the distro's back and loads it, then removes the sidecar and the orig. Any
# other profile is left.
_agents_sandbox() {
  local state target orig src why status=0
  target="$(molt_agent_sandbox_target)"
  orig="$(molt_agent_sandbox_orig)"
  src="$(molt_agent_sandbox_source)"
  if ! state="$(molt_agent_sandbox_state)"; then
    molt_error "agents: sandbox profile: $state, so nothing was written"
    return 1
  fi
  # Nothing is written that this sleeve's AppArmor cannot load.
  case "$state" in
    missing | stale | foreign)
      if ! why="$(molt_apparmor_parses "$src")"; then
        molt_error "agents: sandbox profile: $why, so nothing was written"
        return 1
      fi ;;
  esac
  case "$state" in
    absent | unowned) return 0 ;;
    current)
      why="$(molt_agent_sandbox_probe)" || status=$?
      case $status in
        0) return 0 ;;
        2)
          molt_warn "agents: sandbox profile: $why"
          return 0 ;;
      esac
      _agents_sandbox_take "$target"
      return ;;
    leftover)
      if [[ ! -e "$orig" ]]; then
        molt_error "agents: sandbox profile: there is no $(molt_tilde "$orig") to put back, so $(molt_tilde "$target") is left"
        return 1
      fi
      # The sidecar and the orig go only once the distro's is back and loaded,
      # so a run cut short, or a load refused, leaves a profile molt still
      # answers for.
      if ! why="$(molt_sudo_install "$orig" "$target")" \
          || ! why="$(molt_apparmor_load "$target")" \
          || ! why="$(molt_sudo_remove "${target}.molt-rendered" "$orig")"; then
        molt_error "agents: sandbox profile: $why"
        return 1
      fi
      molt_info "Restored the distro's $(molt_tilde "$target") from $(molt_tilde "$orig")"
      return 0 ;;
    foreign)
      # Only the distro's is replaced: kept first, or kept already by a run cut
      # short, which left it in place again.
      if [[ -e "$orig" ]] && ! cmp -s "$target" "$orig"; then
        molt_report_faults molt_error "agents: " "sandbox profile" "$(molt_agent_sandbox_faults foreign)"
        return 1
      fi
      if [[ ! -e "$orig" ]]; then
        if ! why="$(molt_sudo_install "$target" "$orig")"; then
          molt_error "agents: sandbox profile: $why"
          return 1
        fi
        molt_info "Kept the distro's $(molt_tilde "$target") as $(molt_tilde "$orig")"
      fi ;;
  esac
  if ! why="$(molt_root_file_install "$src" "$target")"; then
    molt_error "agents: sandbox profile: $why"
    return 1
  fi
  molt_info "Rendered: $src -> $target"
  _agents_sandbox_take "$target"
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
  # Nor any home a sysadm agent's floor cannot follow.
  if ! fault="$(molt_agent_floor_state)"; then
    molt_error "agents: managed floor: $fault, so nothing was written"
    return 1
  fi
  while IFS=$'\t' read -r name role; do
    [[ -n "$name" ]] || continue
    _agents_render "$name" "$role" || failed=1
  done <<< "$agents"
  _agents_floor || failed=1
  _agents_sandbox || failed=1
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
