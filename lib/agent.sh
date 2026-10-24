#!/usr/bin/env bash
# agent.sh — Sleeve agents: the [[agent]] entries in a sleeve's molt.toml, the
# home each one gets under MOLT_AGT_DIR, and `molt agent list|config` (ST0006)
# and `roles|start|home` (ST0007).
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

# The entry $1 names among the agents $2, as molt_agents prints them: the one
# whose name it is, or else the one whose role it is, so <hostname>-<role>
# reaches its agent even beside a role spelled like that name. Fails, printing
# nothing, when $1 names none. awk reads to the end, so the writer never meets
# a closed pipe under pipefail (issue 0008).
molt_agent_named() {
  printf '%s\n' "$2" | awk -F'\t' -v want="$1" '
    $1 == want && byname == "" { byname = $0 }
    $2 == want && byrole == "" { byrole = $0 }
    END { if (byname != "") print byname; else if (byrole != "") print byrole; exit (byname == "" && byrole == "") }'
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

# Where the user repo defines the role $1. Fails, printing nothing, when there
# is no user repo: its callers say so in their own words.
molt_agent_role_dir() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null)" || return 1
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
  molt_instance_file "agents/$1.md"
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

# The home guard's hook entry (molt_claude_hook_entry) when the home's file $1
# carries it, and nothing when it does not: settings.json carries it on a
# sleeve that declares its config dir, where the claude liberator publishes the
# guard. A session started without that config dir never reads the user
# settings that also run it, so only the home's copy refuses it (issue 0030).
# Fails, printing why instead, when vars.sh cannot be read.
molt_agent_guard_hook() {
  local declared
  [[ "$1" == .claude/settings.json ]] || return 0
  if ! declared="$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR)"; then
    echo "MOLT_CLAUDE_CONFIG_DIR could not be read: $declared"
    return 1
  fi
  [[ -z "$declared" ]] || molt_claude_hook_entry
}

# Whether the home's settings.json $1 carries the hook entry in the file $2 as
# it stands, compared as the claude liberator compares the user settings', with
# jq -S, so key order and layout are not differences.
molt_agent_runs_hook() {
  local want have
  want="$(jq -eS 'select(type == "object")' "$2" 2>/dev/null)" || return 1
  have="$(jq -S --argjson want "$want" "$MOLT_CLAUDE_HOOK_GET" "$1" 2>/dev/null)" || return 1
  [[ "$have" == "$want" ]]
}

# Whether the file $2 of the home $1 must be rendered again from the template
# $3, with the template $4 put ahead of it and the file $5 after it: it is
# missing, or its digest, which covers the guard's hook entry where the file
# carries it, does not match, or it does not run that hook.
molt_agent_file_stale() {
  local home="$1" file="$2" template="$3" before="$4" after="$5" hook
  hook="$(molt_agent_guard_hook "$file")" || return 0
  molt_render_stale "$template" "$home/$file" ${before:+"$before"} ${after:+"$after"} ${hook:+"$hook"} && return 0
  [[ -n "$hook" ]] && ! molt_agent_runs_hook "$home/$file" "$hook"
}

