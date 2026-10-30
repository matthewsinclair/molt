#!/usr/bin/env bash
# menuz.sh — Liberator: menuz
# Frees you from rebuilding the menu bar's menu on each Mac (issue 0074, hv 30
# Oct 2026).
#
# menuz is Utilz's menu bar app. Its menu is ~/.config/menuz/menuz.yaml, and
# ~/.config/menuz/bin is put first on PATH for everything the menu runs. menuz
# itself writes there only at `menuz init`, but `menuz edit` opens the menu in
# an editor, and an editor's save may replace the file, which would leave a link
# to the file behind a plain copy. So the whole ~/.config/menuz directory is
# linked, made only when the user repo has config/menuz.
#
# macOS only: menuz runs on the Macs.

# Every link menuz_install makes, one "source<TAB>target" line each, for the
# sources the user repo $1 has. check, install and verify all read this list.
_menuz_links() {
  local user_repo="$1"
  if [[ -d "$user_repo/config/menuz" ]]; then
    printf '%s\t%s\n' "$user_repo/config/menuz" "$HOME/.config/menuz"
  fi
}

menuz_check() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "menuz: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  molt_report_link_faults molt_info "menuz: " "$(_menuz_links "$user_repo")"
}

menuz_install() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "menuz: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link_all "$(_menuz_links "$user_repo")" || return 1
  molt_info "Liberator complete: menuz"
}

menuz_verify() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_report_link_faults molt_error "VERIFY FAIL: " "$(_menuz_links "$user_repo")" || return 1
  molt_info "Verified: menuz liberator is fully operational"
}
