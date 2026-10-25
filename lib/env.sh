#!/usr/bin/env bash
# env.sh — Molt's one env writer (ST0008 WP05)
#
# Molt publishes every variable a sleeve's shells and GUI apps need through the
# files here, and through nothing else: env.sh, which ~/.zshenv sources, and the
# GUI environment, a LaunchAgent on macOS and an environment.d file on Linux.
# Each variable is a contributor's pair, "NAME<TAB>scope<TAB>value", where the
# scope is "all" for env.sh and the GUI file, or "gui" for the GUI file alone:
# PATH is the login shell's own, so env.sh, which every zsh sources before its
# PATH is built, never sets it. The env liberator gathers the pairs and calls
# the writer; the files are rebuilt whole from them every time, so a value a
# contributor stops giving is gone from both at once, and env.sh and the GUI
# file cannot drift apart. Nothing here sets anything through launchctl or
# systemctl, nor runs sudo: the GUI file takes effect for apps launched after
# the next login, and the check only reads what launchd holds, with launchctl
# getenv.

# The env file ~/.zshenv sources.
molt_env_file() {
  echo "$HOME/.config/molt/env.sh"
}

# The GUI environment file on this platform, or nothing where there is none.
molt_env_gui_file() {
  case "$(molt_platform)" in
    macos) echo "$HOME/Library/LaunchAgents/com.molt.env.plist" ;;
    linux) echo "$HOME/.config/environment.d/molt.conf" ;;
  esac
}

# The files the claude liberator published CLAUDE_CONFIG_DIR through before
# this writer took them over, one "template<TAB>target" line each, on this
# platform. The templates are kept under templates/env/retired/ only so that a
# file that is still byte for byte what molt rendered can be told from one
# somebody changed; they go once every sleeve has moved.
_molt_env_retired() {
  local t="${MOLT_ROOT}/templates/env/retired"
  case "$(molt_platform)" in
    macos) printf '%s\t%s\n' "$t/com.molt.claude-config-dir.plist.tmpl" "$HOME/Library/LaunchAgents/com.molt.claude-config-dir.plist" ;;
    linux) printf '%s\t%s\n' "$t/claude.conf.tmpl" "$HOME/.config/environment.d/claude.conf" ;;
  esac
}

