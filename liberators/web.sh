#!/usr/bin/env bash
# web.sh — Liberator: web scraper for LLMs
# Frees you from copy-pasting web content.

_web_find_repo() {
  local web_dir="${MOLT_OPT_DIR}/web"
  if [[ -d "$web_dir" ]] && [[ -f "$web_dir/web" ]]; then
    echo "$web_dir"
    return 0
  fi
  return 1
}

web_repo() { _web_find_repo; }
web_repo_git_commands() { echo "pull status log diff fetch"; }

web_check() {
  local ok=0

  # Is the repo present?
  if ! _web_find_repo &>/dev/null; then
    molt_info "web: repo not found"
    return 1
  fi

  # Is web linked into ~/bin?
  if [[ ! -L "$MOLT_LOCAL_BIN/web" ]]; then
    molt_info "web: not linked in ~/bin"
    ok=1
  fi

  return $ok
}

web_install() {
  local repo
  if ! repo="$(_web_find_repo)"; then
    molt_error "web repo not found at: ${MOLT_OPT_DIR}/web"
    molt_error "Clone it: git clone <web-repo-url> ${MOLT_OPT_DIR}/web"
    return 1
  fi

  molt_info "Found web at: $repo"

  # Ensure ~/bin exists
  mkdir -p "$MOLT_LOCAL_BIN"

  # Link the web binary into ~/bin
  molt_link "$repo/web" "$MOLT_LOCAL_BIN/web"

  molt_info "Liberator complete: web"
}

web_verify() {
  local errors=0

  if ! _web_find_repo &>/dev/null; then
    molt_error "VERIFY FAIL: web repo not found"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/web" ]]; then
    molt_error "VERIFY FAIL: web not linked in ~/bin"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: web liberator is fully operational"
  fi
  return $errors
}

web_upgrade() {
  local repo
  if ! repo="$(_web_find_repo)"; then
    molt_error "web repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling web repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "web repo updated."
  else
    molt_warn "web pull skipped (not on tracking branch or already up-to-date)."
  fi
}
