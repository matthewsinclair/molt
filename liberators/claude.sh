#!/usr/bin/env bash
# claude.sh — Liberator: Claude Code configuration
# Frees you from re-teaching every sleeve the same keybindings and status line.

# Every link claude_install makes, one "source<TAB>target" line each, for the
# sources the user repo has. check, install and verify all read this one list.
# The rest of ~/.claude is machine-local state -- sessions, transcripts, project
# history, credentials -- and must not be linked into a shared repo.
_claude_links() {
  local user_repo="$1"
  if [[ -f "$user_repo/config/claude/keybindings.json" ]]; then
    printf '%s\t%s\n' "$user_repo/config/claude/keybindings.json" "$HOME/.claude/keybindings.json"
  fi
  # The layout of the status line, which ccstatusline draws.
  if [[ -f "$user_repo/config/ccstatusline/settings.json" ]]; then
    printf '%s\t%s\n' "$user_repo/config/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
  fi
}

# ~/.claude/settings.json is never linked: it holds each sleeve's own
# permissions, hooks and plugins. Only its statusLine key is managed, from the
# user repo's config/claude/statusline.json, and only when the repo has one.
_claude_statusline() {
  if [[ -f "$1/config/claude/statusline.json" ]]; then
    echo "$1/config/claude/statusline.json"
  fi
}

# Names why ~/.claude/settings.json does not carry the statusLine in $1, and
# prints nothing when it does. Returns non-zero when molt cannot tell, or must
# not write the file. jq -S sorts keys, so key order and layout are not
# differences; the dev-tools liberator already requires jq on every sleeve.
_claude_statusline_fault() {
  local source="$1" settings="$HOME/.claude/settings.json" want have
  if ! command -v jq &>/dev/null; then
    echo "cannot be checked: jq is not installed"
    return 1
  fi
  if ! want="$(jq -eS 'select(type == "object")' "$source" 2>/dev/null)"; then
    echo "cannot be checked: $source holds no statusLine object"
    return 1
  fi
  # Writing replaces the file, which would silently turn a link into a copy.
  if [[ -L "$settings" ]]; then
    echo "is a symlink to $(readlink "$settings"); it must not be linked, so molt will not write it"
    return 1
  fi
  if [[ ! -f "$settings" ]]; then
    echo "is missing"
  elif ! have="$(jq -S 'if type == "object" then .statusLine else error("not an object") end' "$settings" 2>/dev/null)"; then
    echo "is not a JSON object"
    return 1
  elif [[ -z "$have" ]]; then
    echo "is empty"
  elif [[ "$have" == "null" ]]; then
    echo "has no statusLine"
  elif [[ "$have" != "$want" ]]; then
    echo "has a different statusLine"
  fi
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, why
# ~/.claude/settings.json does not carry the statusLine the user repo $3
# declares. Returns non-zero when it reported one.
_claude_report_statusline_fault() {
  local log="$1" prefix="$2" statusline fault
  statusline="$(_claude_statusline "$3")"
  [[ -n "$statusline" ]] || return 0
  if ! fault="$(_claude_statusline_fault "$statusline")" || [[ -n "$fault" ]]; then
    "$log" "${prefix}~/.claude/settings.json $fault"
    return 1
  fi
}

# Writes the statusLine in $1 into ~/.claude/settings.json and changes no other
# key. A file that already carries it is left alone. Every step is checked by
# hand: resleeve runs install inside an `if`, where set -e does not apply, so a
# failed copy or rename would otherwise run on to "written".
_claude_statusline_install() {
  local source="$1" settings="$HOME/.claude/settings.json" fault current tmp backup
  if ! fault="$(_claude_statusline_fault "$source")"; then
    molt_error "claude: ~/.claude/settings.json $fault"
    return 1
  fi
  [[ -n "$fault" ]] || return 0

  current="$settings"
  [[ -f "$current" ]] || current=/dev/null
  tmp="$(mktemp "${settings}.XXXXXX")" || return 1
  # cp -p gives tmp the file's mode, which the write below keeps.
  if [[ -f "$settings" ]] && ! cp -p "$settings" "$tmp"; then
    rm -f "$tmp"
    molt_error "claude: could not copy ~/.claude/settings.json, so its statusLine was not written"
    return 1
  fi
  # An absent or empty settings.json merges as {}.
  if ! jq -n --slurpfile cur "$current" --slurpfile sl "$source" \
      '($cur[0] // {}) | .statusLine = $sl[0]' >"$tmp"; then
    rm -f "$tmp"
    molt_error "claude: statusLine not written; ~/.claude/settings.json was left as it was"
    return 1
  fi

  if [[ -f "$settings" ]]; then
    backup="${settings}.molt-backup.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$settings" "$backup"; then
      rm -f "$tmp"
      molt_error "claude: could not back up ~/.claude/settings.json, so its statusLine was not written"
      return 1
    fi
    molt_warn "Backing up existing file: $settings -> $backup"
  fi
  # A rename, so Claude Code, which watches this file, never reads half of it.
  if ! mv -f "$tmp" "$settings"; then
    rm -f "$tmp"
    molt_error "claude: statusLine not written; ~/.claude/settings.json was left as it was"
    return 1
  fi
  molt_info "claude: statusLine written into ~/.claude/settings.json"
}

claude_check() {
  local ok=0

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0

  molt_report_link_faults molt_info "claude: " "$(_claude_links "$user_repo")" || ok=1
  _claude_report_statusline_fault molt_info "claude: " "$user_repo" || ok=1

  return $ok
}

claude_install() {
  local user_repo links statusline
  user_repo="$(molt_find_user_repo)" || return 1

  # ~/.claude is created by Claude Code itself, but a sleeve may be resleeved
  # before Claude Code has ever run on it.
  mkdir -p "$HOME/.claude" || return 1

  links="$(_claude_links "$user_repo")"
  statusline="$(_claude_statusline "$user_repo")"
  if [[ -z "$links" && -z "$statusline" ]]; then
    molt_warn "claude: nothing to manage -- $user_repo/config has no Claude Code config"
  fi

  molt_link_all "$links" || return 1
  if [[ -n "$statusline" ]]; then
    _claude_statusline_install "$statusline" || return 1
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
    molt_report_link_faults molt_error "VERIFY FAIL: " "$(_claude_links "$user_repo")" || errors=1
    _claude_report_statusline_fault molt_error "VERIFY FAIL: " "$user_repo" || errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: claude liberator is fully operational"
  fi
  return $errors
}
