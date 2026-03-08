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

  # Check if config is linked
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/ssh/config" ]]; then
    if [[ ! -L "$HOME/.ssh/config" ]]; then
      molt_info "ssh: ~/.ssh/config is not a symlink"
      ok=1
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

  # Link config from user repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  if [[ -f "$user_repo/config/ssh/config" ]]; then
    molt_link "$user_repo/config/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$user_repo/config/ssh/config"
  fi

  molt_info "Liberator complete: ssh"
}

ssh_verify() {
  local errors=0

  if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    molt_error "VERIFY FAIL: no SSH key found"
    errors=1
  fi

  if [[ ! -L "$HOME/.ssh/config" ]]; then
    molt_error "VERIFY FAIL: ~/.ssh/config not symlinked"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: ssh liberator is fully operational"
  fi
  return $errors
}
