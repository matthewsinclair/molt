#!/usr/bin/env bash
# agent.sh — Sleeve agents: the [[agent]] entries in a sleeve's molt.toml, the
# home each one gets under MOLT_AGT_DIR, and `molt agent list|config` (ST0006).
#
# A sleeve agent is a local agent, Claude Code for now, that does
# machine-oriented work on one host as the user. Its name is derived, never
# written: <hostname>-<role>, so the convention cannot be mistyped. Its home is
# its config and its working directory at once, rendered from the user repo's
# config/agents/roles/<role>/ by the agents liberator.

# --- The manifest ---

# The [[agent]] entries in this sleeve's molt.toml, one
# "name<TAB>role<TAB>enabled<TAB>harness" line each, in manifest order. enabled
# defaults to true and harness to claude. An entry with no role, or one whose
# role an earlier entry declared, is left out: molt_agent_manifest_faults names
# it. Prints nothing when the sleeve has no manifest.
molt_agents() {
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null)" || return 0
  _molt_table_entries agent role "$manifest" | awk -F'\t' -v host="$(molt_hostname)" '
    $2 == "role" {
      skip = ($1 == "" || ($1 in seen))
      if (!skip) { seen[$1] = 1; order[++n] = $1; enabled[$1] = "true"; harness[$1] = "claude" }
      next
    }
    skip { next }
    $2 == "enabled" { enabled[$1] = $3 }
    $2 == "harness" { harness[$1] = $3 }
    END {
      for (i = 1; i <= n; i++) {
        r = order[i]
        print host "-" r "\t" r "\t" enabled[r] "\t" harness[r]
      }
    }
  '
}

# Names, a line each, what is wrong with this sleeve's [[agent]] entries: an
# entry with no role; a role two entries declare, which would give two agents
# one name; a name written in, which is derived and never written; a harness
# other than claude; and enabled other than true or false.
molt_agent_manifest_faults() {
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null)" || return 0
  _molt_table_entries agent role "$manifest" | awk -F'\t' '
    $2 == "role" {
      if ($1 == "") print "an [[agent]] entry has no role"
      else if ($1 in seen) print "role " $1 " is declared by more than one [[agent]] entry"
      seen[$1] = 1
      next
    }
    $1 == "" { next }
    $2 == "name" { print "the " $1 " entry writes a name; an agent is named <hostname>-<role>" }
    $2 == "harness" && $3 != "claude" { print "the " $1 " entry names harness " $3 "; claude is the only one" }
    $2 == "enabled" && $3 != "true" && $3 != "false" { print "the " $1 " entry has enabled = " $3 ", not true or false" }
  '
}

# --- A home ---

# The directories made in a home, once. They are the agent's: molt writes
# nothing into them, then or after.
_MOLT_AGENT_DIRS=(memory work)

# The home of the agent named $1: its config and its working directory.
molt_agent_home() {
  echo "${MOLT_AGT_DIR}/$1"
}

# Where the user repo defines the role $1. Fails when there is no user repo.
molt_agent_role_dir() {
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  echo "${user_repo}/config/agents/roles/$1"
}

# This sleeve's overlay for the role $1, whether or not it has one: facts true
# on this machine only, which the role's template, one file for every host,
# cannot hold. Fails when there is no user repo.
molt_agent_overlay() {
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  echo "${user_repo}/instances/$(molt_hostname)/agents/$1.md"
}

# The files rendered into a home for the role $1, one
# "file<TAB>template<TAB>extra" line each: the file's path in the home; its
# template; and an input appended after rendering, which its digest covers too.
# AGENTS.md is the role's contract followed by the sleeve's overlay; CLAUDE.md
# is Molt's one-line import of it; .claude/settings.json is the role's
# permission profile.
molt_agent_files() {
  local role_dir overlay
  role_dir="$(molt_agent_role_dir "$1")" || return 1
  overlay="$(molt_agent_overlay "$1")" || return 1
  printf '%s\t%s\t%s\n' AGENTS.md "$role_dir/AGENTS.md.tmpl" "$overlay"
  printf '%s\t%s\t%s\n' CLAUDE.md "${MOLT_ROOT}/templates/agents/CLAUDE.md.tmpl" ""
  printf '%s\t%s\t%s\n' .claude/settings.json "$role_dir/settings.json.tmpl" ""
}

