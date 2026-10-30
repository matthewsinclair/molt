#!/usr/bin/env bash
# hammerspoon.sh — Liberator: Hammerspoon
# Frees you from re-binding each Mac's window grid and app keys by hand, and
# from arngz losing its `hs` CLI (issue 0074, hv 30 Oct 2026).
#
# One link, made only when the user repo has its source: ~/.hammerspoon/init.lua,
# as a file. Its hs.ipc block is what gives arngz the `hs` CLI. The rest of
# ~/.hammerspoon is Spoons/, where third-party Spoons are installed, and they do
# not belong in the user repo.
#
# macOS only: Hammerspoon runs on the Macs.

# Every link hammerspoon_install makes, one "source<TAB>target" line each, for
# the sources the user repo $1 has. check, install and verify all read it.
_hammerspoon_links() {
  local user_repo="$1"
  if [[ -f "$user_repo/config/hammerspoon/init.lua" ]]; then
    printf '%s\t%s\n' "$user_repo/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
  fi
}

hammerspoon_check() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "hammerspoon: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  molt_report_link_faults molt_info "hammerspoon: " "$(_hammerspoon_links "$user_repo")"
}

hammerspoon_install() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "hammerspoon: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link_all "$(_hammerspoon_links "$user_repo")" || return 1
  molt_info "Liberator complete: hammerspoon"
}

hammerspoon_verify() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_report_link_faults molt_error "VERIFY FAIL: " "$(_hammerspoon_links "$user_repo")" || return 1
  molt_info "Verified: hammerspoon liberator is fully operational"
}