# Whether the home $1's settings.json runs the home guard, for molt agent
# config: the guard's command when it does, a fault when it should and does
# not, and why it need not on a sleeve that declares no config dir.
molt_agent_guard_state() {
  local home="$1" hook command
  if ! hook="$(molt_agent_guard_hook .claude/settings.json)"; then
    echo "not checked: $hook"
  elif [[ -z "$hook" ]]; then
    echo "none: this sleeve declares no config dir for Claude Code"
  elif ! molt_agent_runs_hook "$home/.claude/settings.json" "$hook"; then
    echo "missing from .claude/settings.json: re-run molt upgrade"
  elif ! command="$(jq -er '.hooks[0].command' "$hook")"; then
    echo "not checked: $(molt_tilde "$hook") names no command"
  elif [[ ! -x "${command/#\~/$HOME}" ]]; then
    echo "$command, which is missing or not executable: the claude liberator publishes it once the move is done"
  else
    echo "$command"
  fi
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
    elif molt_agent_file_stale "$home" "$file" "$template" "$before" "$after"; then
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

# --- The managed floor (WP06) ---

# A sysadm agent cannot be sandboxed, so its home's deny list is a fence it
# could edit. The floor is the same denies where it cannot reach them: the
# user repo's config/agents/roles/sysadm/floor.json, its bytes as they are,
# in Claude Code's managed drop-in, root-owned, beside a sidecar molt writes
# first. Only a drop-in beside molt's sidecar is ever replaced or removed.

# The floor's source in the user repo. Fails when there is no user repo.
molt_agent_floor_source() {
  local role_dir
  role_dir="$(molt_agent_role_dir sysadm)" || return 1
  echo "$role_dir/floor.json"
}

# The floor's drop-in; its sidecar is ${this}.molt-rendered.
molt_agent_floor_target() {
  echo "$(molt_claude_managed_dir)/managed-settings.d/molt-sysadm.json"
}

# True when this sleeve gives a sysadm agent a home and declares
# MOLT_CLAUDE_CONFIG_DIR, the gate the home guard's hook keeps
# (molt_agent_guard_hook), so it carries the floor. Fails, with status 2 and
# printing why, when the [[agent]] entries or vars.sh cannot be read.
molt_agent_floor_wanted() {
  local agents declared
  if ! agents="$(molt_homed_agents)"; then
    echo "the [[agent]] entries in molt.toml could not be read"
    return 2
  fi
  printf '%s\n' "$agents" | awk -F'\t' '$2 == "sysadm" { found = 1 } END { exit !found }' || return 1
  if ! declared="$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR)"; then
    echo "MOLT_CLAUDE_CONFIG_DIR could not be read: $declared"
    return 2
  fi
  [[ -n "$declared" ]]
}

# Why the floor's source cannot be installed, or nothing when it can: no user
# repo, no floor.json, or one that is not a single object holding only
# permissions, holding only deny, a list of strings.
molt_agent_floor_fault() {
  local src
  if ! src="$(molt_agent_floor_source)"; then
    echo "the user repo cannot be found, so the floor cannot be read"
  elif [[ ! -f "$src" ]]; then
    echo "a sysadm agent needs its managed floor, and there is no $(molt_tilde "$src")"
  elif ! command -v jq &>/dev/null; then
    echo "jq is not installed, so $(molt_tilde "$src") cannot be read"
  elif ! jq -se 'length == 1 and (.[0] | type == "object" and keys == ["permissions"]
      and (.permissions | type == "object" and keys == ["deny"])
      and (.permissions.deny | type == "array" and all(type == "string")))' "$src" >/dev/null 2>&1; then
    echo "$(molt_tilde "$src") is not one object holding only permissions.deny, a list of strings"
  fi
}

# The state of this sleeve's floor, one word: on a sleeve that carries it,
# current, missing, stale, or foreign (a drop-in molt did not write, which it
# leaves, so the floor is not in place); on one that does not, absent, leftover
# (molt's, to remove), or unowned (somebody else's, left alone). Fails,
# printing why instead, when the [[agent]] entries or vars.sh cannot be read,
# or, on a sleeve that carries the floor, its source cannot be installed.
molt_agent_floor_state() {
  local target src why wanted=0
  target="$(molt_agent_floor_target)"
  why="$(molt_agent_floor_wanted)" || wanted=$?
  if [[ $wanted -eq 2 ]]; then
    echo "$why"
    return 1
  fi
  if [[ $wanted -eq 0 ]]; then
    why="$(molt_agent_floor_fault)"
    if [[ -n "$why" ]]; then
      echo "$why"
      return 1
    fi
    # The fault above names a source that cannot be found.
    src="$(molt_agent_floor_source)" || return 1
  fi
  molt_root_file_state "${src:-}" "$target" "$wanted"
}

