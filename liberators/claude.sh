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
# permissions, hooks and plugins. Molt writes two values into it and leaves
# every other key as it was: the statusLine, from the user repo's
# config/claude/statusline.json when it has one, and, on a sleeve that declares
# its config dir, the hook that refuses a launch in $HOME. Each is named by a
# label for messages, a file holding the JSON object molt writes, and two jq
# filters with that object bound to $want: one reads the value as settings.json
# holds it, null when it holds none, and one writes it in. jq -S compares, so
# key order and layout are not differences; the dev-tools liberator already
# requires jq on every sleeve.

_CLAUDE_STATUSLINE_GET='.statusLine'
# shellcheck disable=SC2016 # $want is jq's, not the shell's
_CLAUDE_STATUSLINE_SET='.statusLine = $want'
# The hook's entry and filters are molt_claude_hook_entry, MOLT_CLAUDE_HOOK_GET
# and MOLT_CLAUDE_HOOK_SET in lib/molt.sh: the agents liberator writes the same
# entry into each home's settings (issue 0030).

# The statusLine the user repo $1 declares, as a file, when it declares one.
_claude_statusline() {
  if [[ -f "$1/config/claude/statusline.json" ]]; then
    echo "$1/config/claude/statusline.json"
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
# already carries it is left alone. Every step is checked by hand: resleeve runs
# install inside an `if`, where set -e does not apply, so a failed copy or
# rename would otherwise run on to "written".
_claude_settings_merge() {
  local label="$1" source="$2" get="$3" set="$4" settings shown fault current tmp backup
  settings="$(molt_claude_config_dir)/settings.json"
  shown="$(molt_tilde "$settings")"
  if ! fault="$(_claude_settings_fault "$label" "$source" "$get")"; then
    molt_error "claude: $shown $fault"
    return 1
  fi
  [[ -n "$fault" ]] || return 0

  current="$settings"
  [[ -f "$current" ]] || current=/dev/null
  tmp="$(mktemp "${settings}.XXXXXX")" || return 1
  # cp -p gives tmp the file's mode, which the write below keeps.
  if [[ -f "$settings" ]] && ! cp -p "$settings" "$tmp"; then
    rm -f "$tmp"
    molt_error "claude: could not copy $shown, so its $label was not written"
    return 1
  fi
  # An absent or empty settings.json merges as {}.
  if ! jq -n --slurpfile cur "$current" --slurpfile new "$source" \
      '$new[0] as $want | ($cur[0] // {}) | '"$set" >"$tmp"; then
    rm -f "$tmp"
    molt_error "claude: $label not written; $shown was left as it was"
    return 1
  fi

  if [[ -f "$settings" ]]; then
    backup="${settings}.molt-backup.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$settings" "$backup"; then
      rm -f "$tmp"
      molt_error "claude: could not back up $shown, so its $label was not written"
      return 1
    fi
    molt_warn "Backing up existing file: $settings -> $backup"
  fi
  # A rename, so Claude Code, which watches this file, never reads half of it.
  if ! mv -f "$tmp" "$settings"; then
    rm -f "$tmp"
    molt_error "claude: $label not written; $shown was left as it was"
    return 1
  fi
  molt_info "claude: $label written into $shown"
}

# --- The config dir ---
#
# A sleeve that declares MOLT_CLAUDE_CONFIG_DIR in its vars.sh keeps Claude
# Code's state there, rather than in ~/.claude and ~/.claude.json. Nothing below
# runs on a sleeve that declares none: hv declares it sleeve by sleeve, as each
# is ready to move (ST0006 WP04). On one that does, claude_install moves the
# state once, publishes CLAUDE_CONFIG_DIR only when the state is where it
# points, and installs the hook that refuses a launch in $HOME. A variable
# published before the move would start the next Claude empty in the new dir,
# and the move would then meet a dir that is no longer empty.

# Why the path $2, named $1, cannot be written as it stands into the files that
# publish it, or nothing when it can. They are env.sh, a plist and an
# environment.d file, and env.sh is read back, so a path is refused rather than
# rewritten: a copy tidied here would be compared with files that hold the
# untidied one, and a path spelt with . or .. would get past the comparison
# with ~/.claude. Refused: anything molt_path_fault refuses, a character any
# of those files reads as syntax, and trailing whitespace, which environment.d
# strips. environment.d expands $ and backslash escapes, never % specifiers,
# which belong to unit files.
_claude_path_fault() {
  local name="$1" path="$2" fault
  fault="$(molt_path_fault "$name" "$path")"
  if [[ -n "$fault" ]]; then
    echo "$fault"
    return
  fi
  case "$path" in
    *[\"\'\$\`\\\<\>\&]* | *$'\n'*)
      echo "$name holds a character env.sh, a plist or environment.d would read as syntax: $path" ;;
    *[[:space:]])
      echo "$name ends in whitespace, which environment.d would strip: '$path'" ;;
  esac
}

# Prints the config dir this sleeve declares, or nothing when it declares none.
# Fails, printing why instead, when the value cannot be read or used: a path
# _claude_path_fault refuses, or $HOME, ~/.claude or anything under it. It fails
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
  fault="$(_claude_path_fault MOLT_CLAUDE_CONFIG_DIR "$dir")"
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

# A Claude Code process: the native binary, which runs with argv0 claude, by
# name or by an absolute path (the desktop app's has a space in it), or an npm
# install, which node runs by its bin link or its cli.js. Matched against the
# whole command line with pgrep -f; pgrep -x matches a process name, which
# misses running processes on macOS (board watchout 6). Every arm is anchored
# on argv0, so `ls ~/.config/claude`, a grep or an npm ls naming the package is
# not Claude Code. The path arm allows a space only where the next character
# starts no other argument, ie is not / or -. A relative ./claude is not
# matched.
_CLAUDE_PROCESS_PATTERN='^(/[^ ]*( [^/ -][^ ]*)*/)?claude( |$)|^([^ ]*/)?node ([^ ]*/)?claude( |$)|^([^ ]*/)?node .*@anthropic-ai/claude-code/cli'

# The Claude Code processes this user is running, "pid command" a line, cut to
# 100 characters; nothing when there are none. ps names them, because procps'
# pgrep -l prints a process's name and macOS's its arguments; a process that
# has gone by then is named by its pid alone. Fails when pgrep cannot answer.
_claude_processes() {
  local pids named rc=0 ancestors=()
  # macOS's pgrep leaves out its own ancestors unless given -a, so molt run from
  # inside a Claude Code session would not see that session, the very one whose
  # state it is about to move. procps' pgrep leaves out only itself, and its -a
  # means something else.
  if [[ "$(molt_platform)" == "macos" ]]; then
    ancestors=(-a)
  fi
  pids="$(pgrep ${ancestors+"${ancestors[@]}"} -u "$(id -u)" -f "$_CLAUDE_PROCESS_PATTERN")" || rc=$?
  case "$rc" in
    0) ;;
    1) return 0 ;;
    *) return 1 ;;
  esac
  # A command line can hold newlines; only a line that starts with a pid is one
  # of ps's rows.
  named="$( { ps -o pid=,args= -p "$(printf '%s\n' "$pids" | paste -sd, -)" 2>/dev/null || true; } \
             | awk '$1 ~ /^[0-9]+$/ { sub(/^ +/, ""); print substr($0, 1, 100) }')"
  if [[ -n "$named" ]]; then
    echo "$named"
  else
    echo "$pids"
  fi
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

