#!/usr/bin/env bash
# molt.sh — Core functions for MOLT framework
# The Highlander Rule: this is the ONE place for shared utilities.

set -euo pipefail

# Source constants (single source of truth for all configurable values)
MOLT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${MOLT_LIB_DIR}/constants.sh"

# --- Logging ---

# Prints a line at the level $1. Errors go to stderr, so a caller that captures
# a function's output, as x="$(fn)", never takes an error for its value and the
# user still sees it; every other level goes to stdout (issue 0016).
molt_log() {
  local level="$1"; shift
  local prefix
  case "$level" in
    info)  prefix="Zen:" ;;
    warn)  prefix="Zen [warning]:" ;;
    error) prefix="Zen [error]:" ;;
    debug) [[ "${MOLT_DEBUG:-0}" == "1" ]] || return 0; prefix="Zen [debug]:" ;;
    *)     prefix="Zen:" ;;
  esac
  if [[ "$level" == error ]]; then
    echo "$prefix $*" >&2
  else
    echo "$prefix $*"
  fi
}

molt_info()  { molt_log info "$@"; }
molt_warn()  { molt_log warn "$@"; }
molt_error() { molt_log error "$@"; }
molt_debug() { molt_log debug "$@"; }

# --- Platform Detection ---

molt_platform() {
  local uname_s
  uname_s="$(uname -s)"
  case "$uname_s" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *)      echo "unknown" ;;
  esac
}

molt_distro() {
  if [[ "$(molt_platform)" != "linux" ]]; then
    echo "none"
    return
  fi
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

molt_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    *)       echo "$arch" ;;
  esac
}

# This sleeve's name: its short hostname, which names its directory under the
# user repo's instances/ and every agent it runs (<hostname>-<role>, ST0006).
# Fails, printing nothing, when the host has no name to give.
molt_hostname() {
  local name
  name="$(hostname -s 2>/dev/null || hostname 2>/dev/null)" || name="${HOSTNAME:-}"
  name="${name%%.*}"
  [[ -n "$name" ]] || return 1
  echo "$name"
}

# --- Dependency Checks ---

molt_require() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    molt_error "Required command not found: $cmd"
    return 1
  fi
}

molt_require_all() {
  local failed=0
  for cmd in "$@"; do
    molt_require "$cmd" || failed=1
  done
  return $failed
}

# --- Symlink Management ---

# True when target is a symlink that actually resolves.
#
# The install checks tested `[[ -L "$target" ]]` -- is there a symlink here --
# which a DANGLING symlink satisfies. So after the user repo was renamed on a
# case-sensitive filesystem, every dotfile link pointed at a path that no longer
# existed, every liberator check reported ok, install never ran, molt_link was
# never called, and `molt resleeve` printed "Sleeve ready. Welcome back." over a
# sleeve with no .zshrc, no git identity and no Doom config.
#
# Invisible on macOS: case folding keeps the old path resolving, so nothing ever
# dangles there. kovacs found it, as with the local-storage check.
molt_link_healthy() {
  [[ -L "$1" ]] && [[ -e "$1" ]]
}

# True when target is a healthy symlink pointing at the expected source.
#
# molt_link_healthy asks only whether a link resolves, not whether it resolves
# to the thing this liberator installs. ~/bin/intent resolves fine -- to a Rust
# release binary that intent_install never created -- so the check passed about
# a link it was not governing. A resolving link to the wrong target is the same
# "reports ok while wrong" class as a dangling one, just harder to see.
molt_link_points_to() {
  local target="$1" expected="$2"
  molt_link_healthy "$target" || return 1
  molt_same_file "$target" "$expected"
}

# The path $1 leads to, as the disk spells it: each symlink on the way followed,
# a relative target from its link's directory, and the directory the chain ends
# in named by molt_disk_path -P, which takes each .. after the link before it,
# as realpath(1) does. Shell alone, the same on every platform: realpath(1) is
# not on every macOS, readlink -f is not on every BSD, and Molt ships no Python
# (issue 0039). $1 comes back as it was when it cannot be resolved, or when 40
# links have not ended the chain.
_molt_realpath() {
  local path="$1" link dir hops=0
  [[ "$path" == /* ]] || path="$PWD/$path"
  while [[ -L "$path" ]]; do
    if (( ++hops > 40 )) || ! link="$(readlink "$path")"; then
      echo "$1"
      return 0
    fi
    if [[ "$link" != /* ]]; then
      dir="${path%/*}"
      dir="$(molt_disk_path -P "${dir:-/}")" || { echo "$1"; return 0; }
      link="${dir%/}/$link"
    fi
    path="$link"
  done
  molt_disk_path -P "$path" || echo "$1"
}

# True when the paths $1 and $2 resolve to the same file.
molt_same_file() {
  [[ "$(_molt_realpath "$1")" == "$(_molt_realpath "$2")" ]]
}

# Names which fault molt_link_healthy tripped on, for user-facing messages.
#
# molt_link_healthy is one boolean over distinct states, and the messages all
# said "is not a symlink". For the dangling case that is a false statement:
# it IS a symlink, that is the whole problem. Someone debugging runs `ls -l`,
# sees `.tmux.conf -> ...`, concludes the tool is wrong and stops looking --
# which is exactly the wrong place to stop, because a dangling link is the
# failure that hid the repo rename. Same defect class as a check reporting a
# reason it no longer tests.
#
# Total over every state, the healthy one included. Every call site today
# is guarded by a failed molt_link_healthy, so the healthy branch is
# unreachable from here -- but a helper that names a fault on a sound link is
# the very bug this fixes, and the next caller will not be guarded.
molt_link_fault() {
  local target="$1"
  if molt_link_healthy "$target"; then
    echo "resolves"
  elif [[ -L "$target" ]]; then
    echo "is a broken symlink"
  elif [[ -e "$target" ]]; then
    echo "is not a symlink"
  else
    echo "is missing"
  fi
}

# A liberator that links several files from the user repo lists them once, as
# "source<TAB>target" lines under $HOME, and its check, install and verify all
# read that list through molt_report_link_faults and molt_link_all, further
# down. Each liberator had its own copy of these loops, and the copies drifted.

# Reports, through $1 (molt_info or molt_error) after the prefix $2, every line
# of the list $3 whose target is not a link to its source. Returns non-zero when
# it reported one. A link that resolves somewhere else is named with where it
# points: molt_link_fault would call it "resolves", which reads as healthy.
molt_report_link_faults() {
  local log="$1" prefix="$2" links="$3" source target fault faulted=0
  while IFS=$'\t' read -r source target; do
    # An empty list still reads as one empty line.
    [[ -n "$source" ]] || continue
    molt_link_points_to "$target" "$source" && continue
    if molt_link_healthy "$target"; then
      fault="points at $(readlink "$target"), not $source"
    else
      fault="$(molt_link_fault "$target")"
    fi
    "$log" "${prefix}$(molt_tilde "$target") $fault"
    faulted=1
  done <<< "$links"
  return $faulted
}

# $1 for a message: a path under $HOME is written from ~, any other as it is.
# Writing '~' before whatever follows $HOME named a target outside $HOME as if
# it were inside it, and Claude Code's config dir may be anywhere (ST0006).
molt_tilde() {
  case "$1" in
    "$HOME") echo '~' ;;
    "$HOME"/*) echo '~'"${1#"$HOME"}" ;;
    *) echo "$1" ;;
  esac
}

# The absolute path $1 as the disk spells it: the directory it leads to, as
# /bin/pwd -P names it, or, where it does not exist yet, its nearest ancestor
# that does, so named, with the rest of $1 after it, as mkdir -p would make
# it. A symlinked spelling, or one in another letter case on a disk that
# ignores case, is the same directory. bash's builtin pwd -P keeps the letter
# case it was given, so /bin/pwd answers, and the builtin only on a system
# without one. The claude liberator's home guard resolves a directory the same
# way (real_dir), so molt_agt_dir_fault and the guard never disagree about
# which directories are one (ST0006 AC014). Fails for a relative path, and
# when not even / can be entered.
#
# cd takes a .. off with the name before it, as text, before it follows any
# link, so a/link/.. is a, wherever the link leads. That is the guard's
# answer, and the directories it compares hold no .. to differ on. With -P
# first, each .. is taken after the link before it, as realpath(1) takes it,
# for _molt_realpath, whose link targets may hold one.
molt_disk_path() {
  local cd_opt=() path rest="" real
  if [[ "${1:-}" == -P ]]; then
    cd_opt=(-P)
    shift
  fi
  path="${1:-}"
  # ${path%/*} of a relative path is itself, and the loop below would not end.
  [[ "$path" == /* ]] || return 1
  until real="$(cd ${cd_opt+"${cd_opt[@]}"} "${path:-/}" 2>/dev/null && { /bin/pwd -P 2>/dev/null || pwd -P; })"; do
    [[ -n "$path" ]] || return 1
    rest="/${path##*/}$rest"
    path="${path%/*}"
  done
  real="${real%/}$rest"
  echo "${real:-/}"
}

# Why the path $2, named $1, is not an absolute, canonical path, or nothing
# when it is. A relative one would land wherever molt runs, and a ~ quoted in a
# shell or in vars.sh is not expanded. A trailing slash, //, or a . or ..
# component is a second spelling of a directory, which a comparison of
# spellings takes for another, and after a symlink a .. that cd and mkdir
# resolve to different places. Its callers add what their own use refuses.
molt_path_fault() {
  local name="$1" path="$2"
  case "$path" in
    /*) ;;
    "~"*)
      echo "$name is not an absolute path (a quoted ~ is not expanded): $path"
      return ;;
    *)
      echo "$name is not an absolute path: $path"
      return ;;
  esac
  case "$path/" in
    *//* | */./* | */../*)
      echo "$name is not a canonical path, with no trailing slash, // or . or .. component: $path" ;;
  esac
}

# Links every line of the list $1, stopping at the first link that fails.
molt_link_all() {
  local source target
  while IFS=$'\t' read -r source target; do
    [[ -n "$source" ]] || continue
    molt_link "$source" "$target" || return 1
  done <<< "$1"
}

molt_link() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    molt_error "Source does not exist: $source"
    return 1
  fi

  # If target already points to source, nothing to do.
  if molt_link_points_to "$target" "$source"; then
    molt_debug "Already linked: $target -> $source"
    return 0
  fi

  # Each step is checked by hand: callers run this inside `if` and `||`, where
  # set -e does not apply, so a failed step would otherwise run on to "Linked:".
  # If target exists and is not a symlink, back it up
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    local backup
    backup="${target}.molt-backup.$(date +%Y%m%d%H%M%S)"
    molt_warn "Backing up existing file: $target -> $backup"
    mv "$target" "$backup" || { molt_error "Could not back up $target, so it was not linked"; return 1; }
  fi

  # Remove existing symlink if it points elsewhere
  if [[ -L "$target" ]]; then
    rm "$target" || { molt_error "Could not remove the old link $target, so it was not linked"; return 1; }
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")" || { molt_error "Could not create $(dirname "$target"), so $target was not linked"; return 1; }

  ln -s "$source" "$target" || { molt_error "Could not link $target -> $source"; return 1; }
  molt_info "Linked: $target -> $source"
}

# --- Instance Vars ---

# The path of $1 under this sleeve's instances/<host>/ in the user repo,
# whether or not it exists. Fails, printing why instead, when there is no repo,
# and when this host has no name. Every reader of instances/ asks this, so none
# spells the path, or finds the host, its own way (issue 0044).
molt_instance_file() {
  local user_repo host
  # The reason below is the whole answer: a sleeve with no repo reads its
  # variables as undeclared, so the lookup's own error is not the user's.
  if ! user_repo="$(molt_find_user_repo 2>/dev/null)" || ! host="$(molt_hostname)"; then
    echo "this sleeve's $1 cannot be found: there is no user config repo, or this host has no name"
    return 1
  fi
  echo "${user_repo}/instances/${host}/$1"
}

# Why the vars.sh at $1 cannot be sourced, or nothing when it can be, or is not
# there. molt_render_text and molt_instance_var source vars.sh, each in its own
# subshell so that a declare -x in the file is still in scope where it is
# read; each asks here first, and everything else reads it through
# molt_instance_var. Refused: a file that cannot be read, does not parse, or
# stops before its end when sourced (a return or an exit, or an error under a
# set -u or set -e of its own). Each of those reads as though the file declared
# nothing after the point it stopped at, and on a sleeve whose Claude Code
# state has moved that recreates ~/.claude (ST0006). The file is sourced here
# once first, in a fresh bash, from a copy whose last line answers on fd 3:
# anything that ends the sourcing early misses the answer, and a set -e of the
# file's own stops it under bash 3.2 and 5 alike, which a subshell of a caller
# that ignores errexit would not. BASH_ENV would be read first, by bash -n too,
# and its errors blamed on vars.sh.
molt_instance_vars_fault() {
  local vars_file="$1" err probe
  [[ -e "$vars_file" || -L "$vars_file" ]] || return 0
  if [[ ! -f "$vars_file" || ! -r "$vars_file" ]]; then
    echo "$(molt_tilde "$vars_file") cannot be read"
    return 0
  fi
  if ! err="$(BASH_ENV='' "$BASH" -n "$vars_file" 2>&1)"; then
    err="${err%%$'\n'*}"
    echo "$(molt_tilde "$vars_file") does not parse (${err#"$vars_file": })"
    return 0
  fi
  if ! probe="$(mktemp "${TMPDIR:-/tmp}/molt-vars.XXXXXX")"; then
    echo "$(molt_tilde "$vars_file") could not be checked: no temporary file could be made"
    return 0
  fi
  # An EXIT or RETURN trap the file set would speak after the answer, and a
  # DEBUG trap before it, so the answer clears them first (issue 0025).
  { cat "$vars_file"; printf '\n\nbuiltin trap - EXIT RETURN DEBUG\nbuiltin echo "molt: sourced to its end" >&3\n'; } > "$probe"
  # The answer decides, not the status, which is the file's own. The $1 is the
  # fresh bash's own, so it stays in single quotes.
  # shellcheck disable=SC2016
  err="$(BASH_ENV='' "$BASH" -c 'set +eu; . "$1"' molt-vars "$probe" 3>&1 2>&1 >/dev/null)" || true
  rm -f "$probe"
  case "$err" in
    *"molt: sourced to its end") return 0 ;;
  esac
  # The last thing it said, when that is an error of the file's own.
  err="${err##*$'\n'}"
  case "$err" in
    "$probe: "*) err=" (${err#"$probe: "})" ;;
    *) err="" ;;
  esac
  echo "$(molt_tilde "$vars_file") stops before its end when sourced$err"
}

# Prints the variable $1 as this sleeve's vars.sh exports it; nothing when the
# file does not export it, or there is no file. Only exported variables count,
# because molt_render substitutes only those: a value it could not render is
# not declared. Nor does a value this process inherited: the file declares, not
# the environment molt runs in, so $1 starts unset. Given $2, it starts
# exported with that value instead, as a variable molt's own shell exports
# reaches molt_render_text's subshell: there an assignment, a += or an unset in
# the file changes what envsubst sees, and so it does here. Fails, printing why
# instead: with status 2 when molt_instance_vars_fault refuses the file, when
# the sourcing here stops before its end, or when the value holds a line break
# or a carriage return, which the caller's $() would cut or keep unseen; and
# with status 3 when this sleeve's vars.sh cannot be found, as when there is no
# user repo.
molt_instance_var() {
  local vars_file fault out
  if ! vars_file="$(molt_instance_file vars.sh)"; then
    echo "$vars_file"
    return 3
  fi
  fault="$(molt_instance_vars_fault "$vars_file")"
  if [[ -n "$fault" ]]; then
    echo "$fault"
    return 2
  fi
  # The name is $1 throughout: vars.sh can assign any variable, this function's
  # locals among them, but not its arguments. The value goes out ahead of a
  # closing line, so a sourcing that ends early, or a value that ends in a line
  # break, shows here.
  out="$(
    if [[ $# -gt 1 ]]; then
      export "$1=$2"
    else
      unset "$1"
    fi
    if [[ -e "$vars_file" ]]; then
      set +eu
      # An EXIT trap the file set would print after the closing line, a
      # RETURN trap as the . returns, and a DEBUG trap before each command
      # after the file, the one that clears it included, so the file is
      # quiet here, its stderr too: molt_instance_vars_fault has already
      # said what was wrong with it (issue 0025).
      {
        # shellcheck disable=SC1090
        . "$vars_file"
        builtin trap - EXIT RETURN DEBUG
      } >/dev/null 2>&1
    fi
    if printenv "$1" >/dev/null; then
      printf '%s' "${!1}"
    fi
    printf '\nmolt: read to its end'
  )" || true
  case "$out" in
    *$'\n'"molt: read to its end") out="${out%$'\n'molt: read to its end}" ;;
    *)
      echo "$(molt_tilde "$vars_file") stops before its end when sourced"
      return 2 ;;
  esac
  case "$out" in
    *[$'\n\r']*)
      echo "$(molt_tilde "$vars_file") exports $1 with a line break in it"
      return 2 ;;
  esac
  printf '%s\n' "$out"
}

# --- Template Rendering ---

# Renders the template $1 into the file $2 and nothing more: molt_render_place
# adds the region kept above @@MOLT:BEGIN@@, the backup and the sidecar. Only
# MOLT_* variables are substituted, as this sleeve's vars.sh and the
# environment export them; other $VAR references (like starship's $username,
# $path, etc.) are left untouched. vars.sh is sourced in a subshell, so its
# exports don't leak into the framework, and a declare -x in it is still in
# scope for envsubst. Fails, printing why when envsubst or vars.sh is the
# reason, with $2 not written: no render, whatever the subshell's status, is a
# failure, and a file a crashed render left goes first, or it would pass for
# this one.
molt_render_text() {
  local template="$1" out="$2" vars_file why
  # Asked first, before anything else here runs a command: without envsubst a
  # render would leave the ${VARS} as they are, and the caller report success.
  if ! command -v envsubst &>/dev/null; then
    echo "envsubst not found; install gettext (macOS: brew install gettext && brew link --force gettext; linux: apt install gettext), then re-run"
    return 1
  fi
  if ! vars_file="$(molt_instance_file vars.sh)"; then
    echo "$vars_file"
    return 1
  fi
  why="$(molt_instance_vars_fault "$vars_file")"
  if [[ -n "$why" ]]; then
    echo "$why"
    return 1
  fi
  rm -f "$out"
  if ! (
    if [[ -e "$vars_file" ]]; then
      set +eu
      # The traps molt_instance_var clears, cleared alike, so the two read
      # the file the same way (issue 0025).
      {
        # shellcheck disable=SC1090
        . "$vars_file"
        builtin trap - EXIT RETURN DEBUG
      } >/dev/null 2>&1
    fi
    mkdir -p "$(dirname "$out")" || exit
    local molt_vars
    molt_vars="$(env | grep '^MOLT_' | sed 's/=.*//' | sed 's/^/\$/' | tr '\n' ' ')"
    envsubst "$molt_vars" < "$template" > "$out"
  ) >/dev/null || [[ ! -f "$out" ]]; then
    rm -f "$out"
    return 1
  fi
}

