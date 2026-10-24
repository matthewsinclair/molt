#!/usr/bin/env bash
# claude.sh — Liberator: Claude Code configuration
# Frees you from re-teaching every sleeve the same keybindings, rules and status
# line, and, on a sleeve that declares MOLT_CLAUDE_CONFIG_DIR, from Claude Code
# keeping its state in $HOME (ST0006).

# Every link claude_install makes, one "source<TAB>target" line each, for the
# sources the user repo has. check, install and verify all read this one list.
# The rest of the config dir is machine-local state -- sessions, transcripts,
# project history, credentials -- and must not be linked into a shared repo.
_claude_links() {
  local user_repo="$1" dir name
  dir="$(molt_claude_config_dir)"
  # Keybindings, and the user-scope rules every session on the sleeve reads.
  for name in keybindings.json CLAUDE.md AGENTS.md; do
    if [[ -f "$user_repo/config/claude/$name" ]]; then
      printf '%s\t%s\n' "$user_repo/config/claude/$name" "$dir/$name"
    fi
  done
  # The layout of the status line, which ccstatusline draws.
  if [[ -f "$user_repo/config/ccstatusline/settings.json" ]]; then
    printf '%s\t%s\n' "$user_repo/config/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
  fi
}

# --- The user settings.json ---
#
# settings.json in the config dir is never linked: it holds each sleeve's own
# permissions, hooks and plugins. Molt writes its own values into it and
# leaves every other key as it was: the statusLine, from the user repo's
# config/claude/statusline.json when it has one, the attribution Claude Code
# writes into commits and pull requests, from config/claude/attribution.json
# when it has one, and, on a sleeve that declares its config dir, the hook that
# refuses a launch in $HOME. Each is named by a label for messages, a file
# holding the JSON object molt writes, and two jq filters with that object
# bound to $want: one reads the value as settings.json holds it, null when it
# holds none, and one writes it in. jq -S compares, so key order and layout are
# not differences; this liberator checks for jq itself.

_CLAUDE_STATUSLINE_GET='.statusLine'
# shellcheck disable=SC2016 # $want is jq's, not the shell's
_CLAUDE_STATUSLINE_SET='.statusLine = $want'
_CLAUDE_ATTRIBUTION_GET='.attribution'
# shellcheck disable=SC2016 # $want is jq's, not the shell's
_CLAUDE_ATTRIBUTION_SET='.attribution = $want'
# The hook's entry and filters are molt_claude_hook_entry, MOLT_CLAUDE_HOOK_GET
# and MOLT_CLAUDE_HOOK_SET in lib/molt.sh: the agents liberator writes the same
# entry into each home's settings (issue 0030).

# The statusLine the user repo $1 declares, as a file, when it declares one.
_claude_statusline() {
  if [[ -f "$1/config/claude/statusline.json" ]]; then
    echo "$1/config/claude/statusline.json"
  fi
}

# The attribution the user repo $1 declares, as a file, when it declares one.
_claude_attribution() {
  if [[ -f "$1/config/claude/attribution.json" ]]; then
    echo "$1/config/claude/attribution.json"
  fi
}

# Names why the user settings.json does not carry the value that $1 labels, $2
# holds and the filter $3 reads, and prints nothing when it does. Returns
# non-zero when molt cannot tell, or must not write the file.
_claude_settings_fault() {
  local label="$1" source="$2" get="$3" settings want have
  settings="$(molt_claude_config_dir)/settings.json"
  if ! command -v jq &>/dev/null; then
    echo "cannot be checked: jq is not installed"
    return 1
  fi
  if ! want="$(jq -eS 'select(type == "object")' "$source" 2>/dev/null)"; then
    echo "cannot be checked: $source holds no $label object"
    return 1
  fi
  # Writing replaces the file, which would silently turn a link into a copy.
  if [[ -L "$settings" ]]; then
    echo "is a symlink to $(readlink "$settings"); it must not be linked, so molt will not write it"
    return 1
  fi
  if [[ ! -f "$settings" ]]; then
    echo "is missing"
  elif ! have="$(jq -S --argjson want "$want" \
      "if type == \"object\" then $get else error(\"not an object\") end" "$settings" 2>/dev/null)"; then
    echo "is not a JSON object"
    return 1
  elif [[ -z "$have" ]]; then
    echo "is empty"
  elif [[ "$have" == "null" ]]; then
    echo "has no $label"
  elif [[ "$have" != "$want" ]]; then
    echo "has a different $label"
  fi
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, why the
# user settings.json does not carry the value that the rest of the arguments
# name, as _claude_settings_fault takes them. Returns non-zero when it reported
# one.
_claude_report_settings_fault() {
  local log="$1" prefix="$2" fault
  shift 2
  if ! fault="$(_claude_settings_fault "$@")" || [[ -n "$fault" ]]; then
    "$log" "${prefix}$(molt_tilde "$(molt_claude_config_dir)/settings.json") $fault"
    return 1
  fi
}

