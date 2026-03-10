#!/usr/bin/env bash
# pplr.sh — Liberator: Pplr people/contacts manager
# Frees you from losing track of people.

_pplr_find_repo() {
  if [[ -d "${MOLT_PPLR_HOME}/bin" ]] && [[ -f "${MOLT_PPLR_HOME}/bin/pplr" ]]; then
    echo "${MOLT_PPLR_HOME}"
    return 0
  fi
  return 1
}

pplr_repo() { _pplr_find_repo; }
pplr_repo_git_commands() { echo "pull status log diff fetch"; }

pplr_check() {
  local ok=0

  if ! _pplr_find_repo &>/dev/null; then
    molt_info "pplr: repo not found"
    return 1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/pplr" ]]; then
    molt_info "pplr: not linked in ~/bin"
    ok=1
  fi

  return $ok
}

pplr_install() {
  local repo
  if ! repo="$(_pplr_find_repo)"; then
    molt_error "Pplr repo not found at: ${MOLT_PPLR_HOME}"
    molt_error "Clone it: git clone <pplr-repo-url> ${MOLT_PPLR_HOME}"
    return 1
  fi

  molt_info "Found Pplr at: $repo"

  mkdir -p "$MOLT_LOCAL_BIN"

  # Link pplr dispatcher and all sub-commands into ~/bin
  for f in "$repo/bin/"*; do
    [[ -f "$f" ]] || [[ -L "$f" ]] || continue
    local name
    name="$(basename "$f")"
    molt_link "$f" "$MOLT_LOCAL_BIN/$name"
  done

  molt_info "Liberator complete: pplr"
}

pplr_verify() {
  local errors=0

  if ! _pplr_find_repo &>/dev/null; then
    molt_error "VERIFY FAIL: Pplr repo not found"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/pplr" ]]; then
    molt_error "VERIFY FAIL: pplr not linked in ~/bin"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: pplr liberator is fully operational"
  fi
  return $errors
}

pplr_upgrade() {
  local repo
  if ! repo="$(_pplr_find_repo)"; then
    molt_error "Pplr repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling Pplr repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "Pplr repo updated."
  else
    molt_warn "Pplr pull skipped (not on tracking branch or already up-to-date)."
  fi
}