# Names, a line each, what stands between this sleeve and the floor it should
# carry: the source's fault, a floor missing or stale, one molt did not write,
# or molt's left on a sleeve that no longer carries it. Takes the state
# molt_agent_floor_state gave as $1 where the caller has it.
molt_agent_floor_faults() {
  local state target
  target="$(molt_tilde "$(molt_agent_floor_target)")"
  if [[ $# -gt 0 ]]; then
    state="$1"
  elif ! state="$(molt_agent_floor_state)"; then
    echo "$state"
    return 0
  fi
  case "$state" in
    current | absent | unowned) ;;
    missing) echo "$target is missing" ;;
    stale) echo "$target is not $(molt_tilde "$(molt_agent_floor_source)")" ;;
    foreign) echo "$target was not written by molt, which leaves it" ;;
    leftover) echo "$target is molt's, and this sleeve carries no floor: it has no enabled sysadm agent, or declares no MOLT_CLAUDE_CONFIG_DIR" ;;
  esac
}

# --- The sandbox profile (issue 0032) ---

# Claude Code's Linux sandbox runs each command under bwrap and makes a nested
# user namespace there, which needs sys_admin. Ubuntu's bwrap-userns-restrict
# denies bwrap's children every capability, so an ops or docs agent, fenced
# with the sandbox and no unsandboxed commands, can run none. Molt's copy of
# that profile denies them every capability but sys_admin. It replaces the
# distro's, which is kept beside it as .molt-orig, once, and put back when the
# sleeve no longer takes molt's. Only a profile beside molt's sidecar is ever
# replaced by the distro's.

# Molt's profile, in the framework.
molt_agent_sandbox_source() {
  echo "${MOLT_ROOT}/templates/apparmor/bwrap-userns-restrict.tmpl"
}

# The profile molt replaces; its sidecar is ${this}.molt-rendered.
molt_agent_sandbox_target() {
  echo "$(molt_apparmor_dir)/bwrap-userns-restrict"
}

# Where the distro's profile is kept while molt's is in place.
molt_agent_sandbox_orig() {
  echo "$(molt_agent_sandbox_target).molt-orig"
}

# True when this sleeve is Linux, gives an ops or docs agent a home, the roles
# fenced with the sandbox, and has the distro's bwrap-userns-restrict, in place
# or kept, so it takes molt's profile. A distro that ships none restricts no
# bwrap, and needs none. Fails, with status 2 and printing why, when the
# [[agent]] entries cannot be read.
molt_agent_sandbox_wanted() {
  local agents
  [[ "$(molt_platform)" == linux ]] || return 1
  if ! agents="$(molt_homed_agents)"; then
    echo "the [[agent]] entries in molt.toml could not be read"
    return 2
  fi
  printf '%s\n' "$agents" | awk -F'\t' '$2 == "ops" || $2 == "docs" { found = 1 } END { exit !found }' || return 1
  [[ -e "$(molt_agent_sandbox_target)" || -e "$(molt_agent_sandbox_orig)" ]]
}

# The state of this sleeve's sandbox profile, one word: on a sleeve that takes
# molt's, current, missing (the distro's is kept, and none is in place), stale,
# or foreign (the distro's, or anybody's but molt's); on one that does not, absent, leftover (molt's, to put the distro's
# back over), or unowned (the distro's, left alone). Fails, printing why
# instead, when the [[agent]] entries cannot be read or the profile cannot be
# compared with molt's.
molt_agent_sandbox_state() {
  local why wanted=0
  why="$(molt_agent_sandbox_wanted)" || wanted=$?
  if [[ $wanted -eq 2 ]]; then
    echo "$why"
    return 1
  fi
  molt_root_file_state "$(molt_agent_sandbox_source)" "$(molt_agent_sandbox_target)" "$wanted"
}