# Each file in the home of the agent named $1, with the role $2, one
# "file<TAB>state<TAB>template" line each, where the state is current, stale,
# missing, or untemplated when the role has no template for it.
molt_agent_file_states() {
  local home file template extra state
  home="$(molt_agent_home "$1")"
  while IFS=$'\t' read -r file template extra; do
    [[ -n "$file" ]] || continue
    if [[ ! -f "$template" ]]; then
      state=untemplated
    elif [[ ! -e "$home/$file" ]]; then
      state=missing
    elif molt_render_stale "$template" "$home/$file" ${extra:+"$extra"}; then
      state=stale
    else
      state=current
    fi
    printf '%s\t%s\t%s\n' "$file" "$state" "$template"
  done <<< "$(molt_agent_files "$2")"
}

# Names, a line each, what stands between the agent named $1, with the role $2,
# and a current home: a role the user repo does not define, a template the role
# lacks, and a file or directory of the home missing or stale.
molt_agent_faults() {
  local name="$1" role="$2" home role_dir file state template dir
  home="$(molt_agent_home "$name")"
  if ! role_dir="$(molt_agent_role_dir "$role")"; then
    echo "the user repo cannot be found, so role $role cannot be read"
    return 0
  fi
  if [[ ! -d "$role_dir" ]]; then
    echo "role $role is not defined: there is no $(molt_tilde "$role_dir")"
    return 0
  fi
  while IFS=$'\t' read -r file state template; do
    case "$state" in
      current) ;;
      untemplated) echo "role $role has no $(molt_tilde "$template")" ;;
      *) echo "$(molt_tilde "$home/$file") is $state" ;;
    esac
  done <<< "$(molt_agent_file_states "$name" "$role")"
  for dir in "${_MOLT_AGENT_DIRS[@]}"; do
    [[ -d "$home/$dir" ]] || echo "$(molt_tilde "$home/$dir") is missing"
  done
}

# One word or two for the home of the agent named $1, with the role $2:
# current, stale, not rendered, or role undefined.
molt_agent_currency() {
  local name="$1" role="$2" role_dir
  role_dir="$(molt_agent_role_dir "$role")" || role_dir=""
  if [[ -z "$role_dir" || ! -d "$role_dir" ]]; then
    echo "role undefined"
  elif [[ ! -d "$(molt_agent_home "$name")" ]]; then
    echo "not rendered"
  elif [[ -n "$(molt_agent_faults "$name" "$role")" ]]; then
    echo "stale"
  else
    echo "current"
  fi
}

# --- Permissions ---

