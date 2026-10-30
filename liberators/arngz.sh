#!/usr/bin/env bash
# arngz.sh — Liberator: arngz
# Frees you from re-arranging each Mac's desks by hand (issue 0074, hv 30 Oct
# 2026).
#
# arngz is Utilz's window arranger (Hammerspoon). Its desks live in
# ~/.config/arngz/desks, and `arngz discover --save <desk> --force`, which
# menuz's Discover runs, rewrites a desk there or adds one. So the whole
# ~/.config/arngz directory is linked, made only when the user repo has
# config/arngz: a link to each desk would leave a new desk out of the repo.
#
# macOS only: arngz runs on the Macs.

# Every link arngz_install makes, one "source<TAB>target" line each, for the
# sources the user repo $1 has. check, install and verify all read this list.
_arngz_links() {
  local user_repo="$1"
  if [[ -d "$user_repo/config/arngz" ]]; then
    printf '%s\t%s\n' "$user_repo/config/arngz" "$HOME/.config/arngz"
  fi
}

arngz_check() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "arngz: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  molt_report_link_faults molt_info "arngz: " "$(_arngz_links "$user_repo")"
}

arngz_install() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "arngz: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link_all "$(_arngz_links "$user_repo")" || return 1
  molt_info "Liberator complete: arngz"
}

arngz_verify() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_report_link_faults molt_error "VERIFY FAIL: " "$(_arngz_links "$user_repo")" || return 1
  molt_info "Verified: arngz liberator is fully operational"
}
