#!/usr/bin/env bash
# alacritty.sh — Liberator: Alacritty terminal emulator
# Frees you from default terminals with a GPU-accelerated alternative.

alacritty_check() {
  local ok=0

  if ! command -v alacritty &>/dev/null; then
    molt_info "alacritty: not installed"
    ok=1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/alacritty/alacritty.toml" ]]; then
    if [[ ! -L "$HOME/.config/alacritty/alacritty.toml" ]]; then
      molt_info "alacritty: config not symlinked"
      ok=1
    fi
  fi

  return $ok
}

alacritty_install() {
  if ! command -v alacritty &>/dev/null; then
    molt_error "Alacritty not found. Install it (eg apt install alacritty, brew install --cask alacritty) then re-run."
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  if [[ -f "$user_repo/config/alacritty/alacritty.toml" ]]; then
    mkdir -p "$HOME/.config/alacritty"
    molt_link "$user_repo/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  fi

  molt_info "Liberator complete: alacritty"
}

alacritty_verify() {
  local errors=0

  if ! command -v alacritty &>/dev/null; then
    molt_error "VERIFY FAIL: Alacritty not installed"
    errors=1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/alacritty/alacritty.toml" ]]; then
    if [[ ! -L "$HOME/.config/alacritty/alacritty.toml" ]]; then
      molt_error "VERIFY FAIL: Alacritty config not symlinked"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: alacritty liberator is fully operational"
  fi
  return $errors
}
