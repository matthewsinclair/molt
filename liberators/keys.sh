#!/usr/bin/env bash
# keys.sh — Liberator: keyboard remapping
# Frees you from default key layouts.

# keyd reads its config here; install puts the instance's copy there through
# sudo. MOLT_KEYD_CONFIG stands in for it in tests.
KEYD_CONFIG="${MOLT_KEYD_CONFIG:-/etc/keyd/default.conf}"

keys_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "keys: only applicable on Linux"
    return 0
  fi

  if ! command -v keyd &>/dev/null; then
    molt_info "keys: keyd not installed"
    return 1
  fi

  if ! systemctl is-active --quiet keyd 2>/dev/null; then
    molt_info "keys: keyd service not running"
    ok=1
  fi

  if [[ ! -f "$KEYD_CONFIG" ]]; then
    molt_info "keys: keyd config not present"
    ok=1
  fi

  return $ok
}

keys_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "keys: skipping on $platform (Linux only)"
    return 0
  fi

  # Build keyd from source if not installed
  if ! command -v keyd &>/dev/null; then
    molt_info "Building keyd from source..."
    molt_require_all git make gcc || return 1

    local tmpdir why=""
    if ! tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/molt-keyd.XXXXXX")"; then
      molt_error "keys: no temporary directory could be made to build keyd in"
      return 1
    fi
    if ! git clone https://github.com/rvaiya/keyd "$tmpdir/keyd"; then
      why="keyd could not be cloned from https://github.com/rvaiya/keyd"
    elif ! (cd "$tmpdir/keyd" && make && sudo make install); then
      why="keyd could not be built and installed from source"
    fi
    rm -rf "$tmpdir" || molt_warn "keys: the build directory $tmpdir could not be removed"
    if [[ -n "$why" ]]; then
      molt_error "keys: $why"
      return 1
    fi
  fi

  # Enable and start service
  if ! systemctl is-active --quiet keyd 2>/dev/null; then
    molt_info "Enabling keyd service..."
    if ! sudo systemctl enable keyd; then
      molt_error "keys: the keyd service could not be enabled"
      return 1
    fi
    if ! sudo systemctl start keyd; then
      molt_error "keys: the keyd service could not be started"
      return 1
    fi
  fi

  # Install config from instance directory if available
  local instance_keyd
  if ! instance_keyd="$(molt_instance_file keyd/default.conf)"; then
    molt_error "keys: $instance_keyd"
    return 1
  fi

  if [[ -f "$instance_keyd" ]]; then
    molt_info "Installing keyd config from $(molt_tilde "$instance_keyd")..."
    local why
    if ! why="$(molt_sudo_install "$instance_keyd" "$KEYD_CONFIG")"; then
      molt_error "keys: the keyd config was not installed: $why"
      return 1
    fi
    if ! sudo keyd reload; then
      molt_error "keys: the keyd config is in place at $KEYD_CONFIG, but keyd did not reload it"
      return 1
    fi
  else
    molt_warn "No keyd config found for this instance"
    molt_warn "Expected: $instance_keyd"
  fi

  molt_info "Liberator complete: keys"
}

keys_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: keys liberator not applicable on $platform"
    return 0
  fi

  if ! command -v keyd &>/dev/null; then
    molt_error "VERIFY FAIL: keyd not installed"
    errors=1
  fi

  if ! systemctl is-active --quiet keyd 2>/dev/null; then
    molt_error "VERIFY FAIL: keyd service not running"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: keys liberator is fully operational"
  fi
  return $errors
}