# The env file ~/.zshenv sources to set CLAUDE_CONFIG_DIR.
_claude_env_file() {
  echo "$HOME/.config/molt/env.sh"
}

# The config dir the env file last published, when there is one: the value of
# the export line templates/claude/env.sh.tmpl writes, found only in that form.
_claude_env_dir() {
  local env_file
  env_file="$(_claude_env_file)"
  [[ -f "$env_file" ]] || return 0
  sed -n 's/^export CLAUDE_CONFIG_DIR="\(.*\)"$/\1/p' "$env_file"
}

# A directory other than the config dir $1 that Claude Code's state may be in:
# one CLAUDE_CONFIG_DIR names, in this shell or as the env file last published
# it, that exists. Nothing when there is none, as on a sleeve Claude Code has
# not run on. A sleeve that declares a new dir after its move has its state in
# the old one, and publishing the new, empty one would start Claude afresh.
_claude_other_dir() {
  local dir="$1" named
  for named in "${CLAUDE_CONFIG_DIR:-}" "$(_claude_env_dir)"; do
    if [[ -n "$named" && "$named" != "$dir" && -d "$named" ]]; then
      echo "$named"
      return
    fi
  done
}

# The files that publish the config dir, one "template<TAB>target<TAB>mode"
# line each: env.sh, which ~/.zshenv sources; the GUI environment on this
# platform; and the home guard the hook runs. None of them names a checkout of
# Molt, so a Molt installed any other way renders the same bytes.
_claude_published() {
  local t="${MOLT_ROOT}/templates/claude"
  printf '%s\t%s\t%s\n' "$t/env.sh.tmpl" "$(_claude_env_file)" 644
  case "$(molt_platform)" in
    macos)
      printf '%s\t%s\t%s\n' "$t/com.molt.claude-config-dir.plist.tmpl" \
        "$HOME/Library/LaunchAgents/com.molt.claude-config-dir.plist" 644 ;;
    linux)
      printf '%s\t%s\t%s\n' "$t/claude.conf.tmpl" "$HOME/.config/environment.d/claude.conf" 644 ;;
  esac
  printf '%s\t%s\t%s\n' "$t/claude-home-guard.sh.tmpl" "$HOME/.config/molt/claude-home-guard.sh" 755
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

