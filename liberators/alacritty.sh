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

  # On Linux/GNOME, check Alacritty is in the dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"Alacritty.desktop"* ]]; then
      molt_info "alacritty: not in GNOME dock favorites"
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

  # On Linux/GNOME, add Alacritty to dock favorites if not already there
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"Alacritty.desktop"* ]]; then
      # Append Alacritty.desktop to the favorites list
      local new_favorites
      new_favorites="${favorites/]/, \'Alacritty.desktop\']}"
      gsettings set org.gnome.shell favorite-apps "$new_favorites"
      molt_info "Added Alacritty to GNOME dock favorites"
    fi
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

  # On Linux/GNOME, verify Alacritty is in dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"Alacritty.desktop"* ]]; then
      molt_error "VERIFY FAIL: Alacritty not in GNOME dock favorites"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: alacritty liberator is fully operational"
  fi
  return $errors
}