# Why the value $2, named $1, cannot be written as it stands into the files
# that publish it, or nothing when it can. env.sh is read back, so a value is
# refused rather than rewritten: a copy tidied here would be compared with
# files that hold the untidied one. Refused: a character env.sh, a plist or
# environment.d reads as syntax, and trailing whitespace, which environment.d
# strips. environment.d expands $ and backslash escapes, never % specifiers,
# which belong to unit files. With $3 "path", anything molt_path_fault refuses
# too, ahead of the rest; with "pathlist", an empty list, or an entry that is
# not an absolute path.
molt_env_value_fault() {
  local name="$1" value="$2" kind="${3:-}" fault entry
  if [[ "$kind" == path ]]; then
    fault="$(molt_path_fault "$name" "$value")"
    if [[ -n "$fault" ]]; then
      echo "$fault"
      return
    fi
  fi
  case "$value" in
    *[\"\'\$\`\\\<\>\&]* | *$'\n'*)
      echo "$name holds a character env.sh, a plist or environment.d would read as syntax: $value"
      return ;;
    *[[:space:]])
      echo "$name ends in whitespace, which environment.d would strip: '$value'"
      return ;;
  esac
  if [[ "$kind" == pathlist ]]; then
    if [[ -z "$value" ]]; then
      echo "$name is empty"
      return
    fi
    local IFS=:
    for entry in $value; do
      if [[ "$entry" != /* ]]; then
        echo "$name has an entry that is not an absolute path: '$entry' in $value"
        return
      fi
    done
  fi
}

# The value env.sh last published for $1, when there is one: the value of its
# export line, found only in the form _molt_env_shell_text writes, which is
# also the form the claude liberator's env.sh had.
molt_env_published() {
  local env_file
  env_file="$(molt_env_file)"
  [[ -f "$env_file" ]] || return 0
  sed -n "s/^export $1=\"\(.*\)\"\$/\1/p" "$env_file"
}

# --- Contributors ---
#
# Each contributor prints a "NAME<TAB>scope<TAB>value" line for each pair it
# gives, and a "!<TAB>why" line for each it refuses. A refusal stands alone: the
# other pairs are published all the same, and the run fails naming it, so one
# bad PATH never takes CLAUDE_CONFIG_DIR out of env.sh (vc, 24 Oct).

# Prints why for each refused pair in the contributor lines on stdin.
molt_env_refusals() {
  sed -n 's/^!	//p'
}

# The pairs in the contributor lines on stdin, refusals left out.
molt_env_given() {
  grep -v '^!	' | grep . || true
}

# Each <TOOL>_INSTALL_PREFIX this sleeve's vars.sh exports, MOLT_ ones aside,
# as an "all" pair, in name order. The names are the file's export lines and
# the values molt_instance_var's, which starts each name unset, so a prefix
# this shell inherited, as from an env.sh already published, is not declared.
# A brew-only sleeve declares none and gets none. A prefix that cannot be read
# or published is refused alone, and every prefix when vars.sh cannot be found.
molt_env_prefix_pairs() {
  local vars_file name value fault
  if ! vars_file="$(molt_instance_file vars.sh)"; then
    printf '!\t%s\n' "no prefix was published: $vars_file"
    return 0
  fi
  [[ -f "$vars_file" ]] || return 0
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if ! value="$(molt_instance_var "$name")"; then
      printf '!\t%s\n' "$name could not be read: $value"
      continue
    fi
    [[ -n "$value" ]] || continue
    fault="$(molt_env_value_fault "$name" "$value" path)"
    if [[ -n "$fault" ]]; then
      printf '!\t%s\n' "$fault"
      continue
    fi
    printf '%s\tall\t%s\n' "$name" "$value"
  done <<< "$(sed -n 's/^[[:space:]]*export[[:space:]]\{1,\}\([A-Z][A-Z0-9_]*_INSTALL_PREFIX\)=.*/\1/p' "$vars_file" | grep -v '^MOLT_' | LC_ALL=C sort -u)"
}

# The base PATH a Linux desktop session starts from: the value of the last
# PATH= line in MOLT_ETC_ENVIRONMENT, less one pair of surrounding quotes, or
# nothing when the file is missing or has no such line. Nothing on macOS, where
# /etc/zprofile's path_helper builds the base PATH inside the login shell.
molt_env_base_path() {
  local line
  [[ "$(molt_platform)" == linux && -f "$MOLT_ETC_ENVIRONMENT" ]] || return 0
  line="$(sed -n 's/^[[:space:]]*PATH=//p' "$MOLT_ETC_ENVIRONMENT" | tail -n 1)"
  case "$line" in
    \"*\") line="${line#\"}"; line="${line%\"}" ;;
    \'*\') line="${line#\'}"; line="${line%\'}" ;;
  esac
  printf '%s' "$line"
}

# The PATH a login shell builds, read from one started with nothing but HOME,
# USER, LOGNAME, SHELL and TERM, so the PATH molt itself runs with plays no
# part, and with PATH set to molt_env_base_path when there is one, as PAM sets
# it for a Linux session (issue 0056). With none, the shell starts from its
# own default PATH, which for zsh is not the system's. The shell is
# MOLT_LOGIN_SHELL when set, or zsh. Its startup files may print, so the PATH
# is the last line it prints after a marker. Fails, printing why, when the
# shell is missing, fails or prints no PATH: a PATH molt has not read is never
# published.
molt_env_login_path() {
  local sh="${MOLT_LOGIN_SHELL:-}" base out line
  local -a seed=()
  if [[ -z "$sh" ]] && ! sh="$(command -v zsh)"; then
    echo "there is no zsh to read a login shell's PATH from"
    return 1
  fi
  base="$(molt_env_base_path)"
  [[ -z "$base" ]] || seed=(PATH="$base")
  # shellcheck disable=SC2016 # $PATH is the login shell's to expand
  if ! out="$(env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${LOGNAME:-${USER:-}}" SHELL="$sh" TERM=dumb \
      ${seed[@]+"${seed[@]}"} "$sh" -lic 'printf "molt-path:%s\n" "$PATH"' </dev/null 2>/dev/null)"; then
    echo "a login shell ($sh -lic) failed, so its PATH was not read"
    return 1
  fi
  line="$(printf '%s\n' "$out" | sed -n 's/^molt-path://p' | tail -n 1)"
  if [[ -z "$line" ]]; then
    echo "a login shell ($sh -lic) printed no PATH"
    return 1
  fi
  printf '%s\n' "$line"
}

# PATH for GUI apps, as a "gui" pair: the login shell's, which must put
# MOLT_LOCAL_BIN first, ahead of every Homebrew bin, so an app finds each
# tool's use dev|opt link as a shell does (hv, 24 Oct). Refused when it cannot
# be read, or does not start there. Never in env.sh: a shell builds its own.
molt_env_path_pair() {
  local path fault
  if ! path="$(molt_env_login_path)"; then
    printf '!\t%s\n' "PATH was not published: $path"
    return 0
  fi
  fault="$(molt_env_value_fault PATH "$path" pathlist)"
  if [[ -n "$fault" ]]; then
    printf '!\t%s\n' "$fault"
    return 0
  fi
  if [[ "${path%%:*}" != "$MOLT_LOCAL_BIN" ]]; then
    printf '!\t%s\n' "a login shell's PATH starts with ${path%%:*}, not $(molt_tilde "$MOLT_LOCAL_BIN"), so it was not published: put $(molt_tilde "$MOLT_LOCAL_BIN") first on PATH in zshrc"
    return 0
  fi
  printf 'PATH\tgui\t%s\n' "$path"
}

# --- The files ---

# env.sh for the pairs on stdin: an export line for each "all" pair.
_molt_env_shell_text() {
  local name scope value
  cat <<'EOF'
# env.sh -- GENERATED by molt (lib/env.sh); do not edit.
# Sourced by ~/.zshenv. Every variable molt publishes to shells is here, and
# molt reads each back from its export line, in exactly this form.
EOF
  while IFS=$'\t' read -r name scope value; do
    [[ "$scope" == all ]] || continue
    printf 'export %s="%s"\n' "$name" "$value"
  done
}

# The word $1 single-quoted for sh, so it reaches the command byte for byte.
_molt_env_sh_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# The text $1 escaped for a plist <string>.
_molt_env_xml_text() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# The LaunchAgent for the pairs on stdin: at each login, sh runs one launchctl
# setenv per pair, since setenv takes one name and one value and launchd keeps
# only the first pair of a longer list (issue 0059). Each word is quoted, and
# one failed setenv does not stop the rest. With no pair it runs true.
# launchctl is named bare: a launchd job's PATH finds /bin/launchctl, and a
# test's stub comes first on its own.
_molt_env_plist_text() {
  local name scope value pairs script=""
  pairs="$(cat)"
  while IFS=$'\t' read -r name scope value; do
    [[ -n "$name" ]] || continue
    script="${script:+$script; }launchctl setenv $(_molt_env_sh_quote "$name") $(_molt_env_sh_quote "$value")"
  done <<< "$pairs"
  cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- GENERATED by molt (lib/env.sh); do not edit. At login it sets each
     variable for every app launchd starts, so an app started from the Dock,
     an editor or the desktop app sees what a shell does (Molt ST0008). -->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.molt.env</string>
  <key>ProgramArguments</key>
  <array>
EOF
  if [[ -z "$script" ]]; then
    printf '    <string>/usr/bin/true</string>\n'
  else
    printf '    <string>/bin/sh</string>\n    <string>-c</string>\n    <string>%s</string>\n' "$(_molt_env_xml_text "$script")"
  fi
  cat <<'EOF'
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF
}

# The environment.d file for the pairs on stdin.
_molt_env_conf_text() {
  local name scope value
  cat <<'EOF'
# molt.conf -- GENERATED by molt (lib/env.sh); do not edit.
# systemd reads environment.d at login, so every GUI and terminal child of the
# session sees what a shell does (Molt ST0008).
EOF
  while IFS=$'\t' read -r name scope value; do
    [[ -n "$name" ]] || continue
    printf '%s=%s\n' "$name" "$value"
  done
}

# The files the writer publishes on this platform, one "target<TAB>function"
# line each, the function building the file from the pairs on its stdin.
_molt_env_targets() {
  printf '%s\t%s\n' "$(molt_env_file)" _molt_env_shell_text
  case "$(molt_platform)" in
    macos) printf '%s\t%s\n' "$(molt_env_gui_file)" _molt_env_plist_text ;;
    linux) printf '%s\t%s\n' "$(molt_env_gui_file)" _molt_env_conf_text ;;
  esac
}