# Tries, unprivileged, what Claude Code's sandbox does first where molt's
# profile is in place: a user namespace made inside bwrap, mapping root. It is
# the check that the profile is loaded, since aa-status needs root and
# apparmor_parser -Q never asks the kernel. bwrap binds / as it is, so the
# unshare it runs is this sleeve's. Fails, printing why: with status 2 when
# bwrap or unshare is not installed, so nothing could be tried, and 1 when
# bwrap's children are refused.
molt_agent_sandbox_probe() {
  local out tool
  for tool in bwrap unshare; do
    if ! command -v "$tool" &>/dev/null; then
      echo "$tool is not installed, so whether Claude Code's sandbox can start cannot be tried"
      return 2
    fi
  done
  if ! out="$(bwrap --unshare-user --unshare-pid --ro-bind / / --dev /dev --proc /proc unshare -U --map-root-user true 2>&1)"; then
    out="$(printf '%s\n' "$out" | tail -n 1)"
    echo "$(molt_tilde "$(molt_agent_sandbox_target)") is molt's, but bwrap's children still cannot make the sandbox's user namespace: ${out:-bwrap said nothing}"
    return 1
  fi
}

# Names, a line each, what stands between this sleeve and the sandbox profile
# it should take: apparmor_parser absent; a profile missing, stale, or not
# molt's, and somebody's other than the distro's kept copy; molt's in place but
# bwrap's children still refused, or bwrap or unshare absent so that cannot be
# tried, which it runs bwrap to find out; molt's left on a sleeve that no
# longer takes it, and no .molt-orig to put back. Takes the state
# molt_agent_sandbox_state gave as $1 where the caller has it.
molt_agent_sandbox_faults() {
  local state target orig why
  target="$(molt_tilde "$(molt_agent_sandbox_target)")"
  orig="$(molt_agent_sandbox_orig)"
  if [[ $# -gt 0 ]]; then
    state="$1"
  elif ! state="$(molt_agent_sandbox_state)"; then
    echo "$state"
    return 0
  fi
  case "$state" in
    current | missing | stale | foreign)
      command -v apparmor_parser &>/dev/null \
        || echo "apparmor_parser is not installed, so the sandbox profile cannot be loaded" ;;
  esac
  case "$state" in
    current) why="$(molt_agent_sandbox_probe)" || echo "$why" ;;
    missing) echo "$target is missing" ;;
    stale) echo "$target is not $(molt_tilde "$(molt_agent_sandbox_source)")" ;;
    foreign)
      if [[ -e "$orig" ]] && ! cmp -s "$(molt_agent_sandbox_target)" "$orig"; then
        echo "$target is neither molt's nor the distro's kept in $(molt_tilde "$orig"), so molt leaves it"
      else
        echo "$target is not molt's, so bwrap's children are denied the sys_admin Claude Code's sandbox needs"
      fi ;;
    leftover)
      echo "$target is molt's, and this sleeve takes no sandbox profile: it enables no ops or docs agent, or is not Linux"
      [[ -e "$orig" ]] || echo "there is no $(molt_tilde "$orig") to put back" ;;
  esac
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

# --- Starting an agent (ST0007) ---

# The pids, comma-separated, of the Claude Code sessions this user runs under
# the name $1, which Claude Code reads from the argument after --name or after
# --name=; nothing when there are none. Fails when the process table cannot be
# read.
molt_agent_sessions() {
  local running
  running="$(molt_claude_processes)" || return 1
  [[ -n "$running" ]] || return 0
  printf '%s\n' "$running" | awk -v name="$1" '
    { for (i = 2; i <= NF; i++) if (($i == "--name" && $(i + 1) == name) || $i == "--name=" name) { print $1; next } }' \
    | paste -sd, - | sed 's/,/, /g'
}

