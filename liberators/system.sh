#!/usr/bin/env bash
# system.sh — Liberator: base system setup
# Frees you from a bare OS.

system_check() {
  local ok=0

  # Check if sudo is available
  if ! command -v sudo &>/dev/null; then
    molt_info "system: sudo not available"
    ok=1
  fi

  # Check if current user is in sudo group (Linux)
  if [[ "$(molt_platform)" == "linux" ]]; then
    if ! groups "$(whoami)" 2>/dev/null | grep -qw sudo; then
      molt_info "system: user not in sudo group"
      ok=1
    fi
  fi

  return $ok
}

system_install() {
  local platform
  platform="$(molt_platform)"

  case "$platform" in
    linux)
      if ! command -v sudo &>/dev/null; then
        molt_error "sudo not found. Install it then re-run."
        return 1
      fi
      ;;
    macos)
      if ! command -v brew &>/dev/null; then
        molt_error "Homebrew not found. Install it (https://brew.sh) then re-run."
        return 1
      fi
      ;;
  esac

  molt_info "Liberator complete: system"
}

system_verify() {
  local errors=0

  if ! command -v sudo &>/dev/null; then
    molt_error "VERIFY FAIL: sudo not available"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: system liberator is fully operational"
  fi
  return $errors
}