# Writes into the user settings.json the value that $1 labels, $2 holds and the
# filter $3 reads, with the filter $4, and changes no other key. A file that
# already carries it is left alone; one that does not is kept beside it first.
_claude_settings_merge() {
  local label="$1" source="$2" get="$3" set="$4" settings shown fault current backup why
  settings="$(molt_claude_config_dir)/settings.json"
  shown="$(molt_tilde "$settings")"
  if ! fault="$(_claude_settings_fault "$label" "$source" "$get")"; then
    molt_error "claude: $shown $fault"
    return 1
  fi
  [[ -n "$fault" ]] || return 0

  if [[ -f "$settings" ]]; then
    backup="${settings}.molt-backup.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$settings" "$backup"; then
      molt_error "claude: could not back up $shown, so its $label was not written"
      return 1
    fi
    molt_warn "Backing up existing file: $settings -> $backup"
  fi
  current="$settings"
  [[ -f "$current" ]] || current=/dev/null
  # An absent or empty settings.json merges as {}.
  # shellcheck disable=SC2016 # $new, $cur and $want are jq's, not the shell's
  if ! why="$(molt_settings_write "$settings" jq -n --slurpfile cur "$current" --slurpfile new "$source" \
      '$new[0] as $want | ($cur[0] // {}) | '"$set")"; then
    molt_error "claude: $shown $why, so its $label was not written"
    return 1
  fi
  molt_info "claude: $label written into $shown"
}

# --- The config dir ---
#
# A sleeve that declares MOLT_CLAUDE_CONFIG_DIR in its vars.sh keeps Claude
# Code's state there, rather than in ~/.claude and ~/.claude.json. Nothing below
# runs on a sleeve that declares none, so hv could declare it sleeve by sleeve,
# as each was ready to move (ST0006 WP04). On one that does, claude_install
# moves the state once, with the paths into it that its settings name,
# publishes CLAUDE_CONFIG_DIR only when the state is where it points, and
# installs the hook that refuses a launch in $HOME. A variable published
# before the move would start the next Claude empty in the new dir, and the
# move would then meet a dir that is no longer empty.

# Prints the config dir this sleeve declares, or nothing when it declares none.
# Fails, printing why instead, when the value cannot be read or used: a path
# molt_env_value_fault refuses, or $HOME, ~/.claude or anything under it. It fails
# too when molt_agt_dir_fault refuses MOLT_AGT_DIR: the home guard is published
# with the config dir and rendered with the agents root, which the agents
# liberator makes the homes under and asks the same of (AC014).
_claude_declared_dir() {
  local dir fault
  if ! dir="$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR)"; then
    echo "MOLT_CLAUDE_CONFIG_DIR could not be read: $dir"
    return 1
  fi
  [[ -n "$dir" ]] || return 0
  fault="$(molt_env_value_fault MOLT_CLAUDE_CONFIG_DIR "$dir" path)"
  if [[ -z "$fault" ]]; then
    fault="$(molt_agt_dir_fault)"
  fi
  if [[ -n "$fault" ]]; then
    echo "$fault"
    return 1
  fi
  case "$dir" in
    "$HOME" | "$HOME/.claude" | "$HOME/.claude/"*)
      echo "MOLT_CLAUDE_CONFIG_DIR must be a directory of its own, not $(molt_tilde "$dir")"
      return 1 ;;
  esac
  echo "$dir"
}

# What of Claude Code's state is in $HOME: "~/.claude", "~/.claude.json", both
# joined by "and", or nothing.
_claude_home_items() {
  local items="" item
  for item in .claude .claude.json; do
    if [[ -e "$HOME/$item" || -L "$HOME/$item" ]]; then
      items="${items:+$items and }~/$item"
    fi
  done
  echo "$items"
}

# The entries of the directory $1 for a message: the first five by name, then
# how many more. Nothing when it is empty or absent.
_claude_contents() {
  [[ -d "$1" ]] || return 0
  # Every stage reads all of its input, so none writes into a closed pipe
  # (issue 0008).
  find "$1" -mindepth 1 -maxdepth 1 | sed 's|.*/||' | sort | awk '
    NR <= 5 { out = out (NR > 1 ? ", " : "") $0 }
    END { if (NR > 5) out = out " and " NR - 5 " more"; if (out != "") print out }
  '
}

