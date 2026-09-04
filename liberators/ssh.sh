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

# The instance config.d fragments, as a sorted list (empty if none).
#
# These are inputs to the rendered ~/.ssh/config, so they belong in the digest.
# Adding a fragment changes neither config.tmpl nor vars.sh, so without this
# ssh_check passes, ssh_install never runs, and the new fragment simply never
# lands -- which is what happened on gyges. Editing one has the same shape and
# is the six-month drift seen on rhadamanth.
_ssh_fragments() {
  local user_repo hostname config_d
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  hostname="$(hostname -s 2>/dev/null || hostname)"
  config_d="$user_repo/instances/$hostname/ssh/config.d"
  [[ -d "$config_d" ]] || return 0
  local f
  for f in "$config_d"/*.conf; do
    [[ -f "$f" ]] && printf '%s\n' "$f"
  done | sort
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

  # Read into an array rather than splitting a command substitution: a fragment
  # path can contain spaces, and word splitting would silently pass fragments.
  local _ssh_frags=() _f
  while IFS= read -r _f; do [[ -n "$_f" ]] && _ssh_frags+=("$_f"); done \
    < <(_ssh_fragments)

  if [[ -n "$user_repo" ]]; then
    if [[ -f "$user_repo/config/ssh/config.tmpl" ]] || [[ -f "$user_repo/config/ssh/config" ]]; then
      if [[ -L "$HOME/.ssh/config" ]]; then
        molt_info "ssh: ~/.ssh/config is a symlink (sshd requires regular files)"
        ok=1
      elif molt_config_stale "config/ssh/config" "$HOME/.ssh/config" \
             ${_ssh_frags+"${_ssh_frags[@]}"}; then
        molt_info "ssh: ~/.ssh/config differs from its template, instance vars or config.d fragments — re-rendering"
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

  # THE RENDER AND THE APPEND MUST STAY IN THIS FUNCTION, IN THIS ORDER.
  # molt_render preserves only the region ABOVE @@MOLT:BEGIN@@; fragments are
  # appended BELOW @@MOLT:END@@, so every render wipes every fragment. That is
  # safe only because the re-append happens here, immediately after. Separating
  # them -- or rendering from anywhere else -- silently drops every fragment on
  # the next template change. Flagged by gyges.
  #
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

  # Re-stamp the sidecar so its digest covers the fragments too. Without this
  # the check (which digests fragments) and the sidecar (which did not) never
  # agree, and ssh reinstalls on every run.
  local _frags=() _f
  while IFS= read -r _f; do [[ -n "$_f" ]] && _frags+=("$_f"); done < <(_ssh_fragments)
  if [[ -f "$user_repo/config/ssh/config.tmpl" ]]; then
    molt_config_record_digest "$HOME/.ssh/config" \
      "$user_repo/config/ssh/config.tmpl" ${_frags+"${_frags[@]}"}
  fi

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