# Why the agent named $1, with the role $2, enabled $3 and the harness $4, as
# molt_agents prints them, cannot start now, with the fix; nothing when it can.
# The first found of: not enabled; a harness other than claude; a role the user
# repo does not define; a home that is not current; on a sleeve that declares
# a config dir, a shell whose CLAUDE_CONFIG_DIR is another, compared as the
# home guard compares them, since the guard would refuse the session's first
# prompt; a session of that name running, or a process table that cannot say;
# and no claude on PATH.
molt_agent_start_fault() {
  local name="$1" role="$2" enabled="$3" harness="$4" fault state declared pids
  if [[ "$enabled" != true ]]; then
    echo "$name is not enabled on this sleeve: its [[agent]] entry in molt.toml says enabled = $enabled"
    return 0
  fi
  if [[ "$harness" != claude ]]; then
    echo "$name cannot start: its [[agent]] entry names harness $harness, and claude is the only one"
    return 0
  fi
  # A resleeve cannot define a role, so an undefined one says what is missing.
  fault="$(molt_agent_role_fault "$role")"
  if [[ -n "$fault" ]]; then
    echo "$name cannot start: $fault"
    return 0
  fi
  state="$(molt_agent_currency "$name" "$role")"
  if [[ "$state" != current ]]; then
    echo "$name's home is $state: run molt resleeve, then start it"
    return 0
  fi

  if ! declared="$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR)"; then
    echo "MOLT_CLAUDE_CONFIG_DIR could not be read: $declared"
    return 0
  fi
  if [[ -n "$declared" ]]; then
    if ! molt_claude_config_dir_is "$declared"; then
      echo "this shell's CLAUDE_CONFIG_DIR is ${CLAUDE_CONFIG_DIR:-unset}, and this sleeve's is $(molt_tilde "$declared"): start agents from a shell opened after the move, which sources $(molt_tilde "$(molt_claude_env_file)")"
      return 0
    fi
  fi

  if ! pids="$(molt_agent_sessions "$name")"; then
    echo "pgrep could not list processes, so whether $name is already running is unknown"
    return 0
  fi
  if [[ -n "$pids" ]]; then
    echo "$name is already running (pid $pids): go to that session, or quit it first"
    return 0
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "claude is not on PATH"
  fi
}

# --- molt agent ---

_agent_usage() {
  echo "Usage: molt agent list"
  echo "       molt agent roles"
  echo "       molt agent start <role> [-- <claude args>]"
  echo "       molt agent home <role>"
  echo "       molt agent config <role>"
  echo "An agent is named by its role on this sleeve, or by its name, <hostname>-<role>."
}

# This sleeve's agents, as molt_agents prints them. Fails, saying why, when the
# user repo cannot be found, the sleeve has no molt.toml, or its [[agent]]
# entries cannot be read. A host with no name has no instance to find a
# molt.toml in, which is not the same as having none, so molt_agents answers.
_agent_declared() {
  if ! molt_find_user_repo >/dev/null 2>&1; then
    molt_error "molt agent: the user repo cannot be found, so this sleeve's agents cannot be read"
    return 1
  fi
  if molt_hostname >/dev/null 2>&1 && ! molt_find_manifest >/dev/null 2>&1; then
    molt_error "molt agent: this sleeve has no molt.toml, so it declares no agents"
    return 1
  fi
  if ! molt_agents; then
    molt_error "molt agent: the [[agent]] entries in molt.toml could not be read"
    return 1
  fi
}

# The entry of the agent $1 names, by its role or its name, as molt_agents
# prints it. No name prints the usage; an undeclared one fails, listing the
# declared agents.
_agent_entry() {
  local want="$1" agents entry
  if [[ -z "$want" ]]; then
    _agent_usage >&2
    return 1
  fi
  agents="$(_agent_declared)" || return 1
  if ! entry="$(molt_agent_named "$want" "$agents")"; then
    molt_error "molt agent: $want is not declared on this sleeve; declared: $(printf '%s\n' "$agents" | cut -f1 | paste -sd, - | sed 's/,/, /g; s/^$/none/')"
    return 1
  fi
  echo "$entry"
}

