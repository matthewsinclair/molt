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

# The instance config.d fragments in the user repo $1, as a sorted list (empty
# if none, or there is no repo).
#
# These are inputs to the rendered ~/.ssh/config, so they belong in the digest.
# Adding a fragment changes neither config.tmpl nor vars.sh, so without this
# ssh_check passes, ssh_install never runs, and the new fragment simply never
# lands -- which is what happened on gyges. Editing one has the same shape and
# is the six-month drift seen on rhadamanth.
_ssh_fragments() {
  local config_d
  [[ -n "$1" ]] || return 0
  config_d="$(molt_instance_file ssh/config.d)" || return 1
  [[ -d "$config_d" ]] || return 0
  local f
  # An if, not an &&: the loop's status is its last command's, and an
  # unmatched glob or a last entry that is not a file would fail the pipeline.
  for f in "$config_d"/*.conf; do
    if [[ -f "$f" ]]; then printf '%s\n' "$f"; fi
  done | sort
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

# Why the ssh config of the user repo $1, with $2 config.d fragments, cannot
# be installed, or nothing when it can. ~/.ssh/config is rendered from
# config/ssh/config.tmpl, the one way molt writes it. A repo with no ssh config
# is allowed, and the liberator then manages only the key, unless it declares
# fragments: a fragment declared but not applied is a sleeve that is not as
# declared. A static config/ssh/config is refused, fragments or none: molt
# would link it, and ssh, this liberator's check and its verify all refuse a
# linked ~/.ssh/config, so the sleeve never settled, and fragments went
# through the link into the user repo (issue 0027). As config.tmpl it renders
# as it stands, since only MOLT_* variables are substituted. Check, install
# and verify all ask here.
_ssh_config_fault() {
  local user_repo="$1" n="$2"
  [[ -n "$user_repo" && ! -f "$user_repo/config/ssh/config.tmpl" ]] || return 0
  if [[ -f "$user_repo/config/ssh/config" ]]; then
    local why="ssh: config/ssh/config is static, and ssh refuses ~/.ssh/config as the link molt would make of it: rename it config/ssh/config.tmpl, which renders it as it stands"
    if [[ "$n" -gt 0 ]]; then
      why="$why; $n config.d fragment(s) were not applied"
    fi
    echo "$why"
  elif [[ "$n" -gt 0 ]]; then
    echo "ssh: config.d fragments need config/ssh/config.tmpl; the user repo has no ssh config, so $n fragment(s) were not applied"
  fi
  return 0
}

# What check, install and verify each read before they look at ~/.ssh/config,
# read here once for them all: _SSH_FRAGS, this host's config.d fragments in
# sorted order, and _SSH_FAULT, why the ssh config of the user repo $1 cannot
# be installed, or empty when it can. File-scoped rather than printed: a $()
# would keep the array in its subshell, and bash 3.2 has no nameref.
_ssh_inputs() {
  local user_repo="$1" list f
  _SSH_FRAGS=()
  _SSH_FAULT=""
  if ! list="$(_ssh_fragments "$user_repo")"; then
    _SSH_FAULT="ssh: this host gives no hostname, so its config.d fragments cannot be found"
    return 0
  fi
  while IFS= read -r f; do [[ -n "$f" ]] && _SSH_FRAGS+=("$f"); done <<< "$list"
  _SSH_FAULT="$(_ssh_config_fault "$user_repo" "${#_SSH_FRAGS[@]}")"
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

  _ssh_inputs "$user_repo"
  if [[ -n "$_SSH_FAULT" ]]; then
    molt_info "$_SSH_FAULT"
    ok=1
  fi

  if [[ -n "$user_repo" ]]; then
    if [[ -f "$user_repo/config/ssh/config.tmpl" ]]; then
      if [[ -L "$HOME/.ssh/config" ]]; then
        molt_info "ssh: ~/.ssh/config is a symlink (sshd requires regular files)"
        ok=1
      elif molt_config_stale "config/ssh/config" "$HOME/.ssh/config" \
             ${_SSH_FRAGS+"${_SSH_FRAGS[@]}"}; then
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

  # Render the config from the user repo's template, when it has one
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  _ssh_inputs "$user_repo"
  if [[ -n "$_SSH_FAULT" ]]; then
    molt_error "$_SSH_FAULT"
    return 1
  fi
  local template="$user_repo/config/ssh/config.tmpl"
  if [[ -f "$template" ]]; then
    # A refused render stops the install here, with the config and its
    # sidecar as they were, so ssh_check goes on calling it stale.
    _ssh_render "$template" "$HOME/.ssh/config" ${_SSH_FRAGS+"${_SSH_FRAGS[@]}"} || return 1
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

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  _ssh_inputs "$user_repo"
  if [[ -n "$_SSH_FAULT" ]]; then
    molt_error "VERIFY FAIL: $_SSH_FAULT"
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
  elif [[ -f "$user_repo/config/ssh/config.tmpl" ]]; then
    # A repo with no ssh config leaves ~/.ssh/config alone, as check and
    # install do.
    molt_error "VERIFY FAIL: ~/.ssh/config not found"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: ssh liberator is fully operational"
  fi
  return $errors
}
