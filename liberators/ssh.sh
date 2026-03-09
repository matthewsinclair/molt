#!/usr/bin/env bash
# ssh.sh — Liberator: SSH configuration
# Frees you from typing full hostnames.

ssh_check() {
  local ok=0

  if ! command -v ssh &>/dev/null; then
    molt_info "ssh: not installed"
    return 1
  fi

  # Check if SSH key exists
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
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

  # Generate key if none exists
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    molt_info "Generating SSH key..."
    local email
    email="$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname)")"
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
    molt_warn "New SSH key generated. Add public key to GitHub/remotes:"
    molt_warn "  cat ~/.ssh/id_ed25519.pub"
  fi

  # Install config from user repo (template or static)
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  molt_install_config "config/ssh/config" "$HOME/.ssh/config"

  # Append instance-specific config.d fragments if any exist
  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"
  local config_d="$user_repo/instances/$hostname/ssh/config.d"
  if [[ -d "$config_d" ]]; then
    for fragment in "$config_d"/*.conf; do
      [[ -f "$fragment" ]] || continue
      molt_info "Appending SSH config fragment: $(basename "$fragment")"
      echo "" >> "$HOME/.ssh/config"
      echo "# --- molt config.d: $(basename "$fragment") ---" >> "$HOME/.ssh/config"
      cat "$fragment" >> "$HOME/.ssh/config"
    done
  fi

  chmod 600 "$HOME/.ssh/config"

  molt_info "Liberator complete: ssh"
}

ssh_verify() {
  local errors=0

  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
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
