#!/usr/bin/env bash
# iterm2.sh — Liberator: iTerm2
# Frees you from default Terminal.app with iTerm2 dynamic profiles.

iterm2_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_debug "iterm2: only applicable on macOS"
    return 0
  fi

  if [[ ! -d "/Applications/iTerm.app" ]]; then
    molt_info "iterm2: iTerm2 not installed"
    ok=1
    return $ok
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/iterm2/molt-profile.json" ]]; then
    local target="$HOME/Library/Application Support/iTerm2/DynamicProfiles/molt-profile.json"
    if [[ ! -L "$target" ]]; then
      molt_info "iterm2: dynamic profile not linked"
      ok=1
    fi
  fi

  return $ok
}

iterm2_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_info "iterm2: skipping on $platform (macOS only)"
    return 0
  fi

  if [[ ! -d "/Applications/iTerm.app" ]]; then
    molt_error "iTerm2 not found. Install it (eg brew install --cask iterm2) then re-run."
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local profile_src="$user_repo/config/iterm2/molt-profile.json"

  if [[ ! -f "$profile_src" ]]; then
    molt_warn "iterm2: no profile config found at $profile_src — skipping profile setup"
    molt_info "Liberator complete: iterm2 (no profile to install yet)"
    return 0
  fi

  local target_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$target_dir"
  molt_link "$profile_src" "$target_dir/molt-profile.json"

  molt_info "Liberator complete: iterm2"
}

iterm2_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "macos" ]]; then
    molt_info "Verified: iterm2 liberator not applicable on $platform"
    return 0
  fi

  if [[ ! -d "/Applications/iTerm.app" ]]; then
    molt_error "VERIFY FAIL: iTerm2 not installed"
    errors=1
    return $errors
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/iterm2/molt-profile.json" ]]; then
    local target="$HOME/Library/Application Support/iTerm2/DynamicProfiles/molt-profile.json"
    if [[ ! -L "$target" ]]; then
      molt_error "VERIFY FAIL: iTerm2 dynamic profile not linked"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: iterm2 liberator is fully operational"
  fi
  return $errors
}
