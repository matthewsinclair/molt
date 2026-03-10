#!/usr/bin/env bash
# intent.sh — Liberator: Intent project management framework
# Frees you from unstructured project planning.

_intent_find_repo() {
  if [[ -d "${MOLT_INTENT_HOME}/bin" ]] && [[ -f "${MOLT_INTENT_HOME}/bin/intent" ]]; then
    echo "${MOLT_INTENT_HOME}"
    return 0
  fi
  return 1
}

intent_repo() { _intent_find_repo; }
intent_repo_remote() { echo "origin"; }
intent_repo_git_commands() { echo "pull status log diff fetch"; }

intent_check() {
  local ok=0

  if ! _intent_find_repo &>/dev/null; then
    molt_info "intent: repo not found"
    return 1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/intent" ]]; then
    molt_info "intent: not linked in ~/bin"
    ok=1
  fi

  return $ok
}

intent_install() {
  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_error "Intent repo not found at: ${MOLT_INTENT_HOME}"
    molt_error "Clone it: git clone <intent-repo-url> ${MOLT_INTENT_HOME}"
    return 1
  fi

  molt_info "Found Intent at: $repo"

  mkdir -p "$MOLT_LOCAL_BIN"

  # Link intent dispatcher and all sub-commands into ~/bin
  for f in "$repo/bin/"*; do
    [[ -f "$f" ]] || continue
    local name
    name="$(basename "$f")"
    molt_link "$f" "$MOLT_LOCAL_BIN/$name"
  done

  molt_info "Liberator complete: intent"
}

intent_verify() {
  local errors=0

  if ! _intent_find_repo &>/dev/null; then
    molt_error "VERIFY FAIL: Intent repo not found"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/intent" ]]; then
    molt_error "VERIFY FAIL: intent not linked in ~/bin"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: intent liberator is fully operational"
  fi
  return $errors
}

intent_upgrade() {
  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_error "Intent repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling Intent repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "Intent repo updated."
  else
    molt_warn "Intent pull skipped (not on tracking branch or already up-to-date)."
  fi
}
