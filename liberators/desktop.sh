#!/usr/bin/env bash
# desktop.sh — Liberator: desktop environment settings
# Frees you from GNOME defaults that steal your keys.

# GTK3 and GTK4 read different paths and do not share a stylesheet. Linking
# gtk-3.0 only left GTK4 apps -- now the common case -- unstyled, and molt could
# not repair a gtk-4.0 link because it never created one.
# Dock favourites, read from instances/<host>/desktop/favorite-apps.
#
# Instance-scoped like keys.sh (keyd/default.conf) and ssh.sh (ssh/config.d),
# because which apps a machine pins is per-machine and Linux-only. One .desktop
# id per line; line order is dock order. Blank lines and # comments ignored.
#
# Worth managing because the dock silently outranks every "default terminal"
# setting there is: kovacs had alacritty set as default by gsettings AND by
# /etc/alternatives, and still launched gnome-terminal, because both were
# pinned and the user clicked the icon. A fresh sleeve gets whatever GNOME
# ships, which is how that happened.
_desktop_favorites_file() {
  local user_repo hostname
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")" || return 1
  [[ -n "$user_repo" ]] || return 1
  hostname="$(hostname -s 2>/dev/null || echo "unknown")"
  local f="$user_repo/instances/$hostname/desktop/favorite-apps"
  [[ -f "$f" ]] || return 1
  echo "$f"
}

# True when the favourites file yields no entries.
#
# "Present but empty" is almost always a malformed file or a glob that matched
# nothing, not a deliberate request for a bare dock -- and applying it wipes
# every pinned app, which the user sees immediately. kovacs demonstrated this
# for real while testing the empty case: one gsettings set with an empty list
# emptied the live dock. Recoverable only because the favourites file existed
# to restore from. Refuse it rather than apply it.
_desktop_favorites_empty() {
  [[ "$(_desktop_favorites_wanted "$1")" == "@as []" ]]
}

# The value gsettings would need, as a GVariant string array literal.
_desktop_favorites_wanted() {
  local f="$1" line first=1 out="["
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]')"
    [[ -n "$line" ]] || continue
    [[ $first -eq 1 ]] || out+=", "
    out+="'${line}'"
    first=0
  done < "$f"
  out+="]"
  # gsettings prints an empty string array as "@as []", not "[]", so an empty
  # favourites list would otherwise read as permanent drift.
  [[ $first -eq 1 ]] && out="@as []"
  echo "$out"
}

_desktop_gtk_versions() {
  echo "gtk-3.0 gtk-4.0"
}

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
    local gv
    for gv in $(_desktop_gtk_versions); do
      if ! molt_link_healthy "$HOME/.config/$gv/gtk.css"; then
        molt_info "desktop: ~/.config/${gv}/gtk.css $(molt_link_fault "$HOME/.config/$gv/gtk.css")"
        ok=1
      fi
    done
  fi

  # Dock favourites drift
  local fav_file
  if fav_file="$(_desktop_favorites_file)" && command -v gsettings &>/dev/null; then
    if _desktop_favorites_empty "$fav_file"; then
      molt_warn "desktop: ${fav_file#"$HOME/"} has no entries -- ignoring it."
      molt_warn "        Applying it would empty the dock, which is far more likely"
      molt_warn "        to be a malformed file than a deliberate choice."
    else
      local want have
      want="$(_desktop_favorites_wanted "$fav_file")"
      have="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
      if [[ "$want" != "$have" ]]; then
        molt_info "desktop: dock favourites differ from ${fav_file#"$HOME/"}"
        ok=1
      fi
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

  # Strip GNOME accessibility bindings that conflict with Super combos
  gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "['']" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier "['']" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in "['']" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out "['']" 2>/dev/null || true

  # Install GTK config
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  if [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gv
    for gv in $(_desktop_gtk_versions); do
      mkdir -p "$HOME/.config/$gv"
      molt_link "$user_repo/config/gtk/gtk.css" "$HOME/.config/$gv/gtk.css"
    done
  fi

  # Dock favourites
  local fav_file
  if fav_file="$(_desktop_favorites_file)"; then
    if _desktop_favorites_empty "$fav_file"; then
      molt_warn "desktop: refusing to apply ${fav_file#"$HOME/"} -- it has no entries."
      molt_warn "        That would empty the dock. Fix the file, or delete it if you"
      molt_warn "        want molt to leave dock favourites alone entirely."
    elif command -v gsettings &>/dev/null; then
      local want
      want="$(_desktop_favorites_wanted "$fav_file")"
      if gsettings set org.gnome.shell favorite-apps "$want" 2>/dev/null; then
        molt_info "Dock favourites set from ${fav_file#"$HOME/"}"
      else
        molt_warn "desktop: could not set dock favourites (gsettings refused '${want}')"
      fi
    else
      molt_warn "desktop: ${fav_file#"$HOME/"} present but gsettings is not available"
    fi
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

  # _install links the GTK stylesheet; verify never checked it.
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gv
    for gv in $(_desktop_gtk_versions); do
      if ! molt_link_healthy "$HOME/.config/$gv/gtk.css"; then
        molt_error "VERIFY FAIL: ~/.config/${gv}/gtk.css $(molt_link_fault "$HOME/.config/$gv/gtk.css")"
        errors=1
      fi
    done
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: desktop liberator is fully operational"
  fi
  return $errors
}