# Renders the template $1 into ${2}.molt-tmp, for molt_render_place to put in
# place at $2: what molt_render does before placing, for a caller that adds to
# the file between the two, as the ssh liberator does its config.d fragments.
molt_render_tmp() {
  local template="$1"
  local target="$2"

  if [[ ! -f "$template" ]]; then
    molt_error "Template not found: $template"
    return 1
  fi

  local vars_file why
  if vars_file="$(molt_instance_file vars.sh)" && [[ ! -e "$vars_file" ]]; then
    molt_warn "No vars.sh for instance $(molt_hostname) — rendering template with env only"
  fi

  # Everything below handles the render it finds, so no render is a failure:
  # the target would be backed up with nothing to take its place.
  if ! why="$(molt_render_text "$template" "${target}.molt-tmp")"; then
    molt_error "Could not render $template -> $target${why:+: $why}"
    return 1
  fi
}

molt_render() {
  molt_render_tmp "$1" "$2" && molt_render_place "$1" "$2"
}

# A path to move $1 aside to, named for this second, that nothing holds yet: a
# second render in the same second took the first one's name, and mv put the
# newer backup over the older without a word (critic-shell, 21 Oct).
_molt_backup_path() {
  local backup n=1
  backup="${1}.molt-backup.$(date +%Y%m%d%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${1}.molt-backup.$(date +%Y%m%d%H%M%S).$n"
    n=$((n + 1))
  done
  echo "$backup"
}

# Puts ${2}.molt-tmp in place as $2: the file rendered from the template $1,
# with whatever its caller built into it from the extra inputs after $1. A
# caller builds the whole file there first, and changes nothing in $2 after,
# and the region kept above @@MOLT:BEGIN@@ goes in before the compare: $2 is
# backed up whenever what molt would write differs from what is there, so a
# file finished after the compare would be compared as part of a file and
# backed up at every render (ST0006: an agent's AGENTS.md and settings.json,
# and any file with lines above the marker). The sidecar records the digest of
# $1, this sleeve's vars.sh and the extra inputs, so molt_render_stale, asked
# with the same inputs, reads $2 current.
molt_render_place() {
  local template="$1"
  local target="$2"
  shift 2

  # Honour the @@MOLT:BEGIN@@ contract. Templates carrying the marker tell the
  # user "add your own entries ABOVE this line" -- but rendering replaced the
  # whole file, so anything added there was destroyed on the next render. It
  # stayed invisible only because a template change was the sole trigger and
  # templates rarely changed; molt_config_stale makes renders routine, which
  # turns a latent bug into a frequent one.
  #
  # Take the region above the marker from the CURRENT file BEFORE the backup
  # logic below moves it aside. Only applies when the new render opens with the
  # marker, as the templates that carry it do, and the existing file carries it
  # too, so rendered scripts and plists are untouched. A render with lines of
  # its own above the marker would have them kept here and written again under
  # them, one more copy each time, as a preamble put ahead of a role's contract
  # that carried the marker was (critic-shell, 21 Oct); and a marker that is
  # only mentioned, below the first line, is only text. Lines above a marker
  # the new render no longer opens with are not kept, and those it does not
  # carry itself are named when the file they were in is backed up.
  local marker='@@MOLT:BEGIN@@'
  local kept="" dropped=""
  if [[ -f "$target" ]] && grep -qF "$marker" "$target" 2>/dev/null; then
    kept="$(awk -v m="$marker" 'index($0, m) { exit } { print }' "$target")"
    if [[ -n "$kept" ]] \
       && ! awk -v m="$marker" 'NR == 1 { found = index($0, m) } END { exit !found }' "${target}.molt-tmp" 2>/dev/null; then
      # Only lines the new render does not carry above its own marker: a
      # template's own text there is in it already (critic-shell, 21 Oct).
      dropped="$(awk -v m="$marker" '
        FNR == 1 { file++ }
        file == 1 { if (index($0, m)) done = 1; if (!done) have[$0] = 1; next }
        index($0, m) { exit }
        /./ && !($0 in have) { n++ }
        END { if (n) print n }
      ' "${target}.molt-tmp" "$target")"
      kept=""
    fi
  fi
  if [[ -n "$kept" ]]; then
    if ! { printf '%s\n' "$kept" && cat "${target}.molt-tmp"; } > "${target}.molt-tmp2" \
        || ! mv -f "${target}.molt-tmp2" "${target}.molt-tmp"; then
      rm -f "${target}.molt-tmp" "${target}.molt-tmp2"
      molt_error "Could not keep the lines above ${marker} in $target, so it was not rendered"
      return 1
    fi
  fi

  # Handle existing file before replacing
  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    if [[ -L "$target" ]]; then
      # Symlinks are removed, not backed up (they cause permission issues in
      # directories like ~/.ssh where sshd demands regular files with strict perms)
      molt_info "Removing existing symlink: $target"
      rm "$target"
    elif [[ -f "${target}.molt-rendered" ]]; then
      # Previously rendered by molt. A file that is still what molt wrote, by
      # the sidecar's output digest, is replaced with no backup: only a hand
      # edit is backed up, and lines above the marker the new render drops are
      # kept in a backup either way (issue 0029).
      local wrote now
      wrote="$(sed -n 's/^output //p' "${target}.molt-rendered" 2>/dev/null)"
      now="$(molt_hash < "$target" 2>/dev/null)" || now=""
      if diff -q "$target" "${target}.molt-tmp" &>/dev/null; then
        :   # the same file again: nothing to keep
      elif [[ -n "$wrote" && "$now" == "$wrote" && -z "$dropped" ]]; then
        molt_info "Replacing molt's own render, unchanged since it was written: $target"
      else
        local backup
        backup="$(_molt_backup_path "$target")"
        molt_warn "Rendered file changed since last render, backing up: $target -> $backup"
        if [[ -n "$dropped" ]]; then
          molt_warn "$dropped line(s) above ${marker} in $target are not kept: the new render does not open with the marker, so they are in $backup"
        fi
        if ! mv "$target" "$backup"; then
          rm -f "${target}.molt-tmp"
          molt_error "Could not back up $target, so it was not rendered"
          return 1
        fi
      fi
    else
      # Regular file that wasn't rendered by molt — back up
      local backup
      backup="$(_molt_backup_path "$target")"
      molt_warn "Backing up existing file: $target -> $backup"
      if ! mv "$target" "$backup"; then
        rm -f "${target}.molt-tmp"
        molt_error "Could not back up $target, so it was not rendered"
        return 1
      fi
    fi
  fi

  if [[ -n "$kept" ]]; then
    molt_info "Preserved $(printf '%s\n' "$kept" | grep -c .) line(s) above ${marker}"
  fi

  if ! mv "${target}.molt-tmp" "$target"; then
    rm -f "${target}.molt-tmp"
    molt_error "Could not move the render of $template into place at $target"
    return 1
  fi

  # Leave a marker so we know this file was rendered (not symlinked), carrying
  # the digest of the inputs so molt_config_stale can tell whether they moved,
  # and of the file written, so the next render can tell a hand edit from it.
  local d
  d="$(molt_config_digest "$template" ${1+"$@"})" || d=""
  molt_render_sidecar "$template" "$d" "$target" > "${target}.molt-rendered"

  # If parent directory is locked down (eg ~/.ssh at 700), restrict file perms
  # to match. sshd and similar tools reject files with open permissions.
  local parent_perms
  parent_perms="$(molt_file_mode "$(dirname "$target")" || echo "755")"
  if [[ "$parent_perms" == "700" ]]; then
    chmod 600 "$target" "${target}.molt-rendered"
  fi

  molt_info "Rendered: $template -> $target"
}

# The text of a .molt-rendered sidecar: when the file $3 was rendered and from
# what, $1, the digest $2 of its inputs, and the hash of $3 as written. A digest
# or hash that could not be taken leaves its line out, so the file reads as
# stale, or as not molt's own render, rather than as one that matches.
molt_render_sidecar() {
  local from="$1" digest="$2" written="$3" d
  echo "rendered $(date -Iseconds) from $from"
  [[ -z "$digest" ]] || echo "digest $digest"
  if d="$(molt_hash < "$written")" && [[ -n "$d" ]]; then
    echo "output $d"
  fi
}

# The permission bits of $1 in octal, eg 700, on Linux and macOS. GNU stat is
# asked first, and BSD's only when it fails: GNU's -f means --file-system, and
# takes BSD's format for a file to report on.
molt_file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null
}

# SHA-256 of a string on stdin, portable across macOS and Linux.
molt_hash() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum | awk '{print $1}'
  else
    return 1
  fi
}