# Where Claude Code's state is, for the declared config dir $1, as one word,
# and for "blocked" a tab and the reason:
#   moved    nothing at ~/.claude or ~/.claude.json, and $1 is a directory
#   none     nothing at either and no $1: Claude Code has not run here
#   home     ~/.claude is a directory or ~/.claude.json a file, and $1 is
#            absent or empty: the move is pending
#   both     the same, but $1 holds something: molt never merges the two
#   blocked  something molt will not move, or move into
_claude_state() {
  local dir="$1" item
  for item in "$HOME/.claude" "$HOME/.claude.json"; do
    if [[ -L "$item" ]]; then
      printf 'blocked\t%s is a symlink to %s\n' "$(molt_tilde "$item")" "$(readlink "$item")"
      return
    fi
  done
  if [[ -e "$HOME/.claude" && ! -d "$HOME/.claude" ]]; then
    printf 'blocked\t%s is not a directory\n' "$(molt_tilde "$HOME/.claude")"
    return
  fi
  if [[ -e "$HOME/.claude.json" && ! -f "$HOME/.claude.json" ]]; then
    printf 'blocked\t%s is not a file\n' "$(molt_tilde "$HOME/.claude.json")"
    return
  fi
  # A Claude Code once run with CLAUDE_CONFIG_DIR=~/.claude keeps a
  # .claude.json inside it, and moving ~/.claude.json in after it would
  # overwrite it.
  if [[ -e "$HOME/.claude/.claude.json" && -e "$HOME/.claude.json" ]]; then
    printf 'blocked\t%s and %s both exist, and molt will not choose between them\n' \
      "$(molt_tilde "$HOME/.claude/.claude.json")" "$(molt_tilde "$HOME/.claude.json")"
    return
  fi
  if [[ -L "$dir" ]] || { [[ -e "$dir" ]] && [[ ! -d "$dir" ]]; }; then
    printf 'blocked\t%s is not a directory molt can move into\n' "$(molt_tilde "$dir")"
    return
  fi
  if [[ -n "$(_claude_home_items)" ]]; then
    if [[ -n "$(_claude_contents "$dir")" ]]; then
      echo both
    else
      echo home
    fi
  elif [[ -d "$dir" ]]; then
    echo moved
  else
    echo none
  fi
}

# The Claude Code processes this user is running, as molt_claude_processes
# names them, each cut to 100 characters for the refusal that lists them;
# nothing when there are none. Fails when pgrep cannot answer.
_claude_processes() {
  local running
  running="$(molt_claude_processes)" || return 1
  [[ -n "$running" ]] || return 0
  printf '%s\n' "$running" | awk '{ print substr($0, 1, 100) }'
}

# Copies $1 into the directory $2, cloning where the filesystem can: an APFS
# clone costs no space and next to no time, and ~/.claude runs to gigabytes.
_claude_clone() {
  if [[ "$(molt_platform)" == "macos" ]]; then
    cp -cRp "$1" "$2"
  else
    cp -a --reflink=auto "$1" "$2"
  fi
}

# Moves ~/.claude and ~/.claude.json into the config dir $1, which is absent or
# empty, having first copied both beside it. Refuses, naming them, while any
# Claude Code runs: a live session cannot survive its own state moving. Returns
# 1 when it wrote nothing, and 2 when it failed having written something, the
# copies or half of the move, which its message names.
_claude_move() {
  local dir="$1" running backup kept item
  if ! running="$(_claude_processes)"; then
    molt_error "claude: pgrep could not list processes, so whether Claude Code is running is unknown"
    return 1
  fi
  if [[ -n "$running" ]]; then
    molt_error "claude: Claude Code is running, and a live session cannot survive its own state moving:"
    while IFS= read -r item; do
      molt_error "  $item"
    done <<< "$running"
    molt_error "claude: quit every Claude Code on this machine, then run molt resleeve from a plain terminal"
    return 1
  fi

  backup="${dir}.molt-backup.$(date +%Y%m%d%H%M%S)"
  if ! mkdir -p "$backup"; then
    molt_error "claude: could not create $(molt_tilde "$backup") for the copies"
    return 1
  fi
  kept="nothing was moved; the copies are in $(molt_tilde "$backup")"
  for item in "$HOME/.claude" "$HOME/.claude.json"; do
    [[ -e "$item" ]] || continue
    if ! _claude_clone "$item" "$backup/"; then
      molt_error "claude: could not copy $(molt_tilde "$item") into $(molt_tilde "$backup"), so $kept, as far as they got"
      return 2
    fi
  done

  # An empty config dir counts as absent, and rmdir refuses anything else.
  if [[ -d "$dir" ]] && ! rmdir "$dir"; then
    molt_error "claude: could not remove the empty $(molt_tilde "$dir"), so $kept"
    return 2
  fi
  if ! mkdir -p "$(dirname "$dir")"; then
    molt_error "claude: could not create $(molt_tilde "$(dirname "$dir")"), so $kept"
    return 2
  fi
  if [[ -d "$HOME/.claude" ]]; then
    if ! mv "$HOME/.claude" "$dir"; then
      molt_error "claude: could not move ~/.claude to $(molt_tilde "$dir"), so $kept"
      return 2
    fi
  elif ! mkdir "$dir"; then
    molt_error "claude: could not create $(molt_tilde "$dir"), so $kept"
    return 2
  fi
  if [[ -f "$HOME/.claude.json" ]] && ! mv "$HOME/.claude.json" "$dir/.claude.json"; then
    molt_error "claude: ~/.claude.json did not move, so Claude Code's state is split between it and $(molt_tilde "$dir"); move it by hand to $(molt_tilde "$dir")/.claude.json (the copies are in $(molt_tilde "$backup"))"
    return 2
  fi
  molt_info "claude: moved Claude Code's state into $(molt_tilde "$dir"); the copies taken first are in $(molt_tilde "$backup")"
}

