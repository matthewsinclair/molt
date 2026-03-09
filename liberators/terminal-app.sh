#!/usr/bin/env bash
# terminal-app.sh — Liberator: macOS Terminal.app
# Frees you from default Terminal.app profile with a custom Molt profile.

terminal-app_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_debug "terminal-app: only applicable on macOS"
    return 0
  fi

  # Terminal.app is always present on macOS, just check profile
  local default_profile
  default_profile="$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "")"
  if [[ "$default_profile" != "Molt" ]]; then
    molt_info "terminal-app: default profile is not 'Molt' (current: ${default_profile:-unset})"
    ok=1
  fi

  return $ok
}

terminal-app_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_info "terminal-app: skipping on $platform (macOS only)"
    return 0
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local profile_src="$user_repo/config/terminal-app/Molt.terminal"

  if [[ ! -f "$profile_src" ]]; then
    molt_warn "terminal-app: no profile found at $profile_src — skipping profile setup"
    molt_info "Liberator complete: terminal-app (no profile to install yet)"
    return 0
  fi

  # Import the .terminal profile (macOS opens and imports it)
  open "$profile_src"

  # Set as default profile
  defaults write com.apple.Terminal "Default Window Settings" -string "Molt"
  defaults write com.apple.Terminal "Startup Window Settings" -string "Molt"

  molt_info "Liberator complete: terminal-app"
}

terminal-app_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_info "Verified: terminal-app liberator not applicable on $platform"
    return 0
  fi

  local default_profile
  default_profile="$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "")"
  if [[ "$default_profile" != "Molt" ]]; then
    molt_error "VERIFY FAIL: Terminal.app default profile is not 'Molt'"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: terminal-app liberator is fully operational"
  fi
  return $errors
}