# Digest of everything that determines a rendered file's content: the template
# AND the instance vars.sh that molt_render substitutes into it.
#
# vars.sh matters as much as the template. molt_render sources it and feeds the
# MOLT_* values to envsubst, so a vars-only edit changes the output while
# leaving the template untouched -- and a vars-only edit is the *likely* kind,
# because vars.sh is the per-machine file. Digesting only the template would
# leave that hole open.
molt_config_digest() {
  local template="$1"
  shift
  [[ -f "$template" ]] || return 1

  local vars_file
  vars_file="$(molt_instance_file vars.sh)" || return 1

  # Any remaining arguments are extra inputs that also determine the rendered
  # result -- ssh's instance config.d fragments, for one. A fragment ADDED or
  # EDITED changes the file the sleeve ends up with while changing neither the
  # template nor vars.sh, so without this the digest looks straight past it,
  # _check passes, _install never runs, and the fragment never lands. The same
  # bug has now appeared in the template, then vars.sh, then the fragments. Include everything the output depends on, or the check is
  # answering a narrower question than the one being asked.
  #
  # Sorted so the digest does not depend on glob order across filesystems.
  local extras=()
  if [[ $# -gt 0 ]]; then
    local e
    while IFS= read -r e; do [[ -n "$e" ]] && extras+=("$e"); done \
      < <(printf '%s\n' "$@" | sort)
  fi

  # An absent input contributes nothing, so adding it later changes the digest.
  # Each test is an `if`: a bare `[[ -f ]] && ...` as the group's last command
  # fails it for an absent last extra, pipefail carries that out of the
  # pipeline, and the file then reads stale however often it is rendered.
  {
    cat "$template"
    if [[ -f "$vars_file" ]]; then cat "$vars_file"; fi
    local x
    for x in ${extras+"${extras[@]}"}; do
      # Name as well as content: renaming a fragment changes the sentinel.
      if [[ -f "$x" ]]; then basename "$x"; cat "$x"; fi
    done
  } 2>/dev/null | molt_hash
}

# True when a rendered config no longer matches its inputs.
#
# molt only re-renders a config when its liberator's check reports not-ok. So a
# change to a template or to instance vars never propagated on its own: the
# check passed, install was skipped, and the sleeve kept running the previous
# rendered file while reporting "ok" at every step. That is how gyges spent a
# morning running a backup agent that named a disk image rhadamanth had already
# migrated away from, with both machines reporting a clean upgrade.
#
# This compares a CONTENT DIGEST, not mtimes. mtime looked adequate and is not:
#   - git rewrites mtimes. A checkout, a clone, or `git checkout -- <file>`
#     restamps files whose content never changed, so every template reads stale.
#   - a byte-identical template that is merely touched reads stale.
#   - worst, it produces FALSE NEGATIVES across filesystems. A FUSE mount that
#     truncates mtime to whole seconds, compared against an ext4 file carrying
#     nanoseconds inside the same second, reports "not newer" -- silently NOT
#     re-rendering, which is the exact failure this function exists to catch.
#     Everything else here fails safe by over-rendering; that one fails quiet.
#   - and a guest with no NTP has no clock authority to compare against at all.
#
# Digests are immune to each of these, and cover vars.sh in the same move.
#
# Fails CLOSED: when the digest cannot be computed we report stale, because
# re-rendering costs a moment and skipping it is the failure mode above.
#
# Liberators that render configs should fold this into their check.
molt_config_stale() {
  local source="$1"    # relative path, no .tmpl: "config/backup/backup-mount.sh"
  local target="$2"    # absolute path of the rendered file
  shift 2              # any remaining args: extra inputs the render depends on

  # An absolute or .tmpl source can never name a template, so the "no template,
  # nothing to render" answer below would be a silent pass. The alacritty
  # liberator passed its absolute .tmpl path and was told "not stale" for a week
  # over a dangling link (issue 0007). Say so, and fail closed.
  if [[ "$source" == /* ]]; then
    molt_error "molt_config_stale: source must be repo-relative, got ${source}"
    return 0
  fi
  if [[ "$source" == *.tmpl ]]; then
    molt_error "molt_config_stale: pass the source without .tmpl, got ${source}"
    return 0
  fi

  local user_repo template
  if ! user_repo="$(molt_find_user_repo 2>/dev/null)"; then
    molt_warn "molt_config_stale: no user repo — cannot tell whether ${target} is stale"
    return 0
  fi
  template="${user_repo}/${source}.tmpl"

  [[ -f "$template" ]] || return 1      # static/linked config: nothing to render
  molt_render_stale "$template" "$target" ${1+"$@"}
}

# molt_config_stale for a template named by its path, as Molt's own templates
# under templates/ are (the claude liberator's, ST0006): true when the file $2
# rendered from the template $1 is missing, or no longer matches the template,
# this sleeve's vars.sh or the extra inputs after them. Fails closed, a missing
# template included: a template that is not there cannot be called rendered.
molt_render_stale() {
  local template="$1" target="$2"
  shift 2
  [[ -f "$template" ]] || return 0
  [[ -e "$target" ]]   || return 0      # never rendered: trivially stale

  local want have
  want="$(molt_config_digest "$template" ${1+"$@"})" || return 0
  [[ -n "$want" ]] || return 0
  have="$(sed -n 's/^digest //p' "${target}.molt-rendered" 2>/dev/null)"

  [[ "$want" != "$have" ]]
}

# --- Fonts ---

# Can the system actually resolve this font family?
#   0 = resolved    1 = not installed    2 = cannot determine
#
# fc-match is NOT usable here, and that is the whole point: it ALWAYS succeeds.
# `fc-match ThisFontDoesNotExist12345` returns Verdana on this machine, so a
# check built on it reports every font as present -- the same "reports ok while
# wrong" class as a link check that passed on a dangling symlink. Exact family
# matching over `fc-list : family` is the only honest test.
#
# 2 is a distinct answer on purpose, and callers must not fold it into 0 or 1.
# A machine with no fontconfig cannot be said to be missing the font; claiming
# ok there is the same lie pointing the other way.
molt_font_available() {
  local family="$1" families
  [[ -n "$family" ]] || return 2
  command -v fc-list &>/dev/null || return 2
  families="$(fc-list : family 2>/dev/null)" || return 2
  [[ -n "$families" ]] || return 2

  # Materialise the list, THEN match. `... | grep -qixF` looks equivalent and is
  # not: grep -q closes the pipe on its first hit, the upstream stages take
  # SIGPIPE, and under `set -o pipefail` the function returns 141 for a font
  # that IS installed. The caller reads 141 as "cannot determine", so the honest
  # answer becomes an unmeasurable one on any shell with pipefail set -- passing
  # everywhere it was tried and failing where it was not.
  local list
  list="$(printf '%s\n' "$families" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  grep -qixF -- "$family" <<< "$list"
}

molt_install_config() {
  local source="$1"    # relative path: "config/starship/starship.toml"
  local target="$2"    # absolute path: "$HOME/.config/starship.toml"

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  local full_source="$user_repo/$source"
  local template="${full_source}.tmpl"

  if [[ -f "$template" ]]; then
    molt_render "$template" "$target"
  elif [[ -f "$full_source" ]]; then
    molt_link "$full_source" "$target" || return 1
  else
    molt_warn "Config not found: $source (checked template and static)"
    return 1
  fi
}

# --- Cross-Instance Aggregation ---

# Read a TOML field from all instance.toml files in the user repo.
# Iterates instances/*/instance.toml, extracts the named field from the
# named section, and prints hostname:value pairs (one per line).
# Usage: molt_instances_field "field_name" "section_name"
molt_instances_field() {
  local field="$1"
  local section="${2:-instance}"

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  local instances_dir="$user_repo/instances"
  [[ -d "$instances_dir" ]] || return 1

  for instance_dir in "$instances_dir"/*/; do
    [[ -d "$instance_dir" ]] || continue
    local toml="$instance_dir/instance.toml"
    [[ -f "$toml" ]] || continue

    local hostname value="" in_section=0
    hostname="$(basename "$instance_dir")"

    while IFS= read -r line; do
      if [[ "$line" =~ ^\[([a-z_]+)\] ]]; then
        [[ "${BASH_REMATCH[1]}" == "$section" ]] && in_section=1 || in_section=0
      elif [[ $in_section -eq 1 ]] && [[ "$line" =~ ^${field}[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        value="${BASH_REMATCH[1]}"
      fi
    done < "$toml"

    [[ -n "${value}" ]] && echo "${hostname}:${value}"
  done
  return 0
}

# --- Manifest (molt.toml) ---

# Find the molt.toml manifest. Checks instance-specific first, then repo root.
molt_find_manifest() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -z "$user_repo" ]] && return 1

  # Instance-specific overrides repo-level. A host with no name has no
  # instance, and takes the repo-level manifest, as it did before
  # molt_hostname could say so.
  local instance_manifest
  if instance_manifest="$(molt_instance_file molt.toml)" && [[ -f "$instance_manifest" ]]; then
    echo "$instance_manifest"
    return 0
  fi

  # Repo-level default
  local repo_manifest="$user_repo/molt.toml"
  if [[ -f "$repo_manifest" ]]; then
    echo "$repo_manifest"
    return 0
  fi

  return 1
}

# The one reader of molt.toml's array tables, [[liberator]] and [[agent]]: the
# blocks headed [[$1]] in the manifest $3. Prints a line per key of every block,
# "id<TAB>key<TAB>value", where the id is the value of the block's $2 key and
# its own line comes first whatever order the keys are written in. A block with
# no $2 key is printed with an empty id, so a caller can refuse it rather than
# never see it. A block ends at the next table header of any kind, so a key
# below [stack] or [sleeve] belongs to no block. A quoted value loses its
# quotes; a bare one loses a trailing comment and is otherwise kept as written,
# so a caller can refuse a value by name rather than mistake it for none. Keys
# are read from the start of a line, as molt.toml writes them.
_molt_table_entries() {
  awk -v header="[[$1]]" -v idkey="$2" '
    function flush(   k) {
      if (inblock) {
        print id "\t" idkey "\t" id
        for (k in val) print id "\t" k "\t" val[k]
      }
      for (k in val) delete val[k]
      id = ""
    }
    index($0, header) == 1 { flush(); inblock = 1; next }
    /^\[/ { flush(); inblock = 0; next }
    inblock && /^[A-Za-z0-9_-]+[[:space:]]*=/ {
      key = $0
      sub(/[[:space:]]*=.*/, "", key)
      v = substr($0, index($0, "=") + 1)
      sub(/^[[:space:]]+/, "", v)
      if (v ~ /^"/) {
        v = substr(v, 2)
        sub(/".*/, "", v)
      } else {
        sub(/[[:space:]]*(#.*)?$/, "", v)
      }
      if (key == idkey) id = v
      else val[key] = v
    }
    END { flush() }
  ' "$3"
}

# Parse enabled liberators from molt.toml.
# Returns one liberator name per line for enabled liberators on this platform.
# Fails when there is no manifest (callers then fall back to a directory scan).
molt_enabled_liberators() {
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null || echo "")"
  [[ -z "$manifest" ]] && return 1

  local platform
  platform="$(molt_platform)"

  # In manifest order. enabled defaults to true, os to every platform. An entry
  # with no name names no liberator.
  _molt_table_entries liberator name "$manifest" | awk -F'\t' -v platform="$platform" '
    $1 == "" { next }
    $2 == "name" { order[++n] = $1; enabled[$1] = "true"; os[$1] = "" }
    $2 == "enabled" { enabled[$1] = ($3 == "false") ? "false" : "true" }
    $2 == "os" { os[$1] = $3 }
    END {
      for (i = 1; i <= n; i++) {
        lib = order[i]
        if (enabled[lib] == "true" && (os[lib] == "" || os[lib] ~ platform)) print lib
      }
    }
  '
}

# The liberators a run covers, one a line: those the manifest enables for this
# platform, or every liberator Molt ships when there is no manifest. A manifest
# that enables none for this platform is refused, not read as "run them all":
# fails, printing why and naming the manifest (issue 0054, hv's ruling).
molt_run_liberators() {
  local manifest liberators
  if ! manifest="$(molt_find_manifest 2>/dev/null)"; then
    liberators="$(liberator_list)" || { echo "there are no liberators to run"; return 1; }
    echo "$liberators"
    return 0
  fi
  liberators="$(molt_enabled_liberators)"
  if [[ -z "$liberators" ]]; then
    echo "$(molt_tilde "$manifest") enables no liberator for $(molt_platform); enable one, or remove the manifest to run them all"
    return 1
  fi
  echo "$liberators"
}

# Prints the value of key $2 on the [[liberator]] entry named $1 in this
# sleeve's molt.toml, read by _molt_table_entries like every other key.
# Fails when there is no manifest, no such entry or no such key.
molt_liberator_field() {
  local manifest value
  manifest="$(molt_find_manifest 2>/dev/null)" || return 1
  # Reads every line rather than exiting at the first match, so the writer
  # upstream never meets a closed pipe (issue 0008).
  value="$(_molt_table_entries liberator name "$manifest" | awk -F'\t' -v want="$1" -v key="$2" '
    $1 == want && $2 == key && !found { print $3; found = 1 }
  ')" || return 1
  [[ -n "$value" ]] || return 1
  echo "$value"
}

# --- Homebrew installs ---
#
# A liberator whose tool comes from a Homebrew tap asks these, so every such
# liberator reads the same state the same way. intent had its own copy until
# ST0005, when utilz needed the same answers.

# First line of a command's --version, captured then trimmed (no pipe to head),
# read up to the parenthesis that closes `<tool> <version> (<tree>, <sha12>)`:
# A3 says a reader ignores what follows, such as the ` at <root>` older
# releases print or a provenance word (issue 0063).
molt_cmd_version() {
  local v rest
  v="$("$1" --version 2>/dev/null)" || v="version unknown"
  v="${v%%$'\n'*}"
  if [[ "$v" == *"("*")"* ]]; then
    rest="${v#*(}"
    v="${v%%(*}(${rest%%)*})"
  fi
  echo "$v"
}

# Names what PATH runs for the command $1 when it is not $2, which $3 describes
# (eg "Homebrew's /opt/homebrew/bin/intent"). No output when PATH runs $2.
molt_path_runs_fault() {
  local cmd="$1" expected="$2" label="$3" on_path
  on_path="$(command -v "$cmd" 2>/dev/null)" || on_path=""
  if [[ -z "$on_path" ]]; then
    echo "no $cmd on PATH, so $label does not run"
  elif ! molt_same_file "$on_path" "$expected"; then
    echo "PATH runs $on_path ($(molt_cmd_version "$on_path")), not $label"
  fi
}

# The commands in the list $2 (one per line) that PATH does not run from the
# directory $1, on one line. No output when PATH runs every one of them there.
molt_path_misses() {
  local dir="$1" names="$2" name on missed=""
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    on="$(command -v "$name" 2>/dev/null)" || on=""
    if [[ -z "$on" ]] || ! molt_same_file "$on" "$dir/$name"; then
      missed="${missed:+$missed }$name"
    fi
  done <<< "$names"
  if [[ -n "$missed" ]]; then
    echo "$missed"
  fi
}

# True when a plain brew upgrade includes the formula $1 (tap/name): this
# Homebrew has no trust gate, or its trust store names the formula or its tap.
# Homebrew 7.0.10 skips an installed formula from an untrusted tap with only a
# warning and exits 0, so one installed before the gate arrived stops being
# upgraded while molt maintain reports success. Returns 2 when the trust store
# cannot be read, so a caller can say that rather than "does not trust".
molt_brew_trusted() {
  local formula="$1" store
  brew trust --help &>/dev/null || return 0
  store="$(brew trust --json=v1 2>/dev/null)" || return 2
  [[ "$store" == *"\"$formula\""* || "$store" == *"\"${formula%/*}\""* ]]
}

# True when the tap of the formula $1 (tap/name) is tapped. Fails when it is
# not, and when brew tap cannot list the taps.
molt_brew_tapped() {
  local tap="${1%/*}" taps
  taps="$(brew tap 2>/dev/null)" || return 1
  [[ $'\n'"$taps"$'\n' == *$'\n'"$tap"$'\n'* ]]
}

# Why the formula $1 (tap/name), for the command $2, is not installed from
# Homebrew, or nothing when it is; fails with a fault. $3 is the URL of a
# private tap, which brew install cannot tap itself; when its tap is missing,
# the fault names the tap command. molt_brew_faults asks this first, and a
# liberator that holds the formula beside other trees asks only this.
molt_brew_install_faults() {
  local formula="$1" cmd="$2" tap_url="${3:-}"
  if ! brew --prefix &>/dev/null; then
    echo "Homebrew not found; $cmd installs with: brew install $formula"
    return 1
  fi
  if ! brew list --versions "$formula" &>/dev/null; then
    if [[ -n "$tap_url" ]] && ! molt_brew_tapped "$formula"; then
      echo "not installed, and its tap is missing; run: brew tap ${formula%/*} $tap_url, then brew install $formula"
      return 1
    fi
    echo "not installed; run: brew install $formula"
    return 1
  fi
}

# Everything standing between this machine and "Homebrew's $2 is what PATH
# runs", for the formula $1 (tap/name), one fault per line. Fails, having named
# the fault, when nothing past it can be checked: no Homebrew, the formula not
# installed, or its command not linked. $3 is as for molt_brew_install_faults.
molt_brew_faults() {
  local formula="$1" cmd="$2" tap_url="${3:-}" prefix
  molt_brew_install_faults "$formula" "$cmd" "$tap_url" || return 1
  prefix="$(brew --prefix 2>/dev/null)"
  local trusted=0
  molt_brew_trusted "$formula" || trusted=$?
  case "$trusted" in
    0) ;;
    2) echo "brew trust --json=v1 failed, so whether brew upgrade includes $formula is unknown" ;;
    *) echo "Homebrew does not trust $formula, so brew upgrade skips it; run: brew trust --formula $formula" ;;
  esac
  if [[ ! -x "$prefix/bin/$cmd" ]]; then
    echo "installed but not linked into $prefix/bin"
    return 1
  fi
  molt_path_runs_fault "$cmd" "$prefix/bin/$cmd" "Homebrew's $prefix/bin/$cmd"
}

# Installs the formula $1 (tap/name) by its full name, which Homebrew 7.0.10
# takes as trusting it, and trusts exactly that formula when it is installed but
# not trusted, as one installed before the trust gate arrived is. $2 is the URL
# of a private tap: brew install taps over https, which a private repo refuses,
# so a missing tap is tapped from it first.
molt_brew_install() {
  local formula="$1" tap_url="${2:-}"
  if ! brew --prefix &>/dev/null; then
    molt_error "${formula##*/} installs from Homebrew, and brew is not on PATH"
    return 1
  fi
  if ! brew list --versions "$formula" &>/dev/null; then
    if [[ -n "$tap_url" ]] && ! molt_brew_tapped "$formula"; then
      molt_info "Tapping ${formula%/*}: brew tap ${formula%/*} $tap_url"
      if ! brew tap "${formula%/*}" "$tap_url"; then
        molt_error "brew tap ${formula%/*} $tap_url failed"
        return 1
      fi
    fi
    molt_info "Installing ${formula##*/}: brew install $formula"
    if ! brew install "$formula"; then
      molt_error "brew install $formula failed"
      return 1
    fi
  fi
  if ! molt_brew_trusted "$formula"; then
    molt_info "Trusting $formula, so brew upgrade includes it: brew trust --formula $formula"
    if ! brew trust --formula "$formula"; then
      molt_error "brew trust --formula $formula failed"
      return 1
    fi
  fi
}

# Logs each line of the faults $4 through $1 (molt_info, molt_warn or
# molt_error), after the lead $2 and the label $3. True when there are none.
molt_report_faults() {
  local log="$1" lead="$2" label="$3" faults="$4" fault
  [[ -n "$faults" ]] || return 0
  while IFS= read -r fault; do
    "$log" "${lead}${label}: $fault"
  done <<< "$faults"
  return 1
}

# --- GNOME settings ---

# Chooses, once per run, the gsettings molt reads and sets GNOME keys with: the
# first on PATH whose backend is dconf, the store GNOME reads. A gsettings with
# no dconf module falls back, without a word, to a keyfile under
# ~/.config/glib-2.0 that GNOME never reads. On kovacs the first on PATH was
# Homebrew's, so every key molt set went there and doctor read schema defaults
# (issue 0047). Each candidate is asked, not judged by where it lives.
#
# Status: 0 one reaches dconf, and molt_gsettings runs it; 1 there is no
# gsettings on PATH; 2 there is, but none reaches dconf. MOLT_GSETTINGS_FAULT
# says why on 1 and 2. Call it directly, never in $(...), so that the choice
# outlives the call and later calls ask nothing.
molt_gsettings_find() {
  if [[ -n "${_MOLT_GSETTINGS_STATUS:-}" ]]; then
    return "$_MOLT_GSETTINGS_STATUS"
  fi
  local gs why seen=$'\n' faults=""
  _MOLT_GSETTINGS=""
  while IFS= read -r gs; do
    # A directory PATH names twice gives the same binary twice.
    [[ -n "$gs" && "$seen" != *$'\n'"$gs"$'\n'* ]] || continue
    seen+="$gs"$'\n'
    if why="$(_molt_gsettings_dconf_fault "$gs")"; then
      _MOLT_GSETTINGS="$gs"
      MOLT_GSETTINGS_FAULT=""
      _MOLT_GSETTINGS_STATUS=0
      return 0
    fi
    faults+="${faults:+; }$(molt_tilde "$gs") $why"
  done <<< "$(type -ap gsettings || true)"
  if [[ -z "$faults" ]]; then
    MOLT_GSETTINGS_FAULT="gsettings is not on PATH"
    _MOLT_GSETTINGS_STATUS=1
  else
    MOLT_GSETTINGS_FAULT="no gsettings on PATH reaches dconf, the store GNOME reads: $faults"
    _MOLT_GSETTINGS_STATUS=2
  fi
  return "$_MOLT_GSETTINGS_STATUS"
}

# Asks the gsettings $1 to read one key through dconf. True when it does, and
# says nothing; otherwise false, saying why. One without the dconf module warns
# that it cannot find it, then reads from its fallback and exits 0, so what it
# says is the only sign, and a read that says anything does not qualify. One that fails and says nothing gives no
# reason to trust it either.
_molt_gsettings_dconf_fault() {
  local gs="$1" schemas schema keys key out status=0
  schemas="$("$gs" list-schemas 2>/dev/null)" || schemas=""
  schema="${schemas%%$'\n'*}"
  if [[ -n "$schema" ]]; then
    keys="$("$gs" list-keys "$schema" 2>/dev/null)" || keys=""
    key="${keys%%$'\n'*}"
  fi
  if [[ -z "$schema" || -z "${key:-}" ]]; then
    echo "cannot be asked: it lists no schema with a key to read"
    return 1
  fi
  out="$(GSETTINGS_BACKEND=dconf "$gs" get "$schema" "$key" 2>&1 >/dev/null)" || status=$?
  if [[ -n "$out" ]]; then
    # GLib opens a warning with a blank line.
    out="${out#"${out%%[![:space:]]*}"}"
    echo "does not read through dconf: ${out%%$'\n'*}"
    return 1
  fi
  if [[ $status -ne 0 ]]; then
    echo "cannot tell: asked to read $schema $key through dconf, it exited $status and said nothing"
    return 1
  fi
}

# Runs the gsettings molt_gsettings_find chose, with the arguments given, or
# fails saying why there is none.
molt_gsettings() {
  if ! molt_gsettings_find; then
    echo "$MOLT_GSETTINGS_FAULT" >&2
    return 1
  fi
  "$_MOLT_GSETTINGS" "$@"
}

# Says through $1 (molt_info, molt_warn or molt_error), after the lead $2 and
# the label $3, that gsettings is on PATH but none reaches dconf, and is false
# then. True otherwise: with no gsettings at all there is no GNOME to set, and
# each caller passes that by as it always has.
molt_gsettings_unreachable() {
  local status=0
  molt_gsettings_find || status=$?
  [[ $status -eq 2 ]] || return 0
  molt_report_faults "$1" "$2" "$3" "$MOLT_GSETTINGS_FAULT"
}

# --- Claude Code ---

# Where Claude Code keeps its state on this machine: CLAUDE_CONFIG_DIR when it
# is set, which moves every ~/.claude path and ~/.claude.json too, and
# ~/.claude when it is not. Every liberator that reads or writes Claude Code's
# files asks this, so none of them recreates ~/.claude once the state has moved
# (ST0006). Asked at each call, never captured, because the claude liberator
# exports CLAUDE_CONFIG_DIR partway through a run.
molt_claude_config_dir() {
  echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
}

# Succeeds when this shell's CLAUDE_CONFIG_DIR is set and names the directory
# $1, a sleeve's declared config dir, compared as the home guard compares them:
# each as the disk spells it where it is a directory, so a symlinked spelling
# or a trailing slash is the same directory, and as written where it is not.
# The claude liberator's check and publish, and molt agent start, ask it, so
# none of them passes a shell whose sessions the guard would refuse.
molt_claude_config_dir_is() {
  local want="$1" have="${CLAUDE_CONFIG_DIR:-}"
  [[ -n "$have" ]] || return 1
  if [[ -d "$want" ]]; then
    want="$(molt_disk_path "$want")" || want="$1"
  fi
  if [[ -d "$have" ]]; then
    have="$(molt_disk_path "$have")" || have="$CLAUDE_CONFIG_DIR"
  fi
  [[ "$have" == "$want" ]]
}

# Replaces the settings file $1 with what the command after it prints, through
# a temporary file beside it that cp -p gives the file's mode, then a rename, so
# Claude Code, which watches the file, never reads half of it. Every user and
# home settings file molt writes is written through here. Every step is
# checked by hand: resleeve runs install inside an `if`, where set -e does not
# apply, so a failed copy or rename would otherwise run on to "written". Fails,
# printing why, with the file as it was. Its callers refuse a symlink first:
# the rename would silently turn a link into a copy.
molt_settings_write() {
  local settings="$1" tmp
  shift
  if ! tmp="$(mktemp "${settings}.XXXXXX")"; then
    echo "could not be written: no temporary file could be made beside it"
    return 1
  fi
  if [[ -f "$settings" ]] && ! cp -p "$settings" "$tmp"; then
    rm -f "$tmp"
    echo "could not be written: it could not be copied"
    return 1
  fi
  if ! "$@" >"$tmp"; then
    rm -f "$tmp"
    echo "could not be written: what was to replace it could not be made"
    return 1
  fi
  if ! mv -f "$tmp" "$settings"; then
    rm -f "$tmp"
    echo "could not be written: it could not be replaced"
    return 1
  fi
}

# The settings entry that runs the home guard, as a file holding the JSON object
# molt writes. One of Molt's own files, the same on every sleeve: it names the
# guard as ~/.config/molt/claude-home-guard.sh, outside any Claude config dir,
# so it holds no machine's path and runs whichever config dir a session read.
# The claude liberator writes it into the user settings, and the agents
# liberator into each home's (issue 0030).
molt_claude_hook_entry() {
  echo "${MOLT_ROOT}/templates/claude/home-guard-hook.json"
}

# The jq filters that read and write that entry, with it bound to $want. It is
# the one UserPromptSubmit entry that runs the guard's command; any other entry
# is somebody else's, and is kept. GET gives null when there is none. Read by
# the liberators and lib/agent.sh, and so unused here.
# shellcheck disable=SC2016,SC2034 # $want is jq's, not the shell's
MOLT_CLAUDE_HOOK_GET='first(.hooks.UserPromptSubmit[]? | select(any(.hooks[]?; .command == $want.hooks[0].command))) // null'
# shellcheck disable=SC2016,SC2034
MOLT_CLAUDE_HOOK_SET='.hooks.UserPromptSubmit = ([.hooks.UserPromptSubmit[]? | select(any(.hooks[]?; .command == $want.hooks[0].command) | not)] + [$want])'

# A Claude Code process: the native binary, which runs with argv0 claude, by
# name or by an absolute path (the desktop app's has a space in it), or an npm
# install, which node runs by its bin link or its cli.js. Matched against the
# whole command line with pgrep -f; pgrep -x matches a process name, which
# misses running processes on macOS. Every arm is anchored on argv0, so `ls
# ~/.config/claude`, a grep or an npm ls naming the package is not Claude
# Code. The path arm allows a space only where the next character starts no
# other argument, ie is not / or -. A relative ./claude is not matched.
MOLT_CLAUDE_PROCESS_PATTERN='^(/[^ ]*( [^/ -][^ ]*)*/)?claude( |$)|^([^ ]*/)?node ([^ ]*/)?claude( |$)|^([^ ]*/)?node .*@anthropic-ai/claude-code/cli'

# The Claude Code processes this user is running, "pid command line" a line,
# the command line whole; nothing when there are none. ps names them, because
# procps' pgrep -l prints a process's name and macOS's its arguments; a process
# that has gone by then is named by its pid alone. Fails when pgrep cannot
# answer. The claude liberator asks it before it moves Claude Code's state, and
# molt agent start before it starts a session under a name one already has.
molt_claude_processes() {
  local pids list rows rc=0 ancestors=()
  # macOS's pgrep leaves out its own ancestors unless given -a, so molt run from
  # inside a Claude Code session would not see that session. procps' pgrep
  # leaves out only itself, and its -a means something else.
  if [[ "$(molt_platform)" == "macos" ]]; then
    ancestors=(-a)
  fi
  pids="$(pgrep ${ancestors+"${ancestors[@]}"} -u "$(id -u)" -f "$MOLT_CLAUDE_PROCESS_PATTERN")" || rc=$?
  case "$rc" in
    0) ;;
    1) return 0 ;;
    *) return 1 ;;
  esac
  list="$(printf '%s\n' "$pids" | paste -sd, -)"
  # An argument can hold a newline, and ps prints it as it is: a line that
  # starts with one of these pids starts a row, and any other line continues
  # the row before it, so an argument after one, such as --name, is still read.
  rows="$( { ps -o pid=,args= -p "$list" 2>/dev/null || true; } \
            | awk -v pids=",$list," '
                { sub(/^ +/, "") }
                $1 ~ /^[0-9]+$/ && index(pids, "," $1 ",") { if (row != "") print row; row = $0; next }
                row != "" { row = row " " $0 }
                END { if (row != "") print row }')"
  if [[ -n "$rows" ]]; then
    echo "$rows"
  else
    echo "$pids"
  fi
}

