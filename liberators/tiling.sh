#!/usr/bin/env bash
# tiling.sh — Liberator: tiling window management via Tactile
# Frees you from manual window positioning with a Divvy-like grid picker.
#
# Tactile workflow: Shift+Alt+Super+T shows grid overlay, type two keys to define
# a rectangle (eg Q,C = full left column, Q,V = full screen).
# Keyboard maps to screen position: QWE=top, ASD=middle, ZXC=bottom.

TACTILE_UUID="tactile@lundal.io"
TACTILE_SCHEMA="org.gnome.shell.extensions.tactile"
TACTILE_EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$TACTILE_UUID"

tiling_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "tiling: only applicable on Linux"
    return 0
  fi

  if ! command -v gnome-extensions &>/dev/null; then
    molt_debug "tiling: gnome-extensions not available (no GNOME?)"
    return 0
  fi

  # Check Tactile is installed
  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    molt_info "tiling: Tactile extension not installed"
    ok=1
    return $ok
  fi

  # Check Tactile is enabled (may fail before first shell restart)
  local state
  state="$(gnome-extensions info "$TACTILE_UUID" 2>/dev/null | grep -oP 'State: \K\S+' || echo "UNKNOWN")"
  if [[ "$state" != "ACTIVE" ]] && [[ "$state" != "ENABLED" ]]; then
    molt_info "tiling: Tactile not active (state: $state, may need shell restart)"
    ok=1
  fi

  # Check grid is configured as 7x3
  if command -v gsettings &>/dev/null; then
    local col6 row2
    col6="$(gsettings get $TACTILE_SCHEMA col-6 2>/dev/null || echo "0")"
    row2="$(gsettings get $TACTILE_SCHEMA row-2 2>/dev/null || echo "0")"
    if [[ "$col6" != "1" ]] || [[ "$row2" != "1" ]]; then
      molt_info "tiling: Tactile grid not configured as 7x3"
      ok=1
    fi
  fi

  return $ok
}

tiling_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "tiling: skipping on $platform (Linux only)"
    return 0
  fi

  if ! command -v gnome-extensions &>/dev/null; then
    molt_info "tiling: no GNOME desktop detected, skipping"
    return 0
  fi

  # Check Tactile is installed (we don't install extensions — just configure)
  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    molt_error "Tactile extension not found. Install it first:"
    molt_error "  curl -sL 'https://extensions.gnome.org/download-extension/tactile@lundal.io.shell-extension.zip?version_tag=65140' -o /tmp/tactile.zip"
    molt_error "  gnome-extensions install /tmp/tactile.zip --force"
    molt_error "  # Then log out and back in to activate"
    return 1
  fi

  # Install schema system-wide if not already present
  local system_schema="/usr/share/glib-2.0/schemas/org.gnome.shell.extensions.tactile.gschema.xml"
  if [[ ! -f "$system_schema" ]]; then
    molt_info "Installing Tactile gsettings schema..."
    sudo cp "$TACTILE_EXT_DIR/schemas/org.gnome.shell.extensions.tactile.gschema.xml" \
      /usr/share/glib-2.0/schemas/
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
  fi

  # Enable the extension (may fail before shell restart — that's OK)
  gnome-extensions enable "$TACTILE_UUID" 2>/dev/null || \
    molt_warn "Could not enable Tactile (shell restart may be needed)"

  # Configure 3x3 grid (equal weight columns and rows)
  molt_info "Configuring Tactile: 7x3 grid (QWERTYU/ASDFGHJ/ZXCVBNM)..."
  gsettings set $TACTILE_SCHEMA col-0 1
  gsettings set $TACTILE_SCHEMA col-1 1
  gsettings set $TACTILE_SCHEMA col-2 1
  gsettings set $TACTILE_SCHEMA col-3 1
  gsettings set $TACTILE_SCHEMA col-4 1
  gsettings set $TACTILE_SCHEMA col-5 1
  gsettings set $TACTILE_SCHEMA col-6 1
  gsettings set $TACTILE_SCHEMA grid-cols 7
  gsettings set $TACTILE_SCHEMA grid-rows 3
  gsettings set $TACTILE_SCHEMA row-0 1
  gsettings set $TACTILE_SCHEMA row-1 1
  gsettings set $TACTILE_SCHEMA row-2 1
  gsettings set $TACTILE_SCHEMA row-3 0
  gsettings set $TACTILE_SCHEMA row-4 0

  # Activation keybinding: Shift+Alt+Super+T
  gsettings set $TACTILE_SCHEMA show-tiles "['<Shift><Alt><Super>t']"

  # Window gap and maximize
  gsettings set $TACTILE_SCHEMA gap-size 4
  gsettings set $TACTILE_SCHEMA maximize true

  molt_info "Liberator complete: tiling"
  molt_info "  Activate: Shift+Alt+Super+T → type two keys to tile (eg Q,C = left third)"
  molt_info "  Grid: Q W E R T Y U / A S D F G H J / Z X C V B N M"
}

tiling_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: tiling liberator not applicable on $platform"
    return 0
  fi

  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    molt_error "VERIFY FAIL: Tactile extension not installed"
    errors=1
  fi

  if command -v gsettings &>/dev/null; then
    local col6
    col6="$(gsettings get $TACTILE_SCHEMA col-6 2>/dev/null || echo "0")"
    if [[ "$col6" != "1" ]]; then
      molt_error "VERIFY FAIL: Tactile grid not configured"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: tiling liberator is fully operational"
  fi
  return $errors
}