# --- Paths into ~/.claude ---
#
# The move takes ~/.claude whole, but a value in the settings.json it takes can
# name a file there by path, and goes on naming the old place: on rhadamanth a
# hook named its script so, and a hook whose script is missing blocks every
# call it guards (issue 0038). So the move rewrites each such path to name the
# config dir, and doctor names any found after it. A path counts in any string
# value, an array's items included, where it starts the value or follows a
# character other than a letter, a digit or one of ._~+@%-, so neither
# $CLAUDE_PROJECT_DIR/.claude/ nor a longer path holding ~/.claude/ is one, and
# nor is ~/.claude.json, or ~/.claude with no slash. It is spelt from the
# absolute home, from ~, or from $HOME or ${HOME} for a shell to expand, and
# keeps its spelling, unless the config dir is not under the home, when it
# becomes absolute. The move and doctor read one list, so they never disagree
# about what counts: each value as its key, a jq path, and as it is and as it
# would be, both as JSON strings, so a line break in one keeps to its line.
# The regexes anchor with \A and \z: Oniguruma's ^ and $ match at any line's
# start and end, so a path starting a value's second line read as the tail of
# a longer path.
# shellcheck disable=SC2016 # $home, $abs, $tilde and $HOME are jq's, not the shell's
_CLAUDE_HOME_PATHS='
  def repoint($from; $to):
    if contains($from) then
      split($from) as $parts
      | reduce range(1; $parts | length) as $i ($parts[0];
          . + (if $parts[$i - 1] | test("[[:alnum:]._~+@%-]\\z") then $from else $to end) + $parts[$i])
    else . end;
  def spelt($home_as):
    if $tilde | startswith("~/") then $home_as + ($tilde | ltrimstr("~")) else $abs end;
  def keyname:
    map(if type == "number" then "[\(.)]"
        elif test("\\A[A-Za-z_][A-Za-z0-9_]*\\z") then ".\(.)"
        else "[\(tojson)]" end)
    | join("") | if startswith(".") then . else "." + . end;
  def home_paths:
    if type == "object" then . else error("not a JSON object") end
    | [paths(type == "string") as $p
       | getpath($p) as $was
       | ($was | repoint($home + "/.claude/"; $abs + "/")
               | repoint("~/.claude/"; $tilde + "/")
               | repoint("$HOME/.claude/"; spelt("$HOME") + "/")
               | repoint("${HOME}/.claude/"; spelt("${HOME}") + "/")) as $is
       | select($is != $was)
       | {path: $p, key: ($p | keyname), was: $was, is: $is}];
  def home_paths_listed: home_paths[] | "\(.key)\t\(.was | tojson)\t\(.is | tojson)";
  def home_paths_rewritten: reduce home_paths[] as $e (.; setpath($e.path; $e.is));
'

# Runs the definition $2 of _CLAUDE_HOME_PATHS on the settings file $3, for the
# config dir $1. The output is raw, so each line it gives is printed as it is.
_claude_home_paths_jq() {
  jq -r --arg home "$HOME" --arg abs "$1" --arg tilde "$(molt_tilde "$1")" \
    "$_CLAUDE_HOME_PATHS $2" "$3"
}

# True when this jq matches regexes, which a build without Oniguruma does not.
_claude_jq_regex() {
  jq -n '"a" | test("a")' &>/dev/null
}

# Each value in the settings file $1 that names a path into ~/.claude, one
# "key<TAB>was<TAB>is" line each, where is names it in the config dir $2
# instead; nothing when there is none, or no file. Fails, printing why instead,
# when it cannot tell.
_claude_home_paths() {
  local settings="$1" dir="$2" listed
  [[ -e "$settings" ]] || return 0
  if ! command -v jq &>/dev/null; then
    echo "cannot be checked: jq is not installed"
    return 1
  fi
  # The definition matches with test(), which a jq built without Oniguruma
  # fails, and that failure read as a malformed file (issue 0045).
  if ! _claude_jq_regex; then
    echo "cannot be checked: jq has no regex support"
    return 1
  fi
  if ! listed="$(_claude_home_paths_jq "$dir" home_paths_listed "$settings" 2>/dev/null)"; then
    echo "is not a JSON object"
    return 1
  fi
  [[ -z "$listed" ]] || printf '%s\n' "$listed"
}