# Where Claude Code reads its managed settings, which nothing a user or an agent
# writes can override: managed-settings.json, and the drop-ins beside it in
# managed-settings.d/. Root-owned; molt writes molt-sysadm.json there through
# sudo, and its sidecar, and nothing else (ST0006 WP06). MOLT_CLAUDE_MANAGED_DIR
# stands in for it where set, which the tests do, so no test reaches the host's
# (issue 0061).
molt_claude_managed_dir() {
  if [[ -n "${MOLT_CLAUDE_MANAGED_DIR:-}" ]]; then
    echo "$MOLT_CLAUDE_MANAGED_DIR"
    return 0
  fi
  case "$(molt_platform)" in
    macos) echo "/Library/Application Support/ClaudeCode" ;;
    *)     echo "/etc/claude-code" ;;
  esac
}

# Where AppArmor reads its profiles on a Linux sleeve. Root-owned; molt writes
# bwrap-userns-restrict there through sudo, with its sidecar and the distro's
# copy beside it, and nothing else (issue 0032). MOLT_APPARMOR_DIR stands in
# for it where set, which the tests do, so no test reaches the host's
# (issue 0061).
molt_apparmor_dir() {
  echo "${MOLT_APPARMOR_DIR:-/etc/apparmor.d}"
}

# True when this sleeve's AppArmor parses the profile file $1, read with the
# includes in molt_apparmor_dir, unprivileged and loading nothing. Fails,
# printing why, with apparmor_parser absent or the parse refused; the parser's
# own words go to stderr.
molt_apparmor_parses() {
  local profile
  profile="$(molt_tilde "$1")"
  if ! command -v apparmor_parser &>/dev/null; then
    echo "apparmor_parser is not installed, so $profile cannot be parsed"
    return 1
  fi
  if ! apparmor_parser -Q -K -I "$(molt_apparmor_dir)" "$1" >&2; then
    echo "$profile does not parse under this sleeve's AppArmor"
    return 1
  fi
}

# Loads the AppArmor profile file $1 into the kernel, replacing what it holds of
# it, through sudo. Fails, printing why, with apparmor_parser or sudo absent or
# the load refused.
molt_apparmor_load() {
  local profile
  profile="$(molt_tilde "$1")"
  if ! command -v apparmor_parser &>/dev/null; then
    echo "apparmor_parser is not installed, so $profile was not loaded"
    return 1
  fi
  if ! command -v sudo &>/dev/null; then
    echo "sudo is not installed, so $profile was not loaded"
    return 1
  fi
  if ! sudo apparmor_parser -r "$1" >&2; then
    echo "apparmor_parser could not load $profile"
    return 1
  fi
}

# Puts the bytes of $1 at $2, a root-owned path, mode 644, through sudo: copied
# first to a temporary file of the user's, so what sudo installs is what was
# read, then installed with the directory made as needed. Never written any
# other way: without sudo, or with sudo refusing, nothing is. Fails, printing
# why.
molt_sudo_install() {
  local src="$1" dest="$2" tmp
  if ! command -v sudo &>/dev/null; then
    echo "sudo is not installed, so $dest was not written"
    return 1
  fi
  if ! tmp="$(mktemp "${TMPDIR:-/tmp}/molt-sudo.XXXXXX")" || ! cp "$src" "$tmp"; then
    rm -f "${tmp:-}"
    echo "$src could not be copied to a temporary file, so $dest was not written"
    return 1
  fi
  # An existing directory keeps the mode it has.
  if ! { [[ -d "$(dirname "$dest")" ]] || sudo install -d -m 755 "$(dirname "$dest")"; } \
      || ! sudo install -m 644 "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "sudo could not install $dest"
    return 1
  fi
  rm -f "$tmp"
}

# Removes the root-owned files $@ through sudo. Fails, printing why, with sudo
# absent or refusing.
molt_sudo_remove() {
  if ! command -v sudo &>/dev/null; then
    echo "sudo is not installed, so $* was not removed"
    return 1
  fi
  if ! sudo rm -f "$@"; then
    echo "sudo could not remove $*"
    return 1
  fi
}

# The state of the root-owned file $2 that molt installs from $1, byte for
# byte, one word: on a sleeve that wants it ($3 is 0), current, missing, stale,
# or foreign (a file molt did not write, which it leaves); on one that does not
# ($3 is anything else), absent, leftover (molt's, to remove), or unowned
# (somebody else's, left alone). Molt's is the one beside molt's sidecar,
# ${2}.molt-rendered. Fails, printing why, when the two cannot be compared.
molt_root_file_state() {
  local src="$1" target="$2" wanted="$3" differ=0
  if [[ "$wanted" -ne 0 ]]; then
    if [[ -f "${target}.molt-rendered" ]]; then
      echo leftover
    elif [[ -e "$target" ]]; then
      echo unowned
    else
      echo absent
    fi
    return 0
  fi
  if [[ -e "$target" && ! -f "${target}.molt-rendered" ]]; then
    echo foreign
    return 0
  elif [[ ! -e "$target" ]]; then
    echo missing
    return 0
  fi
  cmp -s "$src" "$target" || differ=$?
  case $differ in
    0) echo current ;;
    1) echo stale ;;
    *)
      echo "$(molt_tilde "$target") could not be compared with $(molt_tilde "$src")"
      return 1 ;;
  esac
}

