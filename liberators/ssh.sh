#!/usr/bin/env bash
# ssh.sh — Liberator: SSH configuration
# Frees you from typing full hostnames.

# Find any existing SSH private key (not just id_ed25519/id_rsa)
_ssh_find_key() {
  for key in "$HOME/.ssh"/id_*; do
    # Skip public keys and non-files
    [[ -f "$key" ]] || continue
    [[ "$key" == *.pub ]] && continue
    echo "$key"
    return 0
  done
  # Also check common custom key names
  for key in "$HOME/.ssh"/personalid "$HOME/.ssh"/personal_id; do
    [[ -f "$key" ]] && echo "$key" && return 0
  done
  return 1
}

ssh_check() {
  local ok=0

  if ! command -v ssh &>/dev/null; then
    molt_info "ssh: not installed"
    return 1
  fi

  # Check if any SSH key exists
  if ! _ssh_find_key &>/dev/null; then
    molt_info "ssh: no SSH key found"
    ok=1
  fi

  # Check if config is managed by molt (rendered file, not symlink — sshd rejects symlinks)
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    if [[ -f "$user_repo/config/ssh/config.tmpl" ]] || [[ -f "$user_repo/config/ssh/config" ]]; then
      if [[ -L "$HOME/.ssh/config" ]]; then
        molt_info "ssh: ~/.ssh/config is a symlink (sshd requires regular files)"
        ok=1
      elif [[ ! -f "$HOME/.ssh/config.molt-rendered" ]]; then
        molt_info "ssh: ~/.ssh/config is not managed by molt"
        ok=1
      fi
    fi
  fi

  return $ok
}

ssh_install() {
  # SSH should already be installed on any system

  # Ensure ~/.ssh exists with correct permissions
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Generate key only if NO key exists at all
  if ! _ssh_find_key &>/dev/null; then
    molt_info "Generating SSH key..."
    local email
    email="$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname -s 2>/dev/null || hostname)")"
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
    molt_warn "New SSH key generated. Add public key to GitHub/remotes:"
    molt_warn "  cat ~/.ssh/id_ed25519.pub"
  else
    local existing_key
    existing_key="$(_ssh_find_key)"
    molt_info "SSH key found: $existing_key"
  fi

  # Install config from user repo (template or static)
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  molt_install_config "config/ssh/config" "$HOME/.ssh/config"

  # Append instance-specific config.d fragments (idempotent via sentinels)
  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"
  local config_d="$user_repo/instances/$hostname/ssh/config.d"
  if [[ -d "$config_d" ]]; then
    for fragment in "$config_d"/*.conf; do
      [[ -f "$fragment" ]] || continue
      local fragment_name
      fragment_name="$(basename "$fragment")"
      local sentinel="# --- molt config.d: ${fragment_name} ---"
      # Only append if sentinel not already present
      if ! grep -qF "$sentinel" "$HOME/.ssh/config" 2>/dev/null; then
        molt_info "Appending SSH config fragment: $fragment_name"
        {
          echo ""
          echo "$sentinel"
          cat "$fragment"
        } >> "$HOME/.ssh/config"
      else
        molt_debug "SSH config fragment already present: $fragment_name"
      fi
    done
  fi

  chmod 600 "$HOME/.ssh/config"

  molt_info "Liberator complete: ssh"
}

ssh_verify() {
  local errors=0

  if ! _ssh_find_key &>/dev/null; then
    molt_error "VERIFY FAIL: no SSH key found"
    errors=1
  fi

  if [[ -L "$HOME/.ssh/config" ]]; then
    molt_error "VERIFY FAIL: ~/.ssh/config is a symlink (sshd requires regular files)"
    errors=1
  elif [[ -f "$HOME/.ssh/config.molt-rendered" ]]; then
    local provenance
    provenance="$(cat "$HOME/.ssh/config.molt-rendered")"
    molt_info "Verified: ~/.ssh/config is rendered ($provenance)"
  elif [[ -f "$HOME/.ssh/config" ]]; then
    # shellcheck disable=SC2088
    molt_warn "~/.ssh/config exists but is not molt-managed"
  else
    molt_error "VERIFY FAIL: ~/.ssh/config not found"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: ssh liberator is fully operational"
  fi
  return $errors
}