# Rewrites each value naming a path into ~/.claude in the settings.json the
# move has just taken into the config dir $1, to name it there, and names each,
# with its key, as it was and as it is. The move's copies hold the file as it
# was, so none is taken here. Fails, naming each value it left, when it cannot:
# as the merge does, it will not write a symlink, nor will it splice in a config
# dir a shell would split or expand, and a file it cannot read or write it
# leaves as it was.
_claude_repoint() {
  local dir="$1" settings shown listed why key was is
  settings="$dir/settings.json"
  shown="$(molt_tilde "$settings")"
  if ! listed="$(_claude_home_paths "$settings" "$dir")"; then
    molt_error "claude: $shown $listed, so no path into ~/.claude it names was rewritten"
    return 1
  fi
  [[ -n "$listed" ]] || return 0

  if [[ -L "$settings" ]]; then
    why="is a symlink to $(readlink "$settings"), which molt will not write"
  # A command names a path unquoted as often as not, so a dir with a space or
  # a shell's syntax in it would break the command, and doctor would pass it,
  # since it would no longer name ~/.claude (critic-shell, 23 Oct).
  elif [[ "$dir" == *[![:alnum:]._/+@%:,=-]* ]]; then
    why="was left: $(molt_tilde "$dir") holds a character a shell would split or expand, which would break a command naming it"
  elif why="$(molt_settings_write "$settings" _claude_home_paths_jq "$dir" home_paths_rewritten "$settings")"; then
    while IFS=$'\t' read -r key was is; do
      molt_info "claude: rewrote $key in $shown: $was -> $is"
    done <<< "$listed"
    return 0
  fi
  molt_error "claude: $shown $why, so these still name paths under ~/.claude, whose files are in $(molt_tilde "$dir") now; change them by hand:"
  while IFS=$'\t' read -r key was _; do
    molt_error "  $key: $was"
  done <<< "$listed"
  return 1
}

# A directory other than the config dir $1 that Claude Code's state may be in:
# one CLAUDE_CONFIG_DIR names, in this shell or as the env file last published
# it, that exists. Nothing when there is none, as on a sleeve Claude Code has
# not run on. A sleeve that declares a new dir after its move has its state in
# the old one, and publishing the new, empty one would start Claude afresh.
_claude_other_dir() {
  local dir="$1" named
  for named in "${CLAUDE_CONFIG_DIR:-}" "$(molt_env_published CLAUDE_CONFIG_DIR)"; do
    if [[ -n "$named" && "$named" != "$dir" && -d "$named" ]]; then
      echo "$named"
      return
    fi
  done
}

# The files the claude liberator renders for the config dir, one
# "template<TAB>target<TAB>mode" line each: the home guard the hook runs, which
# names no checkout of Molt, so a Molt installed any other way renders the
# same bytes. CLAUDE_CONFIG_DIR itself goes out through the env liberator, from
# claude_env_pairs.
_claude_published() {
  printf '%s\t%s\t%s\n' "${MOLT_ROOT}/templates/claude/claude-home-guard.sh.tmpl" "$HOME/.config/molt/claude-home-guard.sh" 755
}

# CLAUDE_CONFIG_DIR as the env liberator publishes it, one
# "NAME<TAB>scope<TAB>value" line: the declared config dir once Claude Code's
# state is in it, and until then whatever env.sh already publishes, so a
# variable never goes out ahead of the move, nor is dropped while one is
# pending. Nothing on a sleeve that declares no config dir. Fails, printing
# why, when the declared dir cannot be used.
claude_env_pairs() {
  local dir state why value
  if ! dir="$(_claude_declared_dir)"; then
    echo "$dir"
    return 1
  fi
  [[ -n "$dir" ]] || return 0
  IFS=$'\t' read -r state why <<< "$(_claude_state "$dir")"
  if [[ "$state" == moved ]]; then
    value="$dir"
  else
    value="$(molt_env_published CLAUDE_CONFIG_DIR)"
  fi
  [[ -z "$value" ]] || printf 'CLAUDE_CONFIG_DIR\tall\t%s\n' "$value"
}

# Why CLAUDE_CONFIG_DIR would go unpublished on this sleeve, or nothing when it
# would not: the env liberator publishes it, so a molt.toml that names
# liberators and does not enable env leaves env.sh and the GUI file as they
# were, with nothing to keep them. With no manifest every liberator runs.
_claude_env_unlisted_fault() {
  local enabled manifest
  enabled="$(molt_enabled_liberators 2>/dev/null)" || return 0
  [[ -n "$enabled" ]] || return 0
  ! grep -qx env <<< "$enabled" || return 0
  manifest="$(molt_find_manifest 2>/dev/null)" || manifest="this sleeve's molt.toml"
  echo "CLAUDE_CONFIG_DIR is published by the env liberator, which $(molt_tilde "$manifest") does not enable: add a [[liberator]] named env after claude"
}

# A value the home guard at $1 was rendered with: the line after the
# here-document opener, ending in <<'$2', that
# templates/claude/claude-home-guard.sh.tmpl writes, found only in that form.
# MOLT_AGENTS_ROOT names the agents root, and MOLT_CLAUDE_CONFIG_DIR the config
# dir. Nothing when there is no such line.
_claude_guard_line() {
  [[ -f "$1" ]] || return 0
  awk -v end="<<'$2'" '
    found { print; exit }
    $0 ~ /^IFS= read -r [a-z_]+ <</ && substr($0, length($0) - length(end) + 1) == end { found = 1 }
  ' "$1"
}

