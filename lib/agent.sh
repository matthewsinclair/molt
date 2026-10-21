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
  local manifest host
  host="$(molt_hostname)" || return 1
  manifest="$(molt_find_manifest 2>/dev/null)" || return 0
  _molt_table_entries agent role "$manifest" | awk -F'\t' -v host="$host" '
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

# The agents this sleeve gives a home, one "name<TAB>role" line each: those
# enabled, with the one harness molt renders a home for, claude.
molt_homed_agents() {
  local agents
  agents="$(molt_agents)" || return 1
  printf '%s\n' "$agents" | awk -F'\t' '$3 == "true" && $4 == "claude" { print $1 "\t" $2 }'
}

# The entry of the agent named $1, as molt_agents prints it. Fails, printing
# nothing: with status 1 when this sleeve declares no agent of that name, and 2
# when its [[agent]] entries cannot be read. awk reads to the end, so the
# writer never meets a closed pipe under pipefail (issue 0008).
molt_agent_named() {
  local agents
  agents="$(molt_agents)" || return 2
  printf '%s\n' "$agents" | awk -F'\t' -v want="$1" '!found && $1 == want { print; found = 1 } END { exit !found }'
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

# --- The agents root ---

# True when the absolute path $1 is the absolute path $2, or under it, as the
# disk spells both (molt_disk_path), which is how the home guard compares
# them. A relative path is under nothing and holds nothing: the root is
# refused before it is asked about, and a relative HOME, MOLT_PRJ_DIR,
# MOLT_CFG_DIR or config dir names no directory to compare, which the guard
# and the claude liberator refuse in their turn.
_molt_disk_within() {
  local path under
  [[ "$1" == /* && "$2" == /* ]] || return 1
  path="$(molt_disk_path "$1")" && under="$(molt_disk_path "$2")" || return 1
  [[ "$under" == / || "$path" == "$under" || "$path" == "$under"/* ]]
}

# Why the agents root $1 cannot hold homes, or nothing when it can. It reads
# its argument, HOME, MOLT_PRJ_DIR, MOLT_CFG_DIR and molt_claude_config_dir,
# and the disk to resolve them. Homes are made under the root as it is spelt,
# and the claude liberator renders its home guard with that spelling and reads
# it back to tell whether it has drifted, so a root is refused rather than
# tidied (AC014):
#   - empty, as constants.sh leaves it when MOLT_PRJ_DIR is not set either
#     (vc, 21 Oct: a Molt sleeve always has MOLT_PRJ_DIR);
#   - a path molt_path_fault refuses: relative, or a second spelling;
#   - holding a line break, where the guard's here-document read stops;
#   - at or above HOME, MOLT_PRJ_DIR or MOLT_CFG_DIR: the guard refuses a
#     launch two levels below the root that is not in a home, so such a root
#     would refuse every project. The disk decides, as it does for the guard:
#     a root reaching HOME through a symlink, or in another letter case, is
#     HOME to the guard;
#   - at or under ~/.claude or Claude Code's config dir: a home made there
#     moves with Claude Code's state, or brings ~/.claude back once it has
#     moved.
# A root constants.sh derived from MOLT_PRJ_DIR is named so, since nobody set
# it as MOLT_AGT_DIR; / is above everything, and is not called untidy.
_molt_agt_root_fault() {
  local root="$1" name=MOLT_AGT_DIR fault shown dir
  if [[ -z "$root" ]]; then
    echo "MOLT_AGT_DIR cannot be resolved: MOLT_PRJ_DIR is unset"
    return 0
  fi
  if [[ -n "${MOLT_PRJ_DIR:-}" && "$root" == "$(molt_agt_dir_derived)" ]]; then
    name="MOLT_AGT_DIR, the agt/ sibling of MOLT_PRJ_DIR $MOLT_PRJ_DIR,"
  fi
  if [[ "$root" != / ]]; then
    fault="$(molt_path_fault "$name" "$root")"
    if [[ -n "$fault" ]]; then
      echo "$fault"
      return 0
    fi
  fi
  case "$root" in
    *$'\n'*)
      echo "$name holds a line break: $root"
      return 0 ;;
  esac
  shown="MOLT_AGT_DIR, $(molt_tilde "$root"),"
  if [[ "$name" != MOLT_AGT_DIR ]]; then
    shown="$shown the agt/ sibling of MOLT_PRJ_DIR $(molt_tilde "$MOLT_PRJ_DIR"),"
  fi
  for dir in "$HOME" "${MOLT_PRJ_DIR:-}" "${MOLT_CFG_DIR:-}"; do
    if _molt_disk_within "$dir" "$root"; then
      echo "$shown is at or above $(molt_tilde "$dir"): the home guard would refuse a launch in any directory two levels below it that is not an agent home"
      return 0
    fi
  done
  for dir in "$HOME/.claude" "$(molt_claude_config_dir)"; do
    if _molt_disk_within "$root" "$dir"; then
      echo "$shown is at or under $(molt_tilde "$dir"), where Claude Code keeps its state: a home there would move with that state, or bring ~/.claude back once it has moved"
      return 0
    fi
  done
}

# Why this sleeve's agents root cannot hold homes, or nothing when it can:
# _molt_agt_root_fault's answer for MOLT_AGT_DIR; a vars.sh that changes
# MOLT_AGT_DIR; or a root at or under the config dir the sleeve declares,
# before Claude Code's state has moved there. constants.sh is the one
# resolver, and molt_render_text sources vars.sh with MOLT_AGT_DIR exported as
# it resolved it, so an assignment, a += or an unset there would render the
# claude liberator's guard with another root, or none, while the homes are
# made under this one: vars.sh is read here the same way.
molt_agt_dir_fault() {
  local fault declared config status=0
  fault="$(_molt_agt_root_fault "${MOLT_AGT_DIR:-}")"
  if [[ -n "$fault" ]]; then
    echo "$fault"
    return 0
  fi
  declared="$(molt_instance_var MOLT_AGT_DIR "$MOLT_AGT_DIR")" || status=$?
  case "$status" in
    0) ;;
    3) return 0 ;;
    *)
      echo "MOLT_AGT_DIR could not be checked against this sleeve's vars.sh: $declared"
      return 0 ;;
  esac
  if [[ -z "$declared" ]]; then
    echo "this sleeve's vars.sh unsets MOLT_AGT_DIR, empties it or stops exporting it, while molt resolves it as $(molt_tilde "$MOLT_AGT_DIR"): drop that from vars.sh"
    return 0
  fi
  if [[ "$declared" != "$MOLT_AGT_DIR" ]]; then
    echo "this sleeve's vars.sh sets MOLT_AGT_DIR to $(molt_tilde "$declared"), but molt resolves it as $(molt_tilde "$MOLT_AGT_DIR"): drop it from vars.sh, and set MOLT_PRJ_DIR or MOLT_AGT_DIR where molt runs"
    return 0
  fi
  if ! config="$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR)"; then
    echo "MOLT_AGT_DIR could not be checked against this sleeve's MOLT_CLAUDE_CONFIG_DIR: $config"
  elif _molt_disk_within "$MOLT_AGT_DIR" "$config"; then
    echo "MOLT_AGT_DIR, $(molt_tilde "$MOLT_AGT_DIR"), is at or under $(molt_tilde "$config"), the config dir this sleeve declares for Claude Code: a home there would block the move into it, or move with Claude Code's state"
  fi
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

# Why the role $1 cannot give an agent a home, or nothing when it can: the user
# repo cannot be found, or does not define the role.
molt_agent_role_fault() {
  local role_dir
  if ! role_dir="$(molt_agent_role_dir "$1")"; then
    echo "the user repo cannot be found, so role $1 cannot be read"
  elif [[ ! -d "$role_dir" ]]; then
    echo "role $1 is not defined: there is no $(molt_tilde "$role_dir")"
  fi
}

# This sleeve's overlay for the role $1, whether or not it has one: facts true
# on this machine only, which the role's template, one file for every host,
# cannot hold. Fails when there is no user repo.
molt_agent_overlay() {
  local user_repo host
  user_repo="$(molt_find_user_repo)" || return 1
  host="$(molt_hostname)" || return 1
  echo "${user_repo}/instances/${host}/agents/$1.md"
}

# The role-independent preamble every agent's AGENTS.md opens with, whether or
# not the user repo has one: text common to every sleeve agent, which no role
# template repeats (AC016). Fails when there is no user repo.
molt_agent_preamble() {
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  echo "${user_repo}/config/agents/AGENTS.md.tmpl"
}

# The files rendered into a home for the role $1, one
# "file<TAB>template<TAB>before<TAB>after" line each: the file's path in the
# home; its template; a template rendered and put ahead of it; and a file
# appended after it. Their digests cover both, present or not, so adding,
# changing or removing either makes the file stale. AGENTS.md is the
# preamble, then the role's contract, then the sleeve's overlay, in that
# order; CLAUDE.md is Molt's one-line import of it; .claude/settings.json is
# the role's permission profile. An empty field comes only last: read takes
# tabs as whitespace and closes up an empty one between two others. Fails when
# the user repo or this host's name cannot be found.
molt_agent_files() {
  local role_dir preamble overlay
  role_dir="$(molt_agent_role_dir "$1")" || return 1
  preamble="$(molt_agent_preamble)" || return 1
  overlay="$(molt_agent_overlay "$1")" || return 1
  printf '%s\t%s\t%s\t%s\n' AGENTS.md "$role_dir/AGENTS.md.tmpl" "$preamble" "$overlay"
  printf '%s\t%s\t%s\t%s\n' CLAUDE.md "${MOLT_ROOT}/templates/agents/CLAUDE.md.tmpl" "" ""
  printf '%s\t%s\t%s\t%s\n' .claude/settings.json "$role_dir/settings.json.tmpl" "" ""
}

# Each file in the home of the agent named $1, with the role $2, one
# "file<TAB>state<TAB>template" line each, where the state is current, stale,
# missing, or untemplated when the role has no template for it. Fails when the
# role's files cannot be listed.
molt_agent_file_states() {
  local home files file template before after state
  home="$(molt_agent_home "$1")"
  files="$(molt_agent_files "$2")" || return 1
  while IFS=$'\t' read -r file template before after; do
    [[ -n "$file" ]] || continue
    if [[ ! -f "$template" ]]; then
      state=untemplated
    elif [[ ! -e "$home/$file" ]]; then
      state=missing
    elif molt_render_stale "$template" "$home/$file" ${before:+"$before"} ${after:+"$after"}; then
      state=stale
    else
      state=current
    fi
    printf '%s\t%s\t%s\n' "$file" "$state" "$template"
  done <<< "$files"
}

# Names, a line each, what stands between the agent named $1, with the role $2,
# and a current home: a role the user repo does not define, a template the role
# lacks, and a file or directory of the home missing or stale.
molt_agent_faults() {
  local name="$1" role="$2" home fault states file state template dir
  home="$(molt_agent_home "$name")"
  fault="$(molt_agent_role_fault "$role")"
  if [[ -n "$fault" ]]; then
    echo "$fault"
    return 0
  fi
  if ! states="$(molt_agent_file_states "$name" "$role")"; then
    echo "the files of role $role cannot be listed"
    return 0
  fi
  while IFS=$'\t' read -r file state template; do
    case "$state" in
      current) ;;
      untemplated) echo "role $role has no $(molt_tilde "$template")" ;;
      *) echo "$(molt_tilde "$home/$file") is $state" ;;
    esac
  done <<< "$states"
  for dir in "${_MOLT_AGENT_DIRS[@]}"; do
    [[ -d "$home/$dir" ]] || echo "$(molt_tilde "$home/$dir") is missing"
  done
}

# One word or two for the home of the agent named $1, with the role $2:
# current, stale, not rendered, or role undefined.
molt_agent_currency() {
  local name="$1" role="$2"
  if [[ -n "$(molt_agent_role_fault "$role")" ]]; then
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
  if ! command -v jq &>/dev/null; then
    echo "molt agent: jq is not installed, so the permission rules cannot be read" >&2
    return 1
  fi
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
  if ! agents="$(molt_agents)"; then
    molt_error "molt agent: the [[agent]] entries in molt.toml could not be read"
    return 1
  fi
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
  local want="${1:-}" entry status=0 name role enabled harness home states file state template layer path rules
  if [[ -z "$want" ]]; then
    _agent_usage
    return 1
  fi
  entry="$(molt_agent_named "$want")" || status=$?
  case "$status" in
    0) ;;
    1)
      molt_error "molt agent: $want is not declared on this sleeve; declared: $(printf '%s\n' "$(molt_agents)" | cut -f1 | paste -sd, - | sed 's/,/, /g; s/^$/none/')"
      return 1 ;;
    *)
      molt_error "molt agent: the [[agent]] entries in molt.toml could not be read"
      return 1 ;;
  esac
  IFS=$'\t' read -r name role enabled harness <<< "$entry"

  home="$(molt_agent_home "$name")"
  echo "$name"
  printf '  %-9s %s\n' role "$role" harness "$harness" enabled "$enabled" home "$(molt_tilde "$home")"
  if ! states="$(molt_agent_file_states "$name" "$role")"; then
    molt_error "molt agent: the files of role $role cannot be listed"
    return 1
  fi
  echo "  files"
  while IFS=$'\t' read -r file state template; do
    [[ "$state" != untemplated ]] || state="role $role has no $(basename "$template")"
    printf '    %-24s %s\n' "$file" "$state"
  done <<< "$states"

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