# The state of the target $1, built by the function $2 from the pairs $3:
# missing, differs, or current.
_molt_env_state() {
  if [[ ! -e "$1" ]]; then
    echo missing
  elif [[ "$("$2" <<< "$3"; echo x)" != "$(cat "$1"; echo x)" ]]; then
    echo differs
  else
    echo current
  fi
}

# The state of the retired file $2, from the template $1: absent; retired,
# when it is byte for byte what molt rendered from $1 with the value env.sh
# published or this sleeve's declared config dir; or changed.
_molt_env_retired_state() {
  local template="$1" target="$2" value
  [[ -e "$target" || -L "$target" ]] || { echo absent; return; }
  for value in "$(molt_env_published CLAUDE_CONFIG_DIR)" "$(molt_instance_var MOLT_CLAUDE_CONFIG_DIR 2>/dev/null)"; do
    [[ -n "$value" && -f "$target" && ! -L "$target" ]] || continue
    # shellcheck disable=SC2016 # envsubst takes the name, unexpanded
    if [[ "$(MOLT_CLAUDE_CONFIG_DIR="$value" envsubst '${MOLT_CLAUDE_CONFIG_DIR}' < "$template"; echo x)" == "$(cat "$target"; echo x)" ]]; then
      echo retired
      return
    fi
  done
  echo changed
}