# The state of the published file $2, rendered from the template $1, on a
# sleeve whose config dir is $3: missing; stale, when its template or this
# sleeve's vars.sh changed after it was rendered; current; or, for the home
# guard, drifted, when the agents root it was rendered with is no longer
# MOLT_AGT_DIR, and misdirected, when the config dir it was rendered with is
# no longer $3. No digest covers either: MOLT_AGT_DIR can come from where molt
# runs, and vars.sh can build the config dir from XDG_CONFIG_HOME.
_claude_published_state() {
  local template="$1" target="$2" dir="$3"
  if [[ ! -e "$target" ]]; then
    echo missing
  elif molt_render_stale "$template" "$target"; then
    echo stale
  elif [[ "$template" != */claude-home-guard.sh.tmpl ]]; then
    echo current
  elif [[ "$(_claude_guard_line "$target" MOLT_AGENTS_ROOT)" != "${MOLT_AGT_DIR:-}" ]]; then
    echo drifted
  elif [[ "$(_claude_guard_line "$target" MOLT_CLAUDE_CONFIG_DIR)" != "$dir" ]]; then
    echo misdirected
  else
    echo current
  fi
}

# Renders the home guard when it is not current, then exports CLAUDE_CONFIG_DIR
# as $1 for the rest of this run, so the links, statusLine and hook written
# after it, and any liberator after this one, land in $1 and none recreates
# ~/.claude. Called only once Claude Code's state is in $1, which is when
# claude_env_pairs gives the env liberator, later in the run, the variable to
# publish in env.sh and the GUI file.
_claude_publish() {
  local dir="$1" template target mode
  while IFS=$'\t' read -r template target mode; do
    [[ -n "$template" ]] || continue
    if [[ "$(_claude_published_state "$template" "$target" "$dir")" != current ]]; then
      molt_render "$template" "$target" || return 1
    fi
    if ! chmod "$mode" "$target"; then
      molt_error "claude: could not make $(molt_tilde "$target") mode $mode"
      return 1
    fi
  done <<< "$(_claude_published)"
  if ! molt_claude_config_dir_is "$dir"; then
    molt_warn "claude: CLAUDE_CONFIG_DIR is not $(molt_tilde "$dir") in this shell. Start Claude Code only from a new shell that sources $(molt_tilde "$(molt_env_file)"), and log out and in for apps started from the GUI"
  fi
  export CLAUDE_CONFIG_DIR="$dir"
}

# Names, when the config dir $1 holds nothing and nothing of Claude Code's is
# in $HOME, the other dir its state may be in; prints nothing otherwise.
_claude_other_dir_fault() {
  local dir="$1" other
  [[ -z "$(_claude_contents "$dir")" ]] || return 0
  other="$(_claude_other_dir "$dir")"
  [[ -n "$other" ]] || return 0
  echo "$(molt_tilde "$dir") holds nothing, and CLAUDE_CONFIG_DIR named $(molt_tilde "$other"), which exists: Claude Code's state may be there. Move it into $(molt_tilde "$dir") by hand, or declare $(molt_tilde "$other") again"
}

# Puts Claude Code's state in the declared config dir $1, moving it out of $HOME
# once, then publishes it. Refuses when it cannot, and says that the variable
# was not published. A move rewrites the paths into ~/.claude that its
# settings.json names; when it cannot, the state is published all the same,
# being in $1 by then, and the run fails after.
_claude_relocate() {
  local dir="$1" state why fault rc=0 repointed=0
  IFS=$'\t' read -r state why <<< "$(_claude_state "$dir")"
  case "$state" in
    moved | none)
      fault="$(_claude_other_dir_fault "$dir")"
      if [[ -n "$fault" ]]; then
        molt_error "claude: $fault"
        _claude_unpublished
        return 1
      fi
      # Neither $HOME nor any dir the variable named holds Claude Code's
      # state: it has not run here, so there is nothing to split.
      if [[ "$state" == none ]] && ! mkdir -p "$dir"; then
        molt_error "claude: could not create $(molt_tilde "$dir")"
        return 1
      fi ;;
    home)
      _claude_move "$dir" || rc=$?
      if [[ $rc -eq 2 ]]; then
        _claude_unpublished changed
        return 1
      elif [[ $rc -ne 0 ]]; then
        _claude_unpublished
        return 1
      fi
      _claude_repoint "$dir" || repointed=1 ;;
    both)
      molt_error "claude: $(molt_tilde "$dir") already holds $(_claude_contents "$dir"), so $(_claude_home_items) did not move into it; molt never merges the two"
      _claude_unpublished
      return 1 ;;
    *)
      molt_error "claude: $why, so Claude Code's state was not moved"
      _claude_unpublished
      return 1 ;;
  esac
  _claude_publish "$dir" || return 1
  return $repointed
}

