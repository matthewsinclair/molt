#!/usr/bin/env bash
# alacritty.sh — Liberator: Alacritty terminal emulator
# Frees you from default terminals with a GPU-accelerated alternative.

# Reports whether the installed config is wrong, for either form.
#
# A rendered config is a regular FILE, so molt_link_healthy fails on it forever
# and the liberator reinstalls every run. A linked config has no digest, so
# molt_config_stale is meaningless for it. The right test depends on which form
# the repo carries, which is exactly what rule 4 in writing-a-liberator.md is
# about -- and the trap that switching to molt_install_config would otherwise
# have set for whoever first renamed this file to .tmpl.
_alacritty_config_wrong() {
  local user_repo target="$HOME/.config/alacritty/alacritty.toml"
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 1

  local tmpl="$user_repo/config/alacritty/alacritty.toml.tmpl"
  if [[ -f "$tmpl" ]]; then
    molt_config_stale "$tmpl" "$target"
  else
    ! molt_link_healthy "$target"
  fi
}

# Describes the fault, in whichever form applies.
_alacritty_config_fault() {
  local user_repo target="$HOME/.config/alacritty/alacritty.toml"
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" && -f "$user_repo/config/alacritty/alacritty.toml.tmpl" ]]; then
    echo "differs from its template or instance vars -- re-rendering"
  else
    molt_link_fault "$target"
  fi
}

# True when the user repo carries an alacritty config in either form.
_alacritty_config_present() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 1
  [[ -f "$user_repo/config/alacritty/alacritty.toml" ]] \
    || [[ -f "$user_repo/config/alacritty/alacritty.toml.tmpl" ]]
}

alacritty_check() {
  local ok=0

  if ! command -v alacritty &>/dev/null; then
    molt_info "alacritty: not installed"
    ok=1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && _alacritty_config_present; then
    if _alacritty_config_wrong; then
      molt_info "alacritty: ~/.config/alacritty/alacritty.toml $(_alacritty_config_fault)"
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
  if _alacritty_config_present; then
    mkdir -p "$HOME/.config/alacritty"
    # Via molt_install_config, not molt_link, so alacritty.toml.tmpl is possible.
    # Linking directly meant the liberator only ever looked for the literal
    # filename: renaming the config to .tmpl made it vanish rather than render.
    # That is why MOLT_FONT_FAMILY and MOLT_FONT_SIZE are declared in every
    # instance's vars.sh and read by nothing.
    molt_install_config "config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
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
  if [[ -n "$user_repo" ]] && _alacritty_config_present; then
    if _alacritty_config_wrong; then
      molt_error "VERIFY FAIL: ~/.config/alacritty/alacritty.toml $(_alacritty_config_fault)"
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
