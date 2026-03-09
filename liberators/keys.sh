#!/usr/bin/env bash
# keys.sh — Liberator: keyboard remapping
# Frees you from default key layouts.

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

  if [[ ! -f /etc/keyd/default.conf ]]; then
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

    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://github.com/rvaiya/keyd "$tmpdir/keyd"
    cd "$tmpdir/keyd"
    make
    sudo make install
    cd -
    rm -rf "$tmpdir"
  fi

  # Enable and start service
  if ! systemctl is-active --quiet keyd 2>/dev/null; then
    molt_info "Enabling keyd service..."
    sudo systemctl enable keyd
    sudo systemctl start keyd
  fi

  # Install config from instance directory if available
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"
  local instance_keyd="$user_repo/instances/$hostname/keyd/default.conf"

  if [[ -f "$instance_keyd" ]]; then
    molt_info "Installing keyd config from instance/$hostname..."
    sudo cp "$instance_keyd" /etc/keyd/default.conf
    sudo keyd reload
  else
    molt_warn "No keyd config found for instance $hostname"
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
