#!/usr/bin/env bash
# gnome-terminal.sh — Liberator: GNOME Terminal
# Frees you from unconfigured GNOME Terminal defaults via dconf.

# Fixed UUID for idempotent profile management
MOLT_GNOME_TERMINAL_UUID="b1dfa3e8-9a6d-4c5e-8e7f-molt00000001"

gnome-terminal_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "gnome-terminal: only applicable on Linux"
    return 0
  fi

  if ! command -v gnome-terminal &>/dev/null; then
    molt_info "gnome-terminal: not installed"
    ok=1
    return $ok
  fi

  if ! command -v dconf &>/dev/null; then
    molt_info "gnome-terminal: dconf not available"
    ok=1
    return $ok
  fi

  # Check if our profile UUID exists
  local profile_path="/org/gnome/terminal/legacy/profiles:/:${MOLT_GNOME_TERMINAL_UUID}/"
  local visible_name
  visible_name="$(dconf read "${profile_path}visible-name" 2>/dev/null || echo "")"
  if [[ -z "$visible_name" ]]; then
    molt_info "gnome-terminal: Molt profile not loaded"
    ok=1
  fi

  # Check if our profile is the default
  local default_profile
  default_profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null || echo "")"
  if [[ "$default_profile" != "'${MOLT_GNOME_TERMINAL_UUID}'" ]]; then
    molt_info "gnome-terminal: Molt profile not set as default"
    ok=1
  fi

  return $ok
}

gnome-terminal_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "gnome-terminal: skipping on $platform (Linux only)"
    return 0
  fi

  if ! command -v gnome-terminal &>/dev/null; then
    molt_error "GNOME Terminal not found. Install it (eg apt install gnome-terminal) then re-run."
    return 1
  fi

  if ! command -v dconf &>/dev/null; then
    molt_error "dconf not found. Install it (eg apt install dconf-cli) then re-run."
    return 1
  fi

  # Find profile.dconf in user repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local profile_dconf="$user_repo/config/gnome-terminal/profile.dconf"

  if [[ ! -f "$profile_dconf" ]]; then
    molt_error "GNOME Terminal profile not found: $profile_dconf"
    return 1
  fi

  # Load profile via dconf
  local dconf_path="/org/gnome/terminal/legacy/profiles:/:${MOLT_GNOME_TERMINAL_UUID}/"
  molt_info "Loading GNOME Terminal profile..."
  dconf load "$dconf_path" < "$profile_dconf"

  # Register our UUID in the profile list
  local current_list
  current_list="$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null || echo "[]")"
  if [[ "$current_list" != *"${MOLT_GNOME_TERMINAL_UUID}"* ]]; then
    # Add our UUID to the list
    if [[ "$current_list" == "@as []" ]] || [[ "$current_list" == "[]" ]]; then
      gsettings set org.gnome.Terminal.ProfilesList list "['${MOLT_GNOME_TERMINAL_UUID}']"
    else
      # Append to existing list
      local new_list
      new_list="$(echo "$current_list" | sed "s/]/, '${MOLT_GNOME_TERMINAL_UUID}']/")"
      gsettings set org.gnome.Terminal.ProfilesList list "$new_list"
    fi
  fi

  # Set as default profile
  gsettings set org.gnome.Terminal.ProfilesList default "'${MOLT_GNOME_TERMINAL_UUID}'"

  molt_info "Liberator complete: gnome-terminal"
}

gnome-terminal_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: gnome-terminal liberator not applicable on $platform"
    return 0
  fi

  if ! command -v gnome-terminal &>/dev/null; then
    molt_error "VERIFY FAIL: GNOME Terminal not installed"
    errors=1
    return $errors
  fi

  # Check profile exists
  local profile_path="/org/gnome/terminal/legacy/profiles:/:${MOLT_GNOME_TERMINAL_UUID}/"
  local visible_name
  visible_name="$(dconf read "${profile_path}visible-name" 2>/dev/null || echo "")"
  if [[ -z "$visible_name" ]]; then
    molt_error "VERIFY FAIL: Molt profile not loaded in dconf"
    errors=1
  fi

  # Check default
  local default_profile
  default_profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null || echo "")"
  if [[ "$default_profile" != "'${MOLT_GNOME_TERMINAL_UUID}'" ]]; then
    molt_error "VERIFY FAIL: Molt profile not set as default"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: gnome-terminal liberator is fully operational"
  fi
  return $errors
}
