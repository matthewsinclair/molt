#!/usr/bin/env bash
# herdr.sh — Liberator: Herdr
# Frees you from re-binding Herdr's keys and re-declaring its spaces on every Mac
# (issue 0074, hv 30 Oct 2026).
#
# Two links, each made only when the user repo has its source:
#
#   - ~/.config/herdr-app/keys.json, the key bindings, as a file. The rest of
#     ~/.config/herdr-app is the app's own state (sockets, window and view json,
#     telemetry), and its settings.json stays the sleeve's. Herdr reloads the
#     bindings when the file is saved, and writes only keys.error beside it.
#   - ~/.config/hrdrcfg, hrdrcfg's defaults and spaces, as the whole directory:
#     `hrdrcfg discover` rewrites space files there and adds new ones, and they
#     land in the repo only through a directory link.
#
# macOS only: Herdr.app runs on the Macs.

# Every link herdr_install makes, one "source<TAB>target" line each, for the
# sources the user repo $1 has. check, install and verify all read this list.
_herdr_links() {
  local user_repo="$1"
  if [[ -f "$user_repo/config/herdr-app/keys.json" ]]; then
    printf '%s\t%s\n' "$user_repo/config/herdr-app/keys.json" "$HOME/.config/herdr-app/keys.json"
  fi
  if [[ -d "$user_repo/config/hrdrcfg" ]]; then
    printf '%s\t%s\n' "$user_repo/config/hrdrcfg" "$HOME/.config/hrdrcfg"
  fi
}

# Why the user repo $1's keys.json is not the one JSON object Herdr reads, or
# nothing when it is or the repo has none. Herdr refuses bindings it cannot
# read, so such a file is a fault even when its link is sound. `jq empty`
# passed an empty file, whitespace, two objects and a top-level array, all of
# which Herdr refuses; jq's own first line says why, so an unreadable file does
# not read as bad JSON.
_herdr_keys_fault() {
  local keys="$1/config/herdr-app/keys.json" err
  [[ -f "$keys" ]] || return 0
  if ! command -v jq &>/dev/null; then
    echo "jq is not installed, so $(molt_tilde "$keys") cannot be read"
  elif ! err="$(jq -se 'length == 1 and (.[0] | type == "object")' "$keys" 2>&1 >/dev/null)"; then
    err="${err%%$'\n'*}"
    echo "$(molt_tilde "$keys") is not one JSON object${err:+ ($err)}"
  fi
}

herdr_check() {
  local ok=0 user_repo fault
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "herdr: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  molt_report_link_faults molt_info "herdr: " "$(_herdr_links "$user_repo")" || ok=1
  fault="$(_herdr_keys_fault "$user_repo")"
  if [[ -n "$fault" ]]; then
    molt_info "herdr: $fault"
    ok=1
  fi
  return $ok
}

herdr_install() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "herdr: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link_all "$(_herdr_links "$user_repo")" || return 1
  # A keys.json Herdr cannot read fails install too: check failing sends
  # resleeve here, and returning 0 printed "installed" and "Sleeve ready" with
  # the fault still standing.
  local fault
  fault="$(_herdr_keys_fault "$user_repo")"
  if [[ -n "$fault" ]]; then
    if ! command -v jq &>/dev/null; then
      molt_error "herdr: $fault; install jq (eg brew install jq), then run molt resleeve"
    else
      molt_error "herdr: $fault; fix it in the user repo, then run molt resleeve"
    fi
    return 1
  fi
  molt_info "Liberator complete: herdr"
}

herdr_verify() {
  local errors=0 user_repo fault
  if [[ "$(molt_platform)" != "macos" ]]; then
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_report_link_faults molt_error "VERIFY FAIL: " "$(_herdr_links "$user_repo")" || errors=1
  fault="$(_herdr_keys_fault "$user_repo")"
  if [[ -n "$fault" ]]; then
    molt_error "VERIFY FAIL: $fault"
    errors=1
  fi
  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: herdr liberator is fully operational"
  fi
  return $errors
}