# Says that CLAUDE_CONFIG_DIR was not published and, unless $1 is "changed",
# that nothing else was changed either: a refusal before anything was written.
_claude_unpublished() {
  if [[ "${1:-}" == "changed" ]]; then
    molt_error "claude: CLAUDE_CONFIG_DIR was not published: no env.sh or GUI file was written"
  else
    molt_error "claude: CLAUDE_CONFIG_DIR was not published: no env.sh or GUI file was written, and nothing else was changed"
  fi
}

# Reports, through $1 after the prefix $2, each published file that is not
# current for the config dir $3, or not the mode it was given. Returns non-zero
# when it reported one.
_claude_report_published_faults() {
  local log="$1" prefix="$2" dir="$3" template target mode had faulted=0
  while IFS=$'\t' read -r template target mode; do
    [[ -n "$template" ]] || continue
    case "$(_claude_published_state "$template" "$target" "$dir")" in
      missing)
        "$log" "${prefix}$(molt_tilde "$target") is missing" ;;
      stale)
        "$log" "${prefix}$(molt_tilde "$target") differs from its template or this sleeve's vars.sh" ;;
      drifted)
        "$log" "${prefix}$(molt_tilde "$target") refuses launches under $(molt_tilde "$(_claude_guard_line "$target" MOLT_AGENTS_ROOT)"), but MOLT_AGT_DIR is $(molt_tilde "${MOLT_AGT_DIR:-}"): re-run molt upgrade" ;;
      misdirected)
        had="$(_claude_guard_line "$target" MOLT_CLAUDE_CONFIG_DIR)"
        case "$had" in
          /*) had="config dir $(molt_tilde "$had")" ;;
          *) had="no config dir" ;;
        esac
        "$log" "${prefix}$(molt_tilde "$target") checks sessions for $had, but this sleeve's is $(molt_tilde "$dir"): re-run molt upgrade" ;;
      *)
        if [[ "$mode" == 755 && ! -x "$target" ]]; then
          "$log" "${prefix}$(molt_tilde "$target") is not executable"
        else
          continue
        fi ;;
    esac
    faulted=1
  done <<< "$(_claude_published)"
  return $faulted
}

# Reports, through $1 after the prefix $2, the links and settings the user repo
# $3 declares that are not in place in the config dir, and the home-launch hook
# too when $4 is "yes". Returns non-zero when it reported any.
_claude_report_config_faults() {
  local log="$1" prefix="$2" user_repo="$3" guarded="$4" statusline attribution ok=0
  molt_report_link_faults "$log" "$prefix" "$(_claude_links "$user_repo")" || ok=1
  statusline="$(_claude_statusline "$user_repo")"
  if [[ -n "$statusline" ]]; then
    _claude_report_settings_fault "$log" "$prefix" statusLine "$statusline" "$_CLAUDE_STATUSLINE_GET" || ok=1
  fi
  attribution="$(_claude_attribution "$user_repo")"
  if [[ -n "$attribution" ]]; then
    _claude_report_settings_fault "$log" "$prefix" attribution "$attribution" "$_CLAUDE_ATTRIBUTION_GET" || ok=1
  fi
  if [[ "$guarded" == "yes" ]]; then
    _claude_report_settings_fault "$log" "$prefix" "home-launch hook" "$(molt_claude_hook_entry)" "$MOLT_CLAUDE_HOOK_GET" || ok=1
  fi
  return $ok
}

# Reports, through $1 after the prefix $2, each value in the settings.json of
# the config dir $3 that still names a path into ~/.claude, with its key. The
# move rewrites those it finds, so one here came after it, or the rewrite
# failed. Returns non-zero when it reported one, or could not tell.
_claude_report_home_paths() {
  local log="$1" prefix="$2" dir="$3" settings shown listed key was
  settings="$dir/settings.json"
  shown="$(molt_tilde "$settings")"
  if ! listed="$(_claude_home_paths "$settings" "$dir")"; then
    "$log" "${prefix}$shown $listed, so whether it names a path under ~/.claude is unknown"
    return 1
  fi
  [[ -n "$listed" ]] || return 0
  while IFS=$'\t' read -r key was _; do
    "$log" "${prefix}$shown $key still names a path under ~/.claude, and this sleeve's config dir is $(molt_tilde "$dir"): $was"
  done <<< "$listed"
  return 1
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, everything
# standing between this sleeve and the Claude Code config the user repo $3
# declares. Returns non-zero when it reported anything.
_claude_report_faults() {
  local log="$1" prefix="$2" user_repo="$3" dir state why fault items verb=is ok=0
  if ! dir="$(_claude_declared_dir)"; then
    "$log" "${prefix}$dir"
    return 1
  fi
  if [[ -z "$dir" ]]; then
    _claude_report_config_faults "$log" "$prefix" "$user_repo" no
    return
  fi

  fault="$(_claude_env_unlisted_fault)"
  if [[ -n "$fault" ]]; then
    "$log" "${prefix}$fault"
    ok=1
  fi

  IFS=$'\t' read -r state why <<< "$(_claude_state "$dir")"
  case "$state" in
    moved | none)
      fault="$(_claude_other_dir_fault "$dir")"
      if [[ -n "$fault" ]]; then
        "$log" "${prefix}$fault"
        return 1
      fi
      if [[ "$state" == none ]]; then
        "$log" "${prefix}$(molt_tilde "$dir"), this sleeve's config dir, does not exist yet"
        ok=1
      fi ;;
    home)
      "$log" "${prefix}Claude Code's state is still in $(_claude_home_items), and this sleeve's config dir is $(molt_tilde "$dir"): quit every Claude Code, then run molt resleeve to move it"
      return 1 ;;
    both)
      items="$(_claude_home_items)"
      [[ "$items" != *" and "* ]] || verb=are
      "$log" "${prefix}$items $verb present while the config dir is $(molt_tilde "$dir"): a launch path missed CLAUDE_CONFIG_DIR, or a move did not finish"
      return 1 ;;
    *)
      "$log" "${prefix}$why"
      return 1 ;;
  esac

  # First: doctor shows only the start of a failing check's report, and a hook
  # whose script has moved blocks every call it guards.
  _claude_report_home_paths "$log" "$prefix" "$dir" || ok=1
  if [[ -z "${CLAUDE_CONFIG_DIR:-}" ]]; then
    "$log" "${prefix}CLAUDE_CONFIG_DIR is not set where molt runs; $(molt_tilde "$(molt_env_file)") sets it in a shell that sources it"
    ok=1
  elif ! molt_claude_config_dir_is "$dir"; then
    "$log" "${prefix}CLAUDE_CONFIG_DIR is $(molt_tilde "$CLAUDE_CONFIG_DIR"), not this sleeve's config dir $(molt_tilde "$dir")"
    ok=1
  fi
  _claude_report_published_faults "$log" "$prefix" "$dir" || ok=1
  # Read where Claude Code reads once the variable is set, not where an
  # environment that missed it would look.
  CLAUDE_CONFIG_DIR="$dir" _claude_report_config_faults "$log" "$prefix" "$user_repo" yes || ok=1
  return $ok
}

claude_check() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  _claude_report_faults molt_info "claude: " "$user_repo"
}

claude_install() {
  local user_repo dir links statusline attribution
  user_repo="$(molt_find_user_repo)" || return 1

  if ! dir="$(_claude_declared_dir)"; then
    molt_error "claude: $dir"
    return 1
  fi
  # On a refusal nothing below runs either: the links, settings and hook would
  # land in a ~/.claude that is about to move, or in the config dir the move
  # must find empty. Nor after a move whose paths could not be rewritten: the
  # run fails there, and the next one writes them.
  if [[ -n "$dir" ]]; then
    _claude_relocate "$dir" || return 1
  fi

  # Claude Code creates its config dir itself, but a sleeve may be resleeved
  # before Claude Code has ever run on it. This is the accessor's answer, so
  # once CLAUDE_CONFIG_DIR is set it is never ~/.claude, which it would
  # otherwise recreate exactly as doctor faults it.
  mkdir -p "$(molt_claude_config_dir)" || return 1

  links="$(_claude_links "$user_repo")"
  statusline="$(_claude_statusline "$user_repo")"
  attribution="$(_claude_attribution "$user_repo")"
  if [[ -z "$links" && -z "$statusline" && -z "$attribution" && -z "$dir" ]]; then
    molt_warn "claude: nothing to manage -- $user_repo/config has no Claude Code config"
  fi

  molt_link_all "$links" || return 1
  if [[ -n "$statusline" ]]; then
    _claude_settings_merge statusLine "$statusline" "$_CLAUDE_STATUSLINE_GET" "$_CLAUDE_STATUSLINE_SET" || return 1
  fi
  if [[ -n "$attribution" ]]; then
    _claude_settings_merge attribution "$attribution" "$_CLAUDE_ATTRIBUTION_GET" "$_CLAUDE_ATTRIBUTION_SET" || return 1
  fi
  if [[ -n "$dir" ]]; then
    _claude_settings_merge "home-launch hook" "$(molt_claude_hook_entry)" "$MOLT_CLAUDE_HOOK_GET" "$MOLT_CLAUDE_HOOK_SET" || return 1
  fi
  if [[ -n "$dir" ]]; then
    local fault
    fault="$(_claude_env_unlisted_fault)"
    if [[ -n "$fault" ]]; then
      molt_error "claude: $fault"
      return 1
    fi
  fi

  molt_info "Liberator complete: claude"
}

claude_verify() {
  local errors=0

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -z "$user_repo" ]]; then
    molt_error "VERIFY FAIL: user config repo not found, so no Claude Code config was checked"
    errors=1
  else
    _claude_report_faults molt_error "VERIFY FAIL: " "$user_repo" || errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: claude liberator is fully operational"
  fi
  return $errors
}
