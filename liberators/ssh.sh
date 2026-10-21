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
  hostname="$(molt_hostname)" || return 1
  config_d="$user_repo/instances/$hostname/ssh/config.d"
  [[ -d "$config_d" ]] || return 0
  local f
  # An if, not an &&: the loop's status is its last command's, and an
  # unmatched glob or a last entry that is not a file would fail the pipeline.
  for f in "$config_d"/*.conf; do
    if [[ -f "$f" ]]; then printf '%s\n' "$f"; fi
  done | sort
}

# Whether the user repo has an ssh config, as a template or a static file. A
# repo without one is allowed, and the liberator then manages only the key, so
# check and install ask this one test and agree on it.
_ssh_config_present() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 1
  [[ -f "$user_repo/config/ssh/config.tmpl" ]] || [[ -f "$user_repo/config/ssh/config" ]]
}

# Renders the template $1 to $2 with the config.d fragments after it ($3...,
# in the sorted order _ssh_fragments gives), each under its sentinel line.
#
# THE WHOLE FILE IS BUILT BEFORE molt_render_place COMPARES IT. molt_render
# keeps only the region ABOVE @@MOLT:BEGIN@@, and a fragment appended to the
# placed file after the compare made every install differ from what was there:
# each one backed ~/.ssh/config up and warned it had been changed, and a hand
# edit read the same as molt's own fragments (issue 0024). The fragments are
# extra inputs, so the sidecar's digest covers them and ssh_check, which asks
# with the same list, reads the file current. The file is rebuilt whole each
# time, so a fragment lands once because the compare finds nothing to change,
# not because its sentinel is already there.
_ssh_render() {
  local template="$1" target="$2" tmp="${2}.molt-tmp"
  shift 2
  molt_render_tmp "$template" "$target" || return 1
  local fragment content
  for fragment in "$@"; do
    # Read before the sentinel is written: a fragment that cannot be read
    # would leave its sentinel with nothing under it.
    if ! content="$(cat "$fragment")"; then
      rm -f "$tmp"
      molt_error "ssh: config.d fragment $(basename "$fragment") cannot be read, so ~/.ssh/config was not rendered"
      return 1
    fi
    if ! printf '\n%s\n%s\n' "# --- molt config.d: $(basename "$fragment") ---" "$content" >> "$tmp"; then
      rm -f "$tmp"
      molt_error "ssh: config.d fragment $(basename "$fragment") could not be added to ~/.ssh/config, so it was not rendered"
      return 1
    fi
  done
  molt_render_place "$template" "$target" ${1+"$@"}
}

# Why the config.d fragments, $1 of them, cannot be applied, or nothing when
# they can: only a rendered config has a file of molt's own to put them in. A
# fragment declared but not applied is a sleeve that is not as declared, so
# check and install both ask here.
_ssh_fragments_fault() {
  local n="$1" user_repo
  [[ "$n" -gt 0 ]] || return 0
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" && ! -f "$user_repo/config/ssh/config.tmpl" ]] || return 0
  if [[ -f "$user_repo/config/ssh/config" ]]; then
    echo "ssh: config.d fragments need config/ssh/config.tmpl; config/ssh/config is static, so $n fragment(s) were not applied"
  else
    echo "ssh: config.d fragments need config/ssh/config.tmpl; the user repo has no ssh config, so $n fragment(s) were not applied"
  fi
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
  local _ssh_frags=() _f _list _fault
  if ! _list="$(_ssh_fragments)"; then
    molt_info "ssh: this host gives no hostname, so its config.d fragments cannot be found"
    return 1
  fi
  while IFS= read -r _f; do [[ -n "$_f" ]] && _ssh_frags+=("$_f"); done <<< "$_list"
  _fault="$(_ssh_fragments_fault "${#_ssh_frags[@]}")"
  if [[ -n "$_fault" ]]; then
    molt_info "$_fault"
    ok=1
  fi

  if [[ -n "$user_repo" ]]; then
    if _ssh_config_present; then
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
    email="$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(molt_hostname)")"
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
    molt_warn "New SSH key generated. Add public key to GitHub/remotes:"
    molt_warn "  cat ~/.ssh/id_ed25519.pub"
  else
    local existing_key
    existing_key="$(_ssh_find_key)"
    molt_info "SSH key found: $existing_key"
  fi

  # Install config from user repo (template or static), when it has one
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local list frags=() f fault
  if ! list="$(_ssh_fragments)"; then
    molt_error "ssh: this host gives no hostname, so its config.d fragments cannot be found"
    return 1
  fi
  while IFS= read -r f; do [[ -n "$f" ]] && frags+=("$f"); done <<< "$list"
  fault="$(_ssh_fragments_fault "${#frags[@]}")"
  if [[ -n "$fault" ]]; then
    molt_error "$fault"
    return 1
  fi
  local template="$user_repo/config/ssh/config.tmpl"
  if [[ -f "$template" ]]; then
    # A refused render stops the install here, with the config and its
    # sidecar as they were, so ssh_check goes on calling it stale.
    _ssh_render "$template" "$HOME/.ssh/config" ${frags+"${frags[@]}"} || return 1
  elif _ssh_config_present; then
    molt_install_config "config/ssh/config" "$HOME/.ssh/config" || return 1
  fi

  # ssh refuses a config that others can write, so a chmod that fails is an
  # install that failed.
  if [[ -f "$HOME/.ssh/config" ]] && ! chmod 600 "$HOME/.ssh/config"; then
    molt_error "ssh: ~/.ssh/config could not be made mode 600, which ssh requires"
    return 1
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