# Installs the bytes of $1 as the root-owned file $2, through sudo, its sidecar
# first, so a file beside molt's sidecar is always one molt wrote. Fails,
# printing why.
molt_root_file_install() {
  local src="$1" target="$2" sidecar digest why
  if ! sidecar="$(mktemp "${TMPDIR:-/tmp}/molt-sidecar.XXXXXX")"; then
    echo "no temporary file could be made for the sidecar of $target, so nothing was written"
    return 1
  fi
  digest="$(molt_hash < "$src")" || digest=""
  if ! molt_render_sidecar "$src" "$digest" "$src" > "$sidecar"; then
    rm -f "$sidecar"
    echo "the sidecar of $target could not be written, so nothing was"
    return 1
  fi
  if ! why="$(molt_sudo_install "$sidecar" "${target}.molt-rendered")" \
      || ! why="$(molt_sudo_install "$src" "$target")"; then
    rm -f "$sidecar"
    echo "$why"
    return 1
  fi
  rm -f "$sidecar"
}

# Removes the root-owned file $1 that molt installed, and its sidecar, through
# sudo. Fails, printing why.
molt_root_file_remove() {
  molt_sudo_remove "$1" "${1}.molt-rendered"
}

# --- CLI Commands ---

cmd_list() {
  echo "${MOLT_NAME} v${MOLT_VERSION} — Liberators"
  echo ""

  # Get enabled list from manifest (if available)
  local enabled_list=" "
  local disabled_list=" "
  local has_manifest=0
  local manifest_liberators
  if manifest_liberators="$(molt_enabled_liberators 2>/dev/null)"; then
    has_manifest=1
    while IFS= read -r lib; do
      [[ -n "$lib" ]] && enabled_list="${enabled_list}${lib} "
    done <<< "$manifest_liberators"
  fi

  # Also parse disabled liberators from manifest directly
  if [[ "$has_manifest" -eq 1 ]]; then
    local manifest
    manifest="$(molt_find_manifest 2>/dev/null || echo "")"
    if [[ -n "$manifest" ]]; then
      local all_names
      all_names="$(_molt_table_entries liberator name "$manifest" | awk -F'\t' '$1 != "" && $2 == "name" { print $1 }')"
      while IFS= read -r lib; do
        [[ -z "$lib" ]] && continue
        if [[ "$enabled_list" != *" ${lib} "* ]]; then
          disabled_list="${disabled_list}${lib} "
        fi
      done <<< "$all_names"
    fi
  fi

  for lib in $(liberator_list); do
    local status_str
    if [[ "$has_manifest" -eq 1 ]]; then
      if [[ "$disabled_list" == *" ${lib} "* ]]; then
        status_str="disabled"
      elif [[ "$enabled_list" == *" ${lib} "* ]]; then
        if liberator_load "$lib" &>/dev/null && liberator_check "$lib" &>/dev/null; then
          status_str="installed"
        else
          status_str="not installed"
        fi
      else
        status_str="not in manifest"
      fi
    else
      if liberator_load "$lib" &>/dev/null && liberator_check "$lib" &>/dev/null; then
        status_str="installed"
      else
        status_str="not installed"
      fi
    fi
    echo "  $lib: $status_str"
  done
}

# Filesystem type for a path, as a short name ("apfs", "ext4", "fuse.prl_fsd").
# Linux and BSD/macOS disagree on how to ask, so try both.
molt_fstype() {
  local path="$1"
  [[ -e "$path" ]] || return 1

  # Branch on platform rather than probing. BSD stat does not merely fail on
  # GNU's `-f -c %T` -- it reads `-c` as the format string and prints it, so a
  # "try GNU first and fall back" probe silently returns "-c" on macOS.
  if [[ "$(molt_platform)" == "linux" ]]; then
    # Prefer df -T: it reports the mount type ("fuse.prl_fsd"), where stat -f
    # gives only the statfs magic ("fuseblk"). Both match the fuse* glob, but
    # naming the actual driver makes the warning far more actionable.
    local t
    t="$(df -T "$path" 2>/dev/null | awk 'NR==2 {print $2}')"
    [[ -n "$t" ]] && { printf '%s\n' "$t"; return 0; }
    stat -f -c %T "$path" 2>/dev/null
    return
  fi

  # macOS: df names the device, mount reports the type in parentheses:
  #   /dev/disk3s5 on /System/Volumes/Data (apfs, local, journaled, ...)
  local dev
  dev="$(df -k "$path" 2>/dev/null | awk 'NR==2 {print $1}')" || return 1
  [[ -n "$dev" ]] || return 1
  mount 2>/dev/null | grep "^${dev} on " | sed -n 's/.*(\([^,)]*\).*/\1/p' | head -1
}

# Report config files that bake in another user's absolute home path
# (/Users/<x> or /home/<x>, including JSON-escaped \/Users\/<x>, where <x> is
# not the current user). Echoes offending paths relative to dir, one per line.
# Empty output means clean. This catches non-portable configs like a raw iTerm2
# or VS Code export committed with hardcoded paths.
#
# /home/linuxbrew is not a foreign home (issue 0017). It holds Homebrew's default
# Linux prefix, /home/linuxbrew/.linuxbrew, and is a system account's home, the
# same on every machine, named by any shell file that starts Homebrew there.
molt_foreign_home_paths() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local me; me="$(whoami)"
  local f homes
  while IFS= read -r f; do
    # Strip backslashes first (octal \134) so JSON-escaped \/Users\/x
    # normalises to /Users/x, then match real home paths precisely.
    #
    # Capture the home paths, THEN match (issue 0008). This was one pipeline
    # ending in `grep -qvE`, which exits at the first foreign path; under
    # pipefail the upstream grep -oE then dies of SIGPIPE on a large file and the
    # whole test reads false, so a file with a foreign path near its top went
    # unreported. The -n test matters: a file mentioning "home" with no real
    # home path captures nothing, and `grep -qv` on an empty herestring matches
    # its one blank line and would report it.
    homes="$(tr -d '\134' < "$f" 2>/dev/null \
               | grep -oE '/(Users|home)/[A-Za-z0-9_.-]+' || true)"
    if [[ -n "$homes" ]] && grep -qvE "/(Users|home)/${me}(/|$)|^/home/linuxbrew$" <<< "$homes"; then
      echo "${f#"$dir"/}"
    fi
  done < <(grep -rIlE '(Users|home)' "$dir" 2>/dev/null)
}

# For doctor's passing molt-on-PATH line: when the tree this doctor runs from
# is not the one that serves molt, says so, in words (A3: a pass names no
# path), and names molt use, the only step that switches the sleeve's tree.
# A dev clone's doctor on a brew sleeve once advised a resleeve that would have
# linked the sleeve to the clone (issue 0067). Nothing when they are one tree.
_molt_doctor_other_tree_note() {
  local link served tree own
  link="$(molt_switch_link)"
  if [[ -e "$link" || -L "$link" ]]; then
    served="$(molt_served_tree)" || return 0
  else
    served="$(molt_brew_on_path)" || return 0
  fi
  molt_same_file "$served" "$MOLT_ROOT" && return 0
  tree="$(molt_tree)"
  case "$tree" in
    dev|opt)
      if own="$(_molt_use_root "$tree" 2>/dev/null)" && molt_same_file "$own" "$MOLT_ROOT"; then
        echo "; this doctor runs from the $tree tree, which does not serve molt, and molt use $tree switches the sleeve to it"
      else
        echo "; this doctor runs from a $tree tree that is not this sleeve's, so nothing switches the sleeve to it; molt use says which tree serves molt"
      fi ;;
    *) echo "; this doctor runs from the $tree tree, which does not serve molt; molt use says which tree does" ;;
  esac
}