# Renders each published file that is not current, then exports
# CLAUDE_CONFIG_DIR as $1 for the rest of this run, so the links, statusLine and
# hook written after it, and any liberator after this one, land in $1 and none
# recreates ~/.claude. Called only once Claude Code's state is in $1. Nothing
# here runs launchctl or systemctl: the GUI file takes effect at the next login.
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
  if [[ "${CLAUDE_CONFIG_DIR:-}" != "$dir" ]]; then
    molt_warn "claude: CLAUDE_CONFIG_DIR is not $(molt_tilde "$dir") in this shell. Start Claude Code only from a new shell that sources ~/.config/molt/env.sh, and log out and in for apps started from the GUI"
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
# was not published.
_claude_relocate() {
  local dir="$1" state why fault rc=0
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
      fi ;;
    both)
      molt_error "claude: $(molt_tilde "$dir") already holds $(_claude_contents "$dir"), so $(_claude_home_items) did not move into it; molt never merges the two"
      _claude_unpublished
      return 1 ;;
    *)
      molt_error "claude: $why, so Claude Code's state was not moved"
      _claude_unpublished
      return 1 ;;
  esac
  _claude_publish "$dir"
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
  local log="$1" prefix="$2" user_repo="$3" guarded="$4" statusline ok=0
  molt_report_link_faults "$log" "$prefix" "$(_claude_links "$user_repo")" || ok=1
  statusline="$(_claude_statusline "$user_repo")"
  if [[ -n "$statusline" ]]; then
    _claude_report_settings_fault "$log" "$prefix" statusLine "$statusline" "$_CLAUDE_STATUSLINE_GET" || ok=1
  fi
  if [[ "$guarded" == "yes" ]]; then
    _claude_report_settings_fault "$log" "$prefix" "home-launch hook" "$(molt_claude_hook_entry)" "$MOLT_CLAUDE_HOOK_GET" || ok=1
  fi
  return $ok
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

  if [[ -z "${CLAUDE_CONFIG_DIR:-}" ]]; then
    "$log" "${prefix}CLAUDE_CONFIG_DIR is not set where molt runs; ~/.config/molt/env.sh sets it in a shell that sources it"
    ok=1
  elif [[ "$CLAUDE_CONFIG_DIR" != "$dir" ]]; then
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
  local user_repo dir links statusline
  user_repo="$(molt_find_user_repo)" || return 1

  if ! dir="$(_claude_declared_dir)"; then
    molt_error "claude: $dir"
    return 1
  fi
  # On a refusal nothing below runs either: the links, statusLine and hook would
  # land in a ~/.claude that is about to move, or in the config dir the move
  # must find empty.
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
  if [[ -z "$links" && -z "$statusline" && -z "$dir" ]]; then
    molt_warn "claude: nothing to manage -- $user_repo/config has no Claude Code config"
  fi

  molt_link_all "$links" || return 1
  if [[ -n "$statusline" ]]; then
    _claude_settings_merge statusLine "$statusline" "$_CLAUDE_STATUSLINE_GET" "$_CLAUDE_STATUSLINE_SET" || return 1
  fi
  if [[ -n "$dir" ]]; then
    _claude_settings_merge "home-launch hook" "$(molt_claude_hook_entry)" "$MOLT_CLAUDE_HOOK_GET" "$MOLT_CLAUDE_HOOK_SET" || return 1
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