# Reports, through $1 after the prefix $2, everything that keeps the files from
# publishing the pairs $3: a retired file still there, and each file missing
# or not what molt would write. Returns non-zero when it reported any.
molt_env_report_faults() {
  local log="$1" prefix="$2" pairs="$3" template target fn ok=0
  while IFS=$'\t' read -r template target; do
    [[ -n "$template" ]] || continue
    case "$(_molt_env_retired_state "$template" "$target")" in
      retired)
        "$log" "${prefix}$(molt_tilde "$target") is retired, and molt resleeve removes it" ; ok=1 ;;
      changed)
        "$log" "${prefix}$(molt_tilde "$target") is retired but is not what molt rendered, so molt leaves it: move it aside by hand" ; ok=1 ;;
    esac
  done <<< "$(_molt_env_retired)"
  while IFS=$'\t' read -r target fn; do
    [[ -n "$target" ]] || continue
    case "$(_molt_env_state "$target" "$fn" "$pairs")" in
      missing) "$log" "${prefix}$(molt_tilde "$target") is missing" ; ok=1 ;;
      differs) "$log" "${prefix}$(molt_tilde "$target") is not what molt would publish: $(_molt_env_names "$pairs")" ; ok=1 ;;
    esac
  done <<< "$(_molt_env_targets)"
  return $ok
}

# Reports, through $1 after the prefix $2, each pair in $3 that launchd does
# not hold as published, on macOS, where GUI apps get the plist's pairs only
# once it has run: a file molt would write says nothing of what launchd holds
# (issue 0059). Reads with launchctl getenv, and never sets anything. Returns
# non-zero when it reported any.
molt_env_report_launchd() {
  local log="$1" prefix="$2" pairs="$3" name scope value held uid plist ok=0
  [[ "$(molt_platform)" == macos ]] || return 0
  uid="$(id -u)"
  plist="$(molt_tilde "$(molt_env_gui_file)")"
  while IFS=$'\t' read -r name scope value; do
    [[ -n "$name" ]] || continue
    if ! held="$(launchctl getenv "$name" 2>&1)"; then
      "$log" "${prefix}launchctl getenv $name failed, so whether GUI apps get it is unknown: $held"
      ok=1
      continue
    fi
    [[ "$held" != "$value" ]] || continue
    if [[ -z "$held" ]]; then
      "$log" "${prefix}launchd does not hold $name, so GUI apps do not get it"
    else
      "$log" "${prefix}launchd holds another $name, so GUI apps get $held"
    fi
    ok=1
  done <<< "$pairs"
  if [[ $ok -ne 0 ]]; then
    "$log" "${prefix}$plist takes effect at the next login, or now with: launchctl bootout gui/$uid/com.molt.env; launchctl bootstrap gui/$uid $plist"
  fi
  return $ok
}

# The names in the pairs $1, joined by ", ".
_molt_env_names() {
  cut -f1 <<< "$1" | grep . | paste -sd, - | sed 's/,/, /g'
}

# Removes each retired file that is still what molt rendered, and refuses,
# naming it, one that is not, before anything is written.
_molt_env_retire() {
  local template target
  while IFS=$'\t' read -r template target; do
    [[ -n "$template" ]] || continue
    case "$(_molt_env_retired_state "$template" "$target")" in
      retired)
        if ! rm -f "$target" "${target}.molt-rendered"; then
          molt_error "env: could not remove the retired $(molt_tilde "$target")"
          return 1
        fi
        molt_info "env: removed the retired $(molt_tilde "$target")" ;;
      changed)
        molt_error "env: $(molt_tilde "$target") is retired but is not what molt rendered, so nothing was published: move it aside by hand, then re-run"
        return 1 ;;
    esac
  done <<< "$(_molt_env_retired)"
}

# Publishes the pairs $1: retires the old files, then writes each file that is
# not current, through molt_render_place, which backs up a hand edit. Fails,
# saying why, at the first step that does.
molt_env_publish() {
  local pairs="$1" target fn
  _molt_env_retire || return 1
  while IFS=$'\t' read -r target fn; do
    [[ -n "$target" ]] || continue
    [[ "$(_molt_env_state "$target" "$fn" "$pairs")" != current ]] || continue
    if ! mkdir -p "$(dirname "$target")" || ! "$fn" <<< "$pairs" > "${target}.molt-tmp"; then
      rm -f "${target}.molt-tmp"
      molt_error "env: could not write $(molt_tilde "$target")"
      return 1
    fi
    molt_render_place "${MOLT_ROOT}/lib/env.sh" "$target" || return 1
    if ! chmod 644 "$target"; then
      molt_error "env: could not make $(molt_tilde "$target") mode 644"
      return 1
    fi
  done <<< "$(_molt_env_targets)"
}