# A check that passes says what passed in words and names no path; only a check
# that fails about a path names it (contract A3, issue 0066). `command -v molt`
# says where the running copy lives.
cmd_doctor() {
  echo "${MOLT_NAME} v${MOLT_VERSION} — Doctor"
  molt_version_line
  echo ""

  # Counted as the checks run, never stored: a total written down is wrong as
  # soon as a check is added (hv, 23 Oct). A check that could not run is not a
  # pass, so it counts among the checks that did not pass.
  local checks=0
  local not_passed=0

  # MOLT_ROOT is valid
  checks=$((checks + 1))
  if [[ -x "${MOLT_ROOT:-}/bin/molt" && -d "${MOLT_ROOT:-}/lib" ]]; then
    echo "Checking MOLT_ROOT... ✓ found"
  else
    echo "Checking MOLT_ROOT... ✗ invalid or not found"
    not_passed=$((not_passed + 1))
  fi

  # The tree molt runs from (ST0008). A dev tree carries test/; opt and brew
  # carry none, and are checked file by file against their manifest instead.
  # An old-form or missing manifest fails opt and is a note in brew (devbin
  # docs/dev-opt-brew.md T3, as decision 58 amends it).
  checks=$((checks + 1))
  local tree tree_drift line form_fault commit_fault
  tree="$(molt_tree)"
  form_fault="$(molt_install_form_fault "$MOLT_ROOT")"
  case "$tree" in
    dev)
      local dirs_ok=1
      for dir in lib liberators test; do
        if [[ ! -d "${MOLT_ROOT}/$dir" ]]; then
          dirs_ok=0
        fi
      done
      commit_fault="$(molt_tree_commit_fault "$MOLT_ROOT")"
      if [[ -n "$commit_fault" ]]; then
        echo "Checking tree... ✗ dev, its commit cannot be read: $commit_fault"
        not_passed=$((not_passed + 1))
      elif [[ "$dirs_ok" -eq 1 ]]; then
        echo "Checking tree... ✓ dev"
      else
        echo "Checking tree... ⚠ dev, missing directories"
        not_passed=$((not_passed + 1))
      fi ;;
    brew)
      if [[ -n "$form_fault" ]]; then
        echo "Checking tree... ✓ brew; note: $form_fault"
      elif tree_drift="$(molt_install_drift "$MOLT_ROOT")" && [[ -z "$tree_drift" ]]; then
        echo "Checking tree... ✓ brew: every file matches its manifest"
      else
        echo "Checking tree... ⚠ brew, not what its manifest says"
        while IFS= read -r line; do
          [[ -z "$line" ]] || echo "         $line"
        done <<< "$tree_drift"
        not_passed=$((not_passed + 1))
      fi ;;
    opt)
      if tree_drift="$(molt_install_drift "$MOLT_ROOT")" && [[ -z "$tree_drift" ]]; then
        echo "Checking tree... ✓ opt: every file matches its manifest"
      else
        echo "Checking tree... ⚠ opt, not what its manifest says"
        while IFS= read -r line; do
          [[ -z "$line" ]] || echo "         $line"
        done <<< "$tree_drift"
        not_passed=$((not_passed + 1))
      fi ;;
    *)
      if [[ -n "$form_fault" ]]; then
        echo "Checking tree... ✗ $form_fault"
      else
        echo "Checking tree... ✗ $MOLT_ROOT is no dev, opt or brew tree"
      fi
      not_passed=$((not_passed + 1)) ;;
  esac

  # The switch molt use sets must be what PATH runs: the link when there is
  # one, and Homebrew's molt when there is none.
  checks=$((checks + 1))
  local shadow
  shadow="$(molt_path_shadow)"
  if [[ -n "$shadow" ]]; then
    echo "Checking molt on PATH... ⚠ $shadow"
    not_passed=$((not_passed + 1))
  elif [[ -e "$(molt_switch_link)" || -L "$(molt_switch_link)" ]]; then
    echo "Checking molt on PATH... ✓ molt use's link$(_molt_doctor_other_tree_note)"
  else
    echo "Checking molt on PATH... ✓ brew's; no link of molt's$(_molt_doctor_other_tree_note)"
  fi

  # User stack repo
  checks=$((checks + 1))
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" && -d "$user_repo" ]]; then
    # Resolving via the lowercase fallback means this sleeve's directory does not
    # match the convention. Harmless on case-insensitive storage, which is why it
    # went unnoticed for months; fatal on a case-sensitive sleeve, where the
    # dotfile symlinks are raw-pointed at one specific spelling. Say so rather
    # than absorb it -- a tolerant lookup would hide exactly this.
    # Compare against the name as STORED, not as resolved. On a case-insensitive
    # filesystem the capitalised search path matches a lowercase directory by
    # folding, so basename returns the spelling we asked for and the drift is
    # invisible -- which is the whole failure mode. Ask the parent directory what
    # the entry is actually called.
    local want_repo real_repo parent base entry entry_name
    want_repo="Molt-$(whoami)"
    parent="$(dirname "$user_repo")"
    base="$(basename "$user_repo")"
    real_repo="$base"
    for entry in "$parent"/*; do
      [[ -d "$entry" ]] || continue
      entry_name="$(basename "$entry")"
      if [[ "$(printf '%s' "$entry_name" | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"')" \
         == "$(printf '%s' "$base" | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"')" ]]; then
        real_repo="$entry_name"
        break
      fi
    done
    if [[ "$real_repo" != "$want_repo" ]]; then
      echo "Checking user stack repo... ⚠ $user_repo"
      echo "         Directory is stored as '${real_repo}'; the convention is '${want_repo}'."
      echo "         Resolved via the compatibility fallback. Rename it and re-run"
      echo "         'molt resleeve' so the dotfile symlinks are regenerated too."
      not_passed=$((not_passed + 1))
    else
      echo "Checking user stack repo... ✓ found"
    fi
  else
    echo "Checking user stack repo... ✗ not found"
    not_passed=$((not_passed + 1))
  fi

  # Manifest
  checks=$((checks + 1))
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null || echo "")"
  if [[ -n "$manifest" && -f "$manifest" ]]; then
    # user_repo is never consumed -- it cannot be, since you must already know
    # the repo to find the manifest inside it. Left as prose it silently drifts
    # out of date, which is how a lowercase declaration survived the rename. So
    # assert it instead: dead documentation becomes a live check.
    #
    # grep is asked on its own, for its status: 1 is a manifest that declares
    # no user_repo, which passes, and anything above is a manifest grep could
    # not read. In the pipeline it was, either ended doctor here, without a
    # word, under bin/molt's pipefail (issue 0028).
    local declared_repo="" declared_lines grep_status=0
    declared_lines="$(grep -E '^[[:space:]]*user_repo[[:space:]]*=' "$manifest" 2>&1)" || grep_status=$?
    if [[ $grep_status -eq 0 ]]; then
      declared_repo="$(printf '%s\n' "$declared_lines" | head -n 1 | sed -E 's/.*=[[:space:]]*"?([^"]*)"?.*/\1/')"
    fi
    if [[ $grep_status -gt 1 ]]; then
      echo "Checking manifest... ⚠ $manifest"
      echo "         It could not be read for its user_repo declaration: ${declared_lines:-grep exited $grep_status}"
      not_passed=$((not_passed + 1))
    elif [[ -n "$declared_repo" && -n "${real_repo:-}" && "$declared_repo" != "$real_repo" ]]; then
      echo "Checking manifest... ⚠ $manifest"
      echo "         Declares user_repo = '${declared_repo}' but the directory is '${real_repo}'."
      echo "         Nothing reads this key, so the mismatch is silent -- fix it before"
      echo "         something starts trusting it."
      not_passed=$((not_passed + 1))
    else
      echo "Checking manifest... ✓ found"
    fi
  else
    echo "Checking manifest... ⚠ no molt.toml found"
    not_passed=$((not_passed + 1))
  fi

  # Liberators: each .sh has a _check function
  checks=$((checks + 1))
  # A pass carries no count; a failure says how many of how many, both counted
  # here, and names them (hv, 23 Oct).
  local lib_errors=0
  local lib_count=0
  local lib_unchecked=""
  for lib in $(liberator_list); do
    lib_count=$((lib_count + 1))
    local script="${MOLT_LIBERATORS_DIR}/${lib}.sh"
    # Check for _check function (source and test); a script gone since the
    # listing has none
    if [[ ! -f "$script" ]] || ! grep -q "^${lib}_check()" "$script" 2>/dev/null; then
      lib_errors=$((lib_errors + 1))
      lib_unchecked="${lib_unchecked:+$lib_unchecked, }$lib"
    fi
  done
  if [[ "$lib_errors" -eq 0 ]]; then
    echo "Checking liberators... ✓ all have _check"
  else
    echo "Checking liberators... ⚠ $lib_errors of $lib_count have no _check: $lib_unchecked"
    not_passed=$((not_passed + 1))
  fi

  # GNOME keys go through the one gsettings that reaches dconf, chosen here so
  # the liberator checks below ask nothing again. One that does not reaches a
  # keyfile GNOME never reads, and the checks read schema defaults (issue 0047).
  if [[ "$(molt_platform)" == "linux" ]]; then
    checks=$((checks + 1))
    local gs_status=0
    molt_gsettings_find || gs_status=$?
    case $gs_status in
      0) echo "Checking gsettings... ✓ found, and it reaches dconf" ;;
      1) echo "Checking gsettings... ✓ none on PATH, so no GNOME keys to set" ;;
      *)
        echo "Checking gsettings... ⚠ $MOLT_GSETTINGS_FAULT"
        not_passed=$((not_passed + 1)) ;;
    esac
  fi

  # Enabled liberator status
  checks=$((checks + 1))
  if [[ -n "$manifest" ]]; then
    local enabled
    enabled="$(molt_enabled_liberators 2>/dev/null || echo "")"
    local enabled_count=0
    local not_installed_count=0
    local not_installed=""
    local not_installed_why=""
    local why=""
    # On fd 3, so a check keeps the caller's stdin and cannot read the rest of
    # the list (issue 0075; see molt_resleeve).
    while IFS= read -r lib <&3; do
      [[ -z "$lib" ]] && continue
      enabled_count=$((enabled_count + 1))
      # Capture rather than discard. The check function already prints exactly
      # why it failed; &>/dev/null threw that away and left the operator with a
      # ratio and no lead. Assign separately from `local` -- `local x="$(...)"`
      # returns local's status, not the command's (SC2155).
      if ! why="$(liberator_load "$lib" 2>&1 && liberator_check "$lib" 2>&1)"; then
        not_installed_count=$((not_installed_count + 1))
        not_installed="${not_installed:+$not_installed, }$lib"
        # As the check printed them: molt's prefix already names the
        # liberator, and the verdict line names it, in the same order, for a
        # line without one (issue 0026).
        while IFS= read -r line; do
          [[ -z "$line" ]] && continue
          not_installed_why="${not_installed_why}         ${line}"$'\n'
        done <<< "$(echo "$why" | head -3)"
      fi
    done 3<<< "$enabled"
    # This once printed ✓ for every ratio, so a sleeve with nothing installed
    # passed and the missing liberator was never named. A count is not a verdict: a pass
    # carries none, and a failure says how many of how many, both counted
    # here, and names them (hv, 23 Oct). It matters most when it is least
    # visible: when a liberator breaks estate-wide, this is the instrument that
    # should notice.
    if [[ "$enabled_count" -eq 0 ]]; then
      echo "Checking enabled liberators... ✓ none enabled"
    elif [[ "$not_installed_count" -eq 0 ]]; then
      echo "Checking enabled liberators... ✓ all installed"
    else
      echo "Checking enabled liberators... ⚠ $not_installed_count of $enabled_count not installed: ${not_installed}"
      [[ -n "$not_installed_why" ]] && printf '%s' "$not_installed_why"
      echo "         Run \`molt resleeve\` to install, or \`molt list\` for status."
      not_passed=$((not_passed + 1))
    fi
  else
    echo "Checking enabled liberators... ⚠ no manifest (skipped)"
    not_passed=$((not_passed + 1))
  fi

  # External dependencies
  checks=$((checks + 1))
  local deps_ok=1
  local missing_deps=""
  local required_deps=(bats envsubst)
  for dep in "${required_deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      deps_ok=0
      missing_deps="$missing_deps $dep"
    fi
  done
  if [[ "$deps_ok" -eq 1 ]]; then
    echo "Checking external dependencies... ✓ ${required_deps[*]}"
  else
    echo "Checking external dependencies... ⚠ missing:$missing_deps"
    not_passed=$((not_passed + 1))
  fi

  # SSH key (check common names + any key referenced in SSH config)
  checks=$((checks + 1))
  local ssh_key_found=""
  for keyname in id_ed25519 id_rsa; do
    if [[ -f "$HOME/.ssh/$keyname" ]]; then
      ssh_key_found="$keyname"
      break
    fi
  done
  if [[ -z "$ssh_key_found" ]] && [[ -f "$HOME/.ssh/config" ]]; then
    # Check keys referenced in SSH config
    local referenced_key
    referenced_key="$(grep -m1 'IdentityFile' "$HOME/.ssh/config" 2>/dev/null | awk '{print $2}' | sed "s|~|$HOME|" || true)"
    if [[ -n "$referenced_key" ]] && [[ -f "$referenced_key" ]]; then
      ssh_key_found="$(basename "$referenced_key")"
    fi
  fi
  if [[ -n "$ssh_key_found" ]]; then
    echo "Checking SSH key... ✓ found"
  else
    echo "Checking SSH key... ⚠ no SSH key found"
    not_passed=$((not_passed + 1))
  fi

  # GitHub auth
  checks=$((checks + 1))
  local gh_auth_output
  if gh_auth_output="$(timeout 5 ssh -T git@github.com 2>&1)"; then
    :
  fi
  if [[ "$gh_auth_output" == *"successfully authenticated"* ]]; then
    local gh_user
    gh_user="$(echo "$gh_auth_output" | grep -o 'Hi [^!]*' | sed 's/Hi //')"
    echo "Checking GitHub auth... ✓ authenticated as $gh_user"
  else
    echo "Checking GitHub auth... ⚠ not authenticated"
    not_passed=$((not_passed + 1))
  fi

  # Config carries no foreign (other-user) absolute home paths
  checks=$((checks + 1))
  local foreign=""
  if [[ -n "$user_repo" ]]; then
    foreign="$(molt_foreign_home_paths "$user_repo/config")"
  fi
  if [[ -z "$foreign" ]]; then
    echo "Checking config for foreign home paths... ✓ none"
  else
    echo "Checking config for foreign home paths... ⚠ found in: $(echo "$foreign" | tr '\n' ' ')"
    not_passed=$((not_passed + 1))
  fi

  # The stack itself lives on a local filesystem
  checks=$((checks + 1))
  local foreign_fs=""
  local p
  for p in "${MOLT_ROOT:-}" "${user_repo:-}"; do
    [[ -n "$p" && -d "$p" ]] || continue
    local fstype
    fstype="$(molt_fstype "$p")" || continue
    case "$fstype" in
      fuse*|prl_fsd|nfs*|smb*|cifs|afpfs|webdav|osxfuse|vboxsf|9p|virtiofs)
        foreign_fs="${foreign_fs}${foreign_fs:+, }${p} (${fstype})" ;;
    esac
  done
  if [[ -z "$foreign_fs" ]]; then
    echo "Checking stack is on local storage... ✓"
  else
    echo "Checking stack is on local storage... ⚠ ${foreign_fs}"
    echo "         This sleeve is running someone else's checkout over a network or"
    echo "         guest mount. It shares one working tree, index and HEAD with the"
    echo "         host, so every command here reports success while changing files"
    echo "         that do not belong to this machine. Clone the repos locally."
    not_passed=$((not_passed + 1))
  fi

  # Each managed repo's core.ignorecase matches what its disk does with case
  #
  # git sets core.ignorecase true when it makes a repo on a disk that folds
  # case, which it finds by asking for .git/CoNfIg and getting .git/config. On
  # such a disk, every Mac's, true is the truth: this check warned on it, so
  # doctor could never pass on a Mac (hv, 23 Oct). What is wrong is a value the
  # disk does not bear out, as in a repo copied from another machine rather
  # than cloned. false on a disk that folds case lets git track paths differing
  # only in case, which the disk cannot hold apart, and true on a disk that
  # keeps case hides a rename that changes only case. git's own question,
  # asked here without writing anything, says what the disk does.
  checks=$((checks + 1))
  local case_folds=0 case_wrong="" case_fixes="" folds disk ignorecase
  for p in "${MOLT_ROOT:-}" "${user_repo:-}"; do
    [[ -n "$p" && -d "$p/.git" ]] || continue
    folds=false disk="keeps case"
    if [[ "$p/.git/config" -ef "$p/.git/CoNfIg" ]]; then
      folds=true disk="folds case"
    fi
    ignorecase="$(git -C "$p" config --bool --get core.ignorecase 2>/dev/null)" || ignorecase=false
    if [[ "$ignorecase" != "$folds" ]]; then
      case_wrong="${case_wrong}${case_wrong:+, }$(basename "$p")"
      case_fixes="${case_fixes}         $(basename "$p") has core.ignorecase=${ignorecase} on a disk that ${disk}:"$'\n'
      case_fixes="${case_fixes}           git -C $p config core.ignorecase ${folds}"$'\n'
    elif [[ "$folds" == true ]]; then
      case_folds=1
    fi
  done
  if [[ -z "$case_wrong" ]]; then
    echo "Checking git case sensitivity... ✓ core.ignorecase matches the disk"
    if [[ "$case_folds" -eq 1 ]]; then
      echo "         The disk folds case, so a rename that changes only case does not"
      echo "         reach the index by itself, and a sleeve on a disk that keeps case"
      echo "         then pulls the old spelling and every symlink to it dangles: that"
      echo "         is what hid the repo rename. Rename with 'git mv -f Old New', then"
      echo "         'git status' to confirm the rename is staged before you commit."
    fi
  else
    echo "Checking git case sensitivity... ⚠ core.ignorecase does not match the disk in ${case_wrong}"
    printf '%s' "$case_fixes"
    echo "         git sets it when it makes a repo, by asking the disk, so a repo"
    echo "         copied from another machine rather than cloned keeps that"
    echo "         machine's answer, and git and the disk then disagree about which"
    echo "         paths name the same file."
    not_passed=$((not_passed + 1))
  fi

  # The font this instance declares is one the system can actually resolve
  #
  # Nothing installs fonts. A fresh sleeve gets the config naming the font and
  # none of the font, and fontconfig then falls back silently -- the terminal
  # opens fine, just without powerline or devicon glyphs, with no error anywhere.
  # Same shape as the dangling-symlink and mtime defects: everything reports
  # success, the result is wrong.
  checks=$((checks + 1))
  local font_family="" font_status=0
  font_family="$(molt_instance_var MOLT_FONT_FAMILY)" || font_status=$?
  # With no user repo, or no host name, nothing declares a font.
  if [[ $font_status -eq 3 ]]; then
    font_family=""
  fi
  if [[ $font_status -eq 2 ]]; then
    echo "Checking declared font... ⚠ $font_family"
    not_passed=$((not_passed + 1))
  elif [[ -z "$font_family" ]]; then
    echo "Checking declared font... ⚠ this instance declares no MOLT_FONT_FAMILY"
    not_passed=$((not_passed + 1))
  else
    # Captured through ||, so errexit cannot end doctor on the very answers
    # this check exists to report (issue 0064).
    local font_rc=0
    molt_font_available "$font_family" || font_rc=$?
    case $font_rc in
      0)
        echo "Checking declared font... ✓ ${font_family}" ;;
      1)
        echo "Checking declared font... ⚠ ${font_family} is NOT installed"
        echo "         The config names this font; nothing on this machine provides it."
        echo "         fontconfig will fall back without erroring, so the terminal opens"
        echo "         looking fine and the powerline and devicon glyphs are simply gone."
        echo "         Install it into ~/.local/share/fonts (Linux, then 'fc-cache -f')"
        echo "         or ~/Library/Fonts (macOS)."
        not_passed=$((not_passed + 1)) ;;
      *)
        # Never a tick, and not ⚠ either: "I could not measure this" is not a
        # finding about the sleeve, so the marker is ?, and the lines below say
        # why. Nor is it a pass: it counts among the checks that did not pass,
        # since "All checks passed." would claim a check that never ran (hv,
        # 23 Oct).
        echo "Checking declared font... ? cannot verify ${font_family}"
        echo "         fc-list is not on this machine, so whether the font resolves is"
        echo "         unknown. Not reporting ok: that would assert something unmeasured."
        echo "         Install fontconfig if you want this checked."
        not_passed=$((not_passed + 1)) ;;
    esac
  fi

  # The managed floor (ST0006 WP06): on a sleeve with a sysadm agent, its
  # denies are in Claude Code's managed drop-in, where the agent cannot edit
  # them; on one without, no floor molt wrote is left behind.
  checks=$((checks + 1))
  local floor_state floor_faults floor_fault
  if floor_state="$(molt_agent_floor_state)"; then
    floor_faults="$(molt_agent_floor_faults "$floor_state")"
  else
    floor_faults="$floor_state"
  fi
  if [[ -z "$floor_faults" ]]; then
    case "$floor_state" in
      current) floor_fault="in place" ;;
      unowned) floor_fault="none needed; not molt's, left as is" ;;
      *)       floor_fault="none needed, and none of molt's here" ;;
    esac
    echo "Checking managed floor... ✓ $floor_fault"
  else
    echo "Checking managed floor... ⚠"
    while IFS= read -r floor_fault; do
      echo "         $floor_fault"
    done <<< "$floor_faults"
    not_passed=$((not_passed + 1))
  fi

  # The sandbox profile (issue 0032): on a Linux sleeve with an ops or docs
  # agent, molt's bwrap-userns-restrict is in place and bwrap's children can
  # make the sandbox's user namespace; on any other, none of molt's is left.
  checks=$((checks + 1))
  local sandbox_state sandbox_faults sandbox_fault
  if sandbox_state="$(molt_agent_sandbox_state)"; then
    sandbox_faults="$(molt_agent_sandbox_faults "$sandbox_state")"
  else
    sandbox_faults="$sandbox_state"
  fi
  if [[ -z "$sandbox_faults" ]]; then
    case "$sandbox_state" in
      current) sandbox_fault="in place" ;;
      unowned) sandbox_fault="none needed; not molt's, left as is" ;;
      *)       sandbox_fault="none needed, and none of molt's here" ;;
    esac
    echo "Checking sandbox profile... ✓ $sandbox_fault"
  else
    echo "Checking sandbox profile... ⚠"
    while IFS= read -r sandbox_fault; do
      echo "         $sandbox_fault"
    done <<< "$sandbox_faults"
    not_passed=$((not_passed + 1))
  fi

  echo ""
  molt_doctor_verdict "$not_passed" "$checks"
}

# Prints doctor's closing line for $1 checks not passed of the $2 that ran, and
# fails when any did not pass, so a caller can tell from the exit (issue 0055).
molt_doctor_verdict() {
  if [[ "$1" -eq 0 ]]; then
    echo "All checks passed."
    return 0
  fi
  echo "$1 of $2 checks did not pass. Review above for details."
  return 1
}