# Every agent this sleeve declares: name, role, enabled, the state of its home,
# and the home. Faults in the entries themselves follow, and fail the command.
_agent_list() {
  local agents name role enabled harness
  agents="$(_agent_declared)" || return 1
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

# The roles this sleeve declares, one a line, in manifest order, a disabled one
# marked, since molt agent start refuses it. `roles list` is the same.
_agent_roles() {
  local agents
  case "${1:-list}" in
    list) ;;
    *) _agent_usage; return 1 ;;
  esac
  agents="$(_agent_declared)" || return 1
  [[ -z "$agents" ]] || printf '%s\n' "$agents" | awk -F'\t' '{ print $2 ($3 == "true" ? "" : " (disabled)") }'
}

# The home of the agent $1 names, as cd "$(molt agent home sysadm)" wants it.
_agent_home() {
  local entry name rest
  entry="$(_agent_entry "${1:-}")" || return 1
  IFS=$'\t' read -r name rest <<< "$entry"
  molt_agent_home "$name"
}

# Starts the agent $1 names in its home as `claude start --name <name>`, the
# word start its first prompt and what follows -- after it, in place of this
# process. Where molt_agent_start_fault gives a reason it cannot start, names
# it and starts nothing (ST0007).
_agent_start() {
  local entry name role enabled harness home fault
  entry="$(_agent_entry "${1:-}")" || return 1
  shift
  [[ "${1:-}" != -- ]] || shift
  IFS=$'\t' read -r name role enabled harness <<< "$entry"
  fault="$(molt_agent_start_fault "$name" "$role" "$enabled" "$harness")"
  if [[ -n "$fault" ]]; then
    molt_error "molt agent: $fault"
    return 1
  fi
  home="$(molt_agent_home "$name")"
  if ! cd "$home"; then
    molt_error "molt agent: cannot enter $(molt_tilde "$home")"
    return 1
  fi
  molt_info "Starting $name in $(molt_tilde "$home")"
  exec claude start --name "$name" "$@"
}

# Whether this sleeve's sandbox profile is in place, for an agent the sandbox
# fences, on one line: in place, none needed, or its faults.
_agent_sandbox_line() {
  local state faults
  if ! state="$(molt_agent_sandbox_state)"; then
    echo "$state"
    return 0
  fi
  faults="$(molt_agent_sandbox_faults "$state")"
  if [[ -n "$faults" ]]; then
    printf '%s\n' "$faults" | awk 'NR > 1 { printf "; " } { printf "%s", $0 } END { print "" }'
  elif [[ "$state" == current ]]; then
    echo "in place: $(molt_tilde "$(molt_agent_sandbox_target)")"
  else
    echo "none needed on this sleeve"
  fi
}

# The agent $1 names: its role, harness, home, each rendered file's state, the
# settings files read for it, and the permission rules in effect there, each
# tagged with its layer. An undeclared one fails, listing the declared ones.
_agent_config() {
  local entry name role enabled harness home states file state template layer path rules
  entry="$(_agent_entry "${1:-}")" || return 1
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
  printf '  %-9s %s\n' guard "$(molt_agent_guard_state "$home")"
  case "$role" in
    ops | docs) printf '  %-9s %s\n' sandbox "$(_agent_sandbox_line)" ;;
  esac

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

# molt agent list | roles | start <role> [-- <args>] | home <role> | config <role>
cmd_agent() {
  case "${1:-}" in
    list)   _agent_list ;;
    roles)  shift; _agent_roles "$@" ;;
    start)  shift; _agent_start "$@" ;;
    home)   shift; _agent_home "$@" ;;
    config) shift; _agent_config "$@" ;;
    *)      _agent_usage; return 1 ;;
  esac
}
