#!/usr/bin/env bash
# desktop.sh — Liberator: desktop environment settings
# Frees you from GNOME defaults that steal your keys.

desktop_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "desktop: only applicable on Linux"
    return 0
  fi

  if ! command -v gsettings &>/dev/null; then
    molt_debug "desktop: gsettings not available (no GNOME?)"
    return 0
  fi

  # Check if GNOME Super/overlay key is disabled
  local overlay_key
  overlay_key="$(gsettings get org.gnome.mutter overlay-key 2>/dev/null || echo "unavailable")"
  if [[ "$overlay_key" != "''" ]] && [[ "$overlay_key" != "unavailable" ]]; then
    molt_info "desktop: GNOME overlay-key still bound ($overlay_key)"
    ok=1
  fi

  # Check GTK config
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gtk_dir="$HOME/.config/gtk-3.0"
    if [[ ! -f "$gtk_dir/gtk.css" ]]; then
      molt_info "desktop: GTK config not installed"
      ok=1
    fi
  fi

  return $ok
}

desktop_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "desktop: skipping on $platform (Linux only)"
    return 0
  fi

  if ! command -v gsettings &>/dev/null; then
    molt_info "desktop: no GNOME desktop detected, skipping"
    return 0
  fi

  # Strip GNOME Super bindings
  molt_info "Stripping GNOME Super key bindings..."
  gsettings set org.gnome.mutter overlay-key '' 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "[]" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']" 2>/dev/null || true

  # Install GTK config
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  if [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    molt_link "$user_repo/config/gtk/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
  fi

  molt_info "Liberator complete: desktop"
}

desktop_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: desktop liberator not applicable on $platform"
    return 0
  fi

  if command -v gsettings &>/dev/null; then
    local overlay_key
    overlay_key="$(gsettings get org.gnome.mutter overlay-key 2>/dev/null || echo "")"
    if [[ -n "$overlay_key" ]] && [[ "$overlay_key" != "''" ]]; then
      molt_error "VERIFY FAIL: GNOME overlay-key still bound"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: desktop liberator is fully operational"
  fi
  return $errors
}