cmd_test() {
  local target="${1:-}"

  # In opt and brew there is no test/, and the lint would check bytes the
  # manifest already vouches for: both run in the dev tree (ST0008).
  molt_require_dev_tree "molt test" || return 1

  if ! command -v bats &>/dev/null; then
    molt_error "bats is required to run tests. Install via: utilz or apt install bats"
    return 1
  fi

  local test_dir="${MOLT_ROOT}/test"
  if [[ ! -d "$test_dir" ]]; then
    molt_error "Test directory not found: $test_dir"
    return 1
  fi

  # Run ShellCheck first (if available).
  #
  # set -e would abort here on failure, which exits non-zero but prints no test
  # output at all -- and an operator who reads "no 'not ok' lines" as success has
  # been told the suite passed when it never ran. Say so instead. This is the
  # same absent-signal-read-as-positive shape as launchctl returning 0 for a
  # missing script and the old mtime check reporting fresh when it could not
  # tell: the answer in each is to fail loudly rather than quietly.
  if ! _test_shellcheck; then
    molt_error "TESTS DID NOT RUN. ShellCheck failed above; fix those first."
    return 1
  fi

  if [[ -n "$target" ]]; then
    # Run specific liberator test
    local target_file="$test_dir/liberators/${target}.bats"
    if [[ ! -f "$target_file" ]]; then
      molt_error "Test not found: $target_file"
      return 1
    fi
    bats "$target_file"
  else
    # Run all tests
    local test_files=()
    for f in "$test_dir"/*.bats; do
      [[ -f "$f" ]] && test_files+=("$f")
    done
    for f in "$test_dir"/liberators/*.bats; do
      [[ -f "$f" ]] && test_files+=("$f")
    done
    if [[ ${#test_files[@]} -eq 0 ]]; then
      molt_error "No test files found"
      return 1
    fi
    # Files can exist and still declare no tests -- a new .bats file with no
    # `load` line, or one whose @test blocks were all commented out. bats then
    # reports "1..0" and exits 0, which reads as a pass.
    local declared
    declared="$(grep -c '^[[:space:]]*@test' "${test_files[@]}" 2>/dev/null \
                | awk -F: '{n += $NF} END {print n + 0}')"
    if [[ "$declared" -eq 0 ]]; then
      molt_error "Found ${#test_files[@]} test file(s) but zero @test declarations. Refusing to report a pass."
      return 1
    fi
    bats "${test_files[@]}"
  fi
}

_test_shellcheck() {
  if ! command -v shellcheck &>/dev/null; then
    molt_warn "shellcheck not found, skipping static analysis"
    return 0
  fi

  local scripts=()
  scripts+=("${MOLT_ROOT}/bin/molt")
  for f in "${MOLT_ROOT}"/lib/*.sh; do
    [[ -f "$f" ]] && scripts+=("$f")
  done
  for f in "${MOLT_ROOT}"/liberators/*.sh; do
    [[ -f "$f" ]] && scripts+=("$f")
  done

  molt_info "ShellCheck: ${#scripts[@]} scripts..."
  local failed=0
  for script in "${scripts[@]}"; do
    if ! shellcheck -x "$script" 2>&1; then
      failed=1
    fi
  done

  if [[ "$failed" -eq 1 ]]; then
    molt_error "ShellCheck found issues (see above)"
    return 1
  fi
  molt_info "ShellCheck: all clean"
}

# --- Resleeve ---

# The resleeve itself, for `molt resleeve` and the end of `molt upgrade`. $1 is
# true for a dry run. $2 is false when the sleeve must not be called ready even
# though every liberator is: molt upgrade passes it when an upgrade hook or a
# pull has failed, and gives the verdict itself.
#
# Every failure here is checked by hand. molt upgrade calls this on the left of
# `||`, where set -e does not apply, so a failed lookup would otherwise run on
# to "Sleeve ready".
molt_resleeve() {
  local dry_run="$1" claim_ready="$2"

  if $dry_run; then
    echo "${MOLT_NAME} v${MOLT_VERSION} — Dry Run"
  else
    echo "${MOLT_NAME} v${MOLT_VERSION} — My Opinionated Local Terminal"
    echo "Needlecasting stack to new sleeve..."
  fi
  echo "Sleeve: $(molt_hostname) | Platform: $(molt_platform)"
  echo ""

  local user_repo
  if ! user_repo="$(molt_find_user_repo)"; then
    molt_error "Cannot resleeve without a user config repo."
    return 1
  fi

  molt_info "Stack found: $user_repo"
  molt_info "Loading liberators..."

  local liberators manifest
  if ! liberators="$(molt_run_liberators)"; then
    molt_error "Cannot resleeve: $liberators"
    return 1
  fi
  if manifest="$(molt_find_manifest 2>/dev/null)"; then
    molt_info "Manifest: $manifest"
  else
    molt_info "No manifest found, using all available liberators"
  fi

  local would_install=0
  # A failure says how many of how many ran, both counted here, and names them.
  local failed=0 ran=0 failed_names=""
  echo ""

  # The list is read on fd 3, and each liberator keeps the caller's stdin.
  # Fed on stdin, an install that read stdin, as an installer or a sudo prompt
  # can, read the rest of the list, and the run ended there as though it were
  # done (issue 0075). The upgrade and maintain loops read theirs the same way.
  while IFS= read -r lib <&3; do
    [[ -z "$lib" ]] && continue
    if ! liberator_load "$lib" 2>/dev/null; then
      molt_warn "Skipping unknown liberator: $lib"
      continue
    fi
    ran=$((ran + 1))
    if ! liberator_check "$lib" 2>/dev/null; then
      if $dry_run; then
        echo "  $lib: WOULD INSTALL"
        would_install=$((would_install + 1))
      else
        if liberator_run "$lib" install; then
          echo "  $lib: ✓ installed"
        else
          molt_error "Liberator failed: $lib — continuing with remaining liberators"
          failed=$((failed + 1))
          failed_names="${failed_names:+$failed_names, }$lib"
        fi
      fi
    else
      echo "  $lib: ✓ ok"
    fi
  done 3<<< "$liberators"

  echo ""
  if $dry_run; then
    if [[ $would_install -eq 0 ]]; then
      molt_info "All liberators are installed. Nothing to do."
    else
      molt_info "$would_install liberator(s) would be installed. Run \`molt resleeve\` to apply."
    fi
  else
    if [[ $failed -gt 0 ]]; then
      molt_error "$failed of $ran liberators failed: $failed_names. Review errors above."
      return 1
    elif $claim_ready; then
      molt_info "Sleeve ready. Welcome back."
    fi
  fi
}

# --- Upgrade ---

# Pulls the repo $1, fast-forward only, $2 naming it for the user (eg
# Framework). A repo with no upstream branch is the one pull not tried: it
# warns that the pull was skipped and fails with status 2. Any other failure
# is an error naming the repo, with git's own words under it, and status 1
# (issue 0015). No upstream is read from the branch's config, or a HEAD on no
# branch, not from git rev-parse @{upstream}, which fails as well for an
# upstream configured and gone: that pull is tried, and fails with git's
# reason.
molt_git_pull() {
  local repo="$1" label="$2" out branch
  if ! branch="$(git -C "$repo" symbolic-ref -q --short HEAD 2>/dev/null)" \
      || ! git -C "$repo" config "branch.${branch}.merge" >/dev/null 2>&1; then
    molt_warn "$label pull skipped: $repo has no upstream branch"
    return 2
  fi
  if ! out="$(git -C "$repo" pull --ff-only 2>&1)"; then
    molt_error "$label pull failed in $repo:"
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    return 1
  fi
  [[ -z "$out" ]] || printf '%s\n' "$out"
}

_upgrade_check_clean() {
  local repo_path="$1"
  local label="$2"

  local staged unstaged
  staged="$(git -C "$repo_path" diff --cached --name-only 2>/dev/null)"
  unstaged="$(git -C "$repo_path" diff --name-only 2>/dev/null)"

  if [[ -n "$staged" ]] || [[ -n "$unstaged" ]]; then
    molt_error "$label repo has uncommitted changes. Commit or stash before upgrading."
    return 1
  fi

  _upgrade_warn_untracked "$repo_path" "$label"
  _upgrade_warn_unpushed "$repo_path" "$label"
  return 0
}

# Untracked files are not a reason to refuse an upgrade -- editors and tools drop
# scratch files in a repo all the time -- but a rendered config that was never
# added is a real way to lose work, so say so.
_upgrade_warn_untracked() {
  local repo_path="$1" label="$2" untracked count
  untracked="$(git -C "$repo_path" ls-files --others --exclude-standard 2>/dev/null)"
  [[ -n "$untracked" ]] || return 0
  count="$(printf '%s\n' "$untracked" | grep -c .)"
  molt_warn "$label repo has ${count} untracked file(s) — they will NOT reach your other machines:"
  printf '%s\n' "$untracked" | head -5 | sed 's/^/    /'
  [[ "$count" -gt 5 ]] && echo "    ... and $((count - 5)) more"
  return 0
}

# The one that actually bites. Commits sitting unpushed mean every other sleeve
# upgrades to a version that does not contain your fixes, and reports success.
# That is how gyges spent a morning running a backup agent pointing at a path
# rhadamanth had already moved.
_upgrade_warn_unpushed() {
  local repo_path="$1" label="$2" upstream ahead
  upstream="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || {
    molt_warn "$label repo has no upstream branch — nothing here will ever reach your other machines."
    return 0
  }
  ahead="$(git -C "$repo_path" rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)"
  [[ "$ahead" -gt 0 ]] || return 0
  molt_warn "$label repo is ${ahead} commit(s) ahead of ${upstream} and NOT pushed:"
  git -C "$repo_path" log --oneline "${upstream}..HEAD" 2>/dev/null | head -5 | sed 's/^/    /'
  [[ "$ahead" -gt 5 ]] && echo "    ... and $((ahead - 5)) more"
  molt_warn "  Push before upgrading your other sleeves, or they will pull an older tree and report success."
  return 0
}

# Checks, then pulls, the framework and the user config repo. Fails with
# status 1, pulling nothing, when either cannot be upgraded from as it stands;
# and with status 2 when a pull failed, after trying both, naming each in
# _UPGRADE_FAILED_PULLS for the verdict, since the run goes on against the
# trees on disk and fails at the end.
_upgrade_pull_repos() {
  local dry_run="${1:-false}"
  local old_version="$MOLT_VERSION"
  local pulled tree
  _UPGRADE_FAILED_PULLS=""

  # Only a dev tree is a framework repo to check and pull (ST0008 D5). An opt
  # or brew tree has no checkout of its own, so the board views a shared
  # checkout carries no longer stop the upgrade of a sleeve that runs one.
  tree="$(molt_tree)"
  case "$tree" in
    dev)
      molt_info "Checking framework repo: $MOLT_ROOT"
      if ! _upgrade_check_clean "$MOLT_ROOT" "Framework"; then
        return 1
      fi ;;
    opt|brew) ;;
    *) molt_warn "Framework: $MOLT_ROOT is no dev, opt or brew tree, so it is not upgraded; molt doctor says why." ;;
  esac

  # Check user config repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || {
    molt_error "Cannot upgrade without a user config repo."
    return 1
  }
  molt_info "Checking user config repo: $user_repo"
  if ! _upgrade_check_clean "$user_repo" "User config"; then
    return 1
  fi

  echo ""
  case "$tree" in
    dev)
      molt_info "Pulling framework repo..."
      if $dry_run; then
        echo "  molt: WOULD PULL"
      else
        pulled=0
        molt_git_pull "$MOLT_ROOT" "Framework" || pulled=$?
        case $pulled in
          0) molt_info "Framework repo updated." ;;
          2) ;;
          *) _UPGRADE_FAILED_PULLS="the framework repo ($MOLT_ROOT)" ;;
        esac
      fi ;;
    opt) _upgrade_opt_framework ;;
    brew)
      pulled=0
      _upgrade_brew_framework "$dry_run" || pulled=$?
      case $pulled in
        0) ;;
        3) _UPGRADE_FAILED_PULLS="brew update" ;;
        *) _UPGRADE_FAILED_PULLS="the brew upgrade of $MOLT_BREW_FORMULA" ;;
      esac ;;
  esac

  # Pull user config repo
  molt_info "Pulling user config repo..."
  if $dry_run; then
    echo "  config: WOULD PULL"
  else
    pulled=0
    molt_git_pull "$user_repo" "User config" || pulled=$?
    case $pulled in
      0) molt_info "User config repo updated." ;;
      2) ;;
      *) _UPGRADE_FAILED_PULLS="${_UPGRADE_FAILED_PULLS:+$_UPGRADE_FAILED_PULLS, }the user config repo ($user_repo)" ;;
    esac
  fi

  # Re-source constants to pick up any version change. Only a pull changes
  # this tree in place: brew upgrade installs a new keg, and may remove this
  # one, so a brew upgrade says what changed as it restarts on the new keg.
  if [[ "$tree" == dev ]]; then
    # shellcheck disable=SC1091
    source "${MOLT_LIB_DIR}/constants.sh"
    if [[ "$old_version" != "$MOLT_VERSION" ]]; then
      echo ""
      molt_info "Version changed: v${old_version} -> v${MOLT_VERSION}"
    fi
  fi
  [[ -z "$_UPGRADE_FAILED_PULLS" ]] || return 2
}

# Ends an upgrade: resleeves when asked, then gives the verdict. $3 lists the
# upgrade hooks that failed, and $4 the repos whose pull failed. A sleeve with
# either is not ready, whatever resleeve then finds, so resleeve is told not to
# say it is: on kovacs doom sync failed inside the editors hook, and molt
# upgrade still said "Sleeve ready" (issue 0013).
_upgrade_finish() {
  local dry_run="$1" do_resleeve="$2" failed_hooks="$3" failed_pulls="${4:-}" status=0 claim_ready=true
  if [[ "$do_resleeve" == "yes" ]]; then
    echo ""
    if $dry_run; then
      molt_info "Dry run — showing what resleeve would do:"
      echo ""
      molt_resleeve true true || status=1
    else
      molt_info "Running resleeve..."
      echo ""
      [[ -z "$failed_hooks$failed_pulls" ]] || claim_ready=false
      molt_resleeve false "$claim_ready" || status=1
    fi
  fi
  if [[ -n "$failed_pulls" ]]; then
    echo ""
    molt_error "Upgrade incomplete: the pull failed for $failed_pulls. The liberators ran against the trees on disk; the sleeve is not ready."
    status=1
  fi
  if [[ -n "$failed_hooks" ]]; then
    echo ""
    molt_error "Upgrade incomplete: the upgrade hook failed for $failed_hooks. The sleeve is not ready; review the errors above."
    return 1
  fi
  return $status
}

# The opt tree is never pulled: a publish is a verb hv types. Says so, and
# names the dev tree's commit when it is ahead of this install's.
_upgrade_opt_framework() {
  local dev installed head
  molt_info "Framework: the opt tree at $(molt_tilde "$MOLT_ROOT") is not pulled; upgrade it from the dev tree with molt install --force."
  dev="$(_molt_use_root dev)" || return 0
  installed="$(molt_tree_source_commit "$MOLT_ROOT")" || return 0
  head="$(git -C "$dev" rev-parse HEAD 2>/dev/null)" || return 0
  if [[ "$head" != "$installed" ]] \
      && git -C "$dev" merge-base --is-ancestor "$installed" "$head" 2>/dev/null; then
    molt_info "  The dev tree at $(molt_tilde "$dev") is at ${head:0:12}, ahead of this install's ${installed:0:12}."
  fi
}

# Upgrades the formula in the brew tree, with HOMEBREW_NO_AUTO_UPDATE=1 on
# every brew call (devbin docs/dev-opt-brew.md T6): brew update, a step of its
# own, then brew outdated, then brew upgrade when that names the formula. brew
# outdated exits 0, saying nothing, for a current formula, and 1, naming it,
# for an outdated one; anything else is brew failing to say. A dry run changes
# nothing, Homebrew's taps included, so it skips the update and says so.
# Fails with 3 when brew update fails, and 1 when brew cannot say or the
# upgrade fails, so the verdict counts each by name (issue 0015).
_upgrade_brew_framework() {
  local dry_run="$1" out err status=0
  if $dry_run; then
    molt_info "Dry run: skipping brew update, so brew outdated answers from what brew last fetched."
  else
    molt_info "Updating Homebrew..."
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew update; then
      molt_error "brew update failed (above), so whether $MOLT_BREW_FORMULA is outdated was not asked."
      return 3
    fi
  fi
  molt_info "Asking brew whether $MOLT_BREW_FORMULA is outdated..."
  # Its stderr is kept apart, so nothing brew warns of reads as an answer.
  if ! err="$(mktemp "${TMPDIR:-/tmp}/molt-brew-outdated.XXXXXX")"; then
    molt_error "Cannot ask brew whether $MOLT_BREW_FORMULA is outdated: mktemp failed."
    return 1
  fi
  out="$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --quiet "$MOLT_BREW_FORMULA" 2>"$err")" || status=$?
  if [[ "$status" -eq 0 && -z "$out" ]]; then
    rm -f "$err"
    molt_info "Framework: $MOLT_BREW_FORMULA is current."
    return 0
  fi
  if [[ "$status" -ne 1 ]] || ! printf '%s\n' "$out" | grep -qxE "(${MOLT_BREW_FORMULA%/*}/)?molt"; then
    molt_error "brew outdated could not say whether $MOLT_BREW_FORMULA is current (exit $status):"
    { printf '%s\n' "$out"; cat "$err"; } | sed 's/^/    /' >&2
    rm -f "$err"
    return 1
  fi
  rm -f "$err"
  if $dry_run; then
    echo "  molt: WOULD BREW UPGRADE $MOLT_BREW_FORMULA"
    return 0
  fi
  if ! HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "$MOLT_BREW_FORMULA"; then
    molt_error "brew upgrade $MOLT_BREW_FORMULA failed (above)."
    return 1
  fi
  molt_info "Framework: $MOLT_BREW_FORMULA upgraded."
}

# The root the framework is upgraded in and restarted from: MOLT_ROOT, except
# in brew, where brew upgrade installs a new keg beside the running one, so it
# is the formula's opt link, which follows the upgrade.
_upgrade_framework_root() {
  if [[ "$(molt_tree)" == brew ]]; then
    _molt_use_root brew
  else
    echo "$MOLT_ROOT"
  fi
}

# What the framework is at, as the restart compares it before and after the
# pull, or nothing and a failure when it cannot be read: the tree's commit in
# dev and opt, and in brew the keg the formula's opt link resolves to. A
# revision bump (0.3.0 to 0.3.0_1) installs a new keg of the same commit, and
# brew cleanup can remove the running one, so in brew the commit cannot say.
# It prints only the mark, since its callers capture it; they say what an
# unread one means.
_upgrade_framework_mark() {
  local root
  root="$(_upgrade_framework_root)" || return 1
  case "$(molt_tree "$root")" in
    brew) _molt_realpath "$root" ;;
    dev|opt) molt_tree_source_commit "$root" ;;
    *) return 1 ;;
  esac
}

# The mark $1 as the restart names it: a keg by its version, the directory it
# sits in, and a commit short.
_upgrade_mark_label() {
  case "$1" in
    /*) basename "$(dirname "$1")" ;;
    *) echo "${1:0:12}" ;;
  esac
}

# This process sourced lib/ before the pull, but liberator_load reads each
# liberator from disk after it, so a pull that moved the framework would run
# the old library against the new liberators: with ST0006 WP02, the first
# upgrade on every sleeve failed in claude and agents (issue 0023). Only a new
# process knows which library files the pulled bin/molt sources, so the rest
# of the upgrade runs in one, without pulling again, told which pulls failed
# ($3) so that its verdict still counts them.
_upgrade_restart_if_pulled() {
  local mark_before="$1" do_resleeve="$2" failed_pulls="${3:-}" mark_after root
  [[ -n "$mark_before" ]] || return 0
  mark_after="$(_upgrade_framework_mark)" || {
    molt_warn "Cannot read the framework commit in $MOLT_ROOT after the pull; if it changed lib/, run molt upgrade again."
    return 0
  }
  [[ "$mark_after" != "$mark_before" ]] || return 0
  root="$(_upgrade_framework_root)" || {
    molt_warn "Cannot find the upgraded framework to restart on: $root. Run molt upgrade again."
    return 0
  }
  echo ""
  molt_info "Framework updated ($(_upgrade_mark_label "$mark_before") -> $(_upgrade_mark_label "$mark_after")); restarting on the new code."
  if [[ "$do_resleeve" == "yes" ]]; then
    MOLT_UPGRADE_FAILED_PULLS="$failed_pulls" exec "$root/bin/molt" upgrade --no-pull --resleeve
  fi
  MOLT_UPGRADE_FAILED_PULLS="$failed_pulls" exec "$root/bin/molt" upgrade --no-pull --no-resleeve
}

cmd_upgrade() {
  local dry_run=false
  local do_resleeve=""  # "" = use default, "yes" = forced, "no" = suppressed
  local target_liberators=""
  local self_only=false
  local pull=true

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self)        self_only=true; shift ;;
      --no-pull)     pull=false; shift ;;
      --dry-run)     dry_run=true; shift ;;
      --resleeve)    do_resleeve="yes"; shift ;;
      --no-resleeve) do_resleeve="no"; shift ;;
      -*)
        molt_error "Unknown option: $1"
        return 1
        ;;
      *)
        target_liberators="$1"; shift ;;
    esac
  done

  # Default resleeve behavior: yes for full upgrade, no for targeted
  if [[ -z "$do_resleeve" ]]; then
    if [[ -n "$target_liberators" ]]; then
      do_resleeve="no"
    else
      do_resleeve="yes"
    fi
  fi

  if $self_only && ! $pull; then
    molt_error "--self pulls and does nothing else, so it cannot take --no-pull."
    return 1
  fi

  echo "${MOLT_NAME} v${MOLT_VERSION} — Upgrade"
  echo ""

  if $self_only; then
    # Self-update only: pull repos, report, exit
    _upgrade_pull_repos "$dry_run" || return 1
    return 0
  fi

  if [[ -n "$target_liberators" ]]; then
    # --- Targeted upgrade: run _upgrade() on specified liberators only ---
    local failed=0 failed_hooks=""
    # Split comma-separated list
    IFS=',' read -ra targets <<< "$target_liberators"
    for lib in "${targets[@]}"; do
      # Trim whitespace
      lib="${lib## }"
      lib="${lib%% }"
      [[ -z "$lib" ]] && continue

      if ! liberator_load "$lib" 2>/dev/null; then
        molt_error "Unknown liberator: $lib"
        failed=1
        continue
      fi

      if liberator_has_upgrade "$lib"; then
        if $dry_run; then
          echo "  $lib: WOULD UPGRADE"
        else
          if ! liberator_upgrade "$lib"; then
            molt_error "Upgrade failed: $lib"
            failed_hooks="${failed_hooks:+$failed_hooks, }$lib"
          fi
        fi
      else
        molt_warn "$lib has no upgrade hook — skipping"
      fi
    done

    _upgrade_finish "$dry_run" "$do_resleeve" "$failed_hooks" || failed=1
    return $failed
  fi

  # --- Full upgrade: pull repos, run all _upgrade() hooks, then resleeve ---

  # A pull that failed does not stop the run: the hooks and resleeve settle
  # what they can on the trees on disk, and the verdict counts it (issue
  # 0015). An upgrade restarted after a pull is told by the one that pulled.
  local failed_pulls=""
  if $pull; then
    local mark_before pulled=0
    mark_before="$(_upgrade_framework_mark)" || {
      mark_before=""
      molt_warn "Cannot read the framework commit in $MOLT_ROOT; a pull that changes lib/ needs a second molt upgrade."
    }
    _upgrade_pull_repos "$dry_run" || pulled=$?
    [[ $pulled -ne 1 ]] || return 1
    failed_pulls="${_UPGRADE_FAILED_PULLS:-}"
    $dry_run || _upgrade_restart_if_pulled "$mark_before" "$do_resleeve" "$failed_pulls"
  else
    failed_pulls="${MOLT_UPGRADE_FAILED_PULLS:-}"
  fi
  # Read once: it is the restart's, not anything this run starts.
  unset MOLT_UPGRADE_FAILED_PULLS

  # Run _upgrade() hooks on all enabled liberators that define one
  echo ""
  molt_info "Running liberator upgrade hooks..."
  local liberators
  if ! liberators="$(molt_run_liberators)"; then
    molt_error "Cannot upgrade: $liberators"
    return 1
  fi

  local upgrade_count=0 failed_hooks=""
  # On fd 3, so a hook keeps the caller's stdin (issue 0075; see molt_resleeve).
  while IFS= read -r lib <&3; do
    [[ -z "$lib" ]] && continue
    if ! liberator_load "$lib"; then
      continue
    fi
    if liberator_has_upgrade "$lib"; then
      if $dry_run; then
        echo "  $lib: WOULD UPGRADE"
      elif ! liberator_upgrade "$lib"; then
        molt_error "Upgrade hook failed: $lib — continuing"
        failed_hooks="${failed_hooks:+$failed_hooks, }$lib"
      fi
      upgrade_count=$((upgrade_count + 1))
    fi
  done 3<<< "$liberators"

  if [[ "$upgrade_count" -eq 0 ]]; then
    molt_info "No liberators have upgrade hooks."
  fi

  # Resleeve (unless suppressed), then the verdict
  _upgrade_finish "$dry_run" "$do_resleeve" "$failed_hooks" "$failed_pulls"
}

# --- Maintain ---

cmd_maintain() {
  local dry_run=false
  local target_liberators=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)  dry_run=true; shift ;;
      -*)
        molt_error "Unknown option: $1"
        return 1
        ;;
      *)
        target_liberators="$1"; shift ;;
    esac
  done

  echo "${MOLT_NAME} v${MOLT_VERSION} — Maintain"
  echo ""

  # Get enabled liberators
  local liberators
  if ! liberators="$(molt_run_liberators)"; then
    molt_error "Cannot maintain: $liberators"
    return 1
  fi

  if [[ -n "$target_liberators" ]]; then
    # --- Targeted maintain: run _maintain() on specified liberators only ---
    local failed=0
    IFS=',' read -ra targets <<< "$target_liberators"
    for lib in "${targets[@]}"; do
      lib="${lib## }"
      lib="${lib%% }"
      [[ -z "$lib" ]] && continue

      if ! liberator_load "$lib" 2>/dev/null; then
        molt_error "Unknown liberator: $lib"
        failed=1
        continue
      fi

      if liberator_has_maintain "$lib"; then
        if $dry_run; then
          echo "  $lib: WOULD MAINTAIN"
        else
          if ! liberator_maintain "$lib"; then
            molt_error "Maintain failed: $lib"
            failed=1
          fi
        fi
      else
        molt_warn "$lib has no maintain hook — skipping"
      fi
    done
    return $failed
  fi

  # --- Full maintain: run _maintain() on all enabled liberators ---
  # A failed hook is reported and the rest still run, but maintain exits
  # non-zero: it used to warn, say maintenance was complete and exit 0, which
  # is how kovacs's failed doom sync passed (issue 0013).
  local maintain_count=0 failed_hooks=""
  # On fd 3, so a hook keeps the caller's stdin: brew's hook read the rest of
  # the list once, and editors' doom upgrade never ran (issue 0075; see
  # molt_resleeve).
  while IFS= read -r lib <&3; do
    [[ -z "$lib" ]] && continue
    if ! liberator_load "$lib"; then
      continue
    fi
    if liberator_has_maintain "$lib"; then
      if $dry_run; then
        echo "  $lib: WOULD MAINTAIN"
      elif ! liberator_maintain "$lib"; then
        molt_error "Maintain hook failed: $lib — continuing"
        failed_hooks="${failed_hooks:+$failed_hooks, }$lib"
      fi
      maintain_count=$((maintain_count + 1))
    fi
  done 3<<< "$liberators"

  if [[ "$maintain_count" -eq 0 ]]; then
    molt_info "No liberators have maintain hooks."
  elif ! $dry_run; then
    echo ""
    if [[ -n "$failed_hooks" ]]; then
      molt_error "Maintenance incomplete: the maintain hook failed for $failed_hooks. Review the errors above."
      return 1
    fi
    molt_info "System maintenance complete."
  fi
}

# --- Multi-Repo Git ---

# Prints a "label:path" line per managed repo: the framework, the config repo
# and each run liberator's _repo. Fails, printing only why, when the manifest
# names no liberator to run (issue 0054), so no list hides the refusal.
molt_all_repos() {
  local liberators
  liberators="$(molt_run_liberators)" || { echo "$liberators"; return 1; }

  # Framework repo (always included)
  echo "molt:${MOLT_ROOT}"

  # User config repo (if found)
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    echo "config:${user_repo}"
  fi

  # Liberator repos (enabled liberators only). On fd 3, so a liberator's code
  # keeps the caller's stdin and cannot read the rest of the list (issue 0075).
  while IFS= read -r lib <&3; do
    [[ -z "$lib" ]] && continue
    # Load liberator quietly: anything it printed would mix with the repo list
    liberator_load "$lib" >/dev/null 2>&1 || continue
    local repo_path
    local repo_fn="${lib}_repo"
    if declare -f "$repo_fn" &>/dev/null; then
      if repo_path="$("$repo_fn" 2>/dev/null)" && [[ -n "$repo_path" ]]; then
        echo "${lib}:${repo_path}"
      fi
    fi
  done 3<<< "$liberators"
}

_git_detect_remote() {
  local repo="$1"

  # If the current branch already tracks a remote, use it
  local branch
  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" || return 1
  local tracking
  tracking="$(git -C "$repo" config "branch.${branch}.remote" 2>/dev/null)"
  if [[ -n "$tracking" ]]; then
    echo "$tracking"
    return 0
  fi

  # No tracking — if there's exactly one remote, use it
  local remotes
  remotes="$(git -C "$repo" remote 2>/dev/null)" || return 1
  local count
  count="$(echo "$remotes" | grep -c . 2>/dev/null || echo 0)"
  if [[ "$count" -eq 1 ]]; then
    echo "$remotes"
    return 0
  fi

  return 1
}

cmd_git() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: molt git <git-command> [args...]"
    echo ""
    echo "Run a git command across all managed repos."
    echo "Examples:"
    echo "  molt git status"
    echo "  molt git pull"
    echo "  molt git log --oneline -3"
    return 0
  fi

  local git_cmd="$1"
  local errors=0 repos
  if ! repos="$(molt_all_repos)"; then
    molt_error "Cannot run git: $repos"
    return 1
  fi

  while IFS=: read -r label repo_path; do
    [[ -z "$label" ]] && continue

    # For liberator repos (not molt or config), check whitelist
    if [[ "$label" != "molt" ]] && [[ "$label" != "config" ]]; then
      # Ensure liberator is loaded in this shell (molt_all_repos ran in a subshell)
      if ! liberator_load "$label" 2>/dev/null; then
        echo "--- ${label} (${repo_path}) ---"
        molt_warn "could not load liberator ${label} — skipping"
        echo ""
        continue
      fi
      local whitelist_fn="${label}_repo_git_commands"
      if declare -f "$whitelist_fn" &>/dev/null; then
        local allowed
        allowed="$($whitelist_fn)"
        if [[ " $allowed " != *" $git_cmd "* ]]; then
          echo "--- ${label} (${repo_path}) ---"
          molt_warn "git ${git_cmd} not in ${label}'s allowed commands (${allowed})"
          echo ""
          continue
        fi
      fi
    fi

    echo "--- ${label} (${repo_path}) ---"
    # For remote-aware commands, auto-detect the remote when needed
    if [[ " pull fetch push " == *" $git_cmd "* ]]; then
      local remote
      if remote="$(_git_detect_remote "$repo_path")"; then
        if ! git -C "$repo_path" "$@" "$remote"; then
          errors=$((errors + 1))
        fi
      else
        if ! git -C "$repo_path" "$@"; then
          errors=$((errors + 1))
        fi
      fi
    else
      if ! git -C "$repo_path" "$@"; then
        errors=$((errors + 1))
      fi
    fi
    echo ""
  done <<< "$repos"

  if [[ $errors -gt 0 ]]; then
    molt_warn "${errors} repo(s) had errors"
    return 1
  fi
}

# --- Stack Discovery ---

molt_find_user_repo() {
  local path
  for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
    if [[ -d "$path/config" ]]; then
      echo "$path"
      return 0
    fi
  done
  molt_error "Could not find user config repo (Molt-$(whoami))."
  if [[ -z "$MOLT_CFG_DIR" && -z "$MOLT_PRJ_DIR" ]]; then
    molt_error "Set MOLT_PRJ_DIR to the directory containing your repos, eg:"
    molt_error "  export MOLT_PRJ_DIR=\$HOME/Devel/prj"
    molt_error "The user repo is then looked for in its sibling cfg/ (override with MOLT_CFG_DIR)."
  else
    molt_error "Searched:"
    for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
      molt_error "  $path"
    done
  fi
  return 1
}