# The settings files Claude Code reads permission rules from, for a session in
# the home $1, one "layer<TAB>file" line each in the order Claude Code ranks
# them: managed (managed-settings.json, then its drop-ins), local (the home's
# settings.local.json, where Claude Code records what was approved there), home
# (its settings.json) and user. Listed whether or not each file exists.
molt_agent_settings_layers() {
  local home="$1" managed dropin
  managed="$(molt_claude_managed_dir)"
  printf 'managed\t%s\n' "$managed/managed-settings.json"
  for dropin in "$managed"/managed-settings.d/*.json; do
    [[ -e "$dropin" ]] && printf 'managed\t%s\n' "$dropin"
  done
  printf 'local\t%s\n' "$home/.claude/settings.local.json"
  printf 'home\t%s\n' "$home/.claude/settings.json"
  printf 'user\t%s\n' "$(molt_claude_config_dir)/settings.json"
}

# The permission rules in effect for a session in the home $1, one
# "list<TAB>rule<TAB>layer" line each: deny first, then ask, then allow, each in
# layer order. allow, ask and deny merge across the layers and deny wins at
# every one, so every rule from every layer is listed, tagged with the layer it
# came from. Fails, naming the file on stderr, when a layer that exists is not
# JSON with permissions lists.
molt_agent_permissions() {
  local home="$1" layers list layer file
  layers="$(molt_agent_settings_layers "$home")"
  for list in deny ask allow; do
    while IFS=$'\t' read -r layer file; do
      [[ -f "$file" ]] || continue
      if ! jq -r --arg list "$list" --arg layer "$layer" \
          '(.permissions[$list] // [])[] | [$list, ., $layer] | @tsv' "$file" 2>/dev/null; then
        echo "molt agent: $(molt_tilde "$file") cannot be read as Claude Code settings" >&2
        return 1
      fi
    done <<< "$layers"
  done
}

# --- molt agent ---

_agent_usage() {
  echo "Usage: molt agent list"
  echo "       molt agent config <name>"
}

# Every agent this sleeve declares: name, role, enabled, the state of its home,
# and the home. Faults in the entries themselves follow, and fail the command.
_agent_list() {
  local agents name role enabled harness
  if ! molt_find_manifest >/dev/null 2>&1; then
    molt_error "molt agent: this sleeve has no molt.toml, so it declares no agents"
    return 1
  fi
  agents="$(molt_agents)"
  if [[ -z "$agents" ]]; then
    echo "No agents: this sleeve's molt.toml has no [[agent]] entries."
  else
    printf '%-28s %-8s %-8s %-14s %s\n' NAME ROLE ENABLED STATE HOME
    while IFS=$'\t' read -r name role enabled harness; do
      printf '%-28s %-8s %-8s %-14s %s\n' "$name" "$role" "$enabled" \
        "$(molt_agent_currency "$name" "$role")" "$(molt_tilde "$(molt_agent_home "$name")")"
    done <<< "$agents"
  fi
  molt_report_faults molt_warn "molt agent: " "molt.toml" "$(molt_agent_manifest_faults)"
}

# The agent named $1: its role, harness, home, each rendered file's state, the
# settings files read for it, and the permission rules in effect there, each
# tagged with its layer. An undeclared name fails, listing the declared ones.
_agent_config() {
  local want="${1:-}" agents name role enabled harness found="" home file state template layer path rules
  if [[ -z "$want" ]]; then
    _agent_usage
    return 1
  fi
  agents="$(molt_agents)"
  while IFS=$'\t' read -r name role enabled harness; do
    if [[ -n "$name" && "$name" == "$want" ]]; then
      found=1
      break
    fi
  done <<< "$agents"
  if [[ -z "$found" ]]; then
    molt_error "molt agent: $want is not declared on this sleeve; declared: $(printf '%s\n' "$agents" | cut -f1 | paste -sd, - | sed 's/,/, /g; s/^$/none/')"
    return 1
  fi

  home="$(molt_agent_home "$name")"
  echo "$name"
  printf '  %-9s %s\n' role "$role" harness "$harness" enabled "$enabled" home "$(molt_tilde "$home")"
  echo "  files"
  while IFS=$'\t' read -r file state template; do
    [[ "$state" != untemplated ]] || state="role $role has no $(basename "$template")"
    printf '    %-24s %s\n' "$file" "$state"
  done <<< "$(molt_agent_file_states "$name" "$role")"

  echo "  settings, highest first"
  while IFS=$'\t' read -r layer path; do
    if [[ -f "$path" ]]; then
      printf '    %-8s %s\n' "$layer" "$(molt_tilde "$path")"
    else
      printf '    %-8s %s (absent)\n' "$layer" "$(molt_tilde "$path")"
    fi
  done <<< "$(molt_agent_settings_layers "$home")"

  echo "  permissions, deny winning at every layer"
  rules="$(molt_agent_permissions "$home")" || return 1
  if [[ -z "$rules" ]]; then
    echo "    none"
  else
    printf '%s\n' "$rules" | awk -F'\t' '{ printf "    %-6s %-44s %s\n", $1, $2, $3 }'
  fi
}

# molt agent list | molt agent config <name>
cmd_agent() {
  case "${1:-}" in
    list)   _agent_list ;;
    config) shift; _agent_config "$@" ;;
    *)      _agent_usage; return 1 ;;
  esac
}
