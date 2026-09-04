#!/usr/bin/env bash
# claude.sh — Liberator: Claude Code configuration
# Frees you from re-teaching every sleeve the same keybindings.

# Only keybindings.json is managed. The rest of ~/.claude is machine-local
# state -- sessions, transcripts, project history, credentials -- and must not
# be linked into a shared repo.
_claude_managed_files() {
  echo "keybindings.json"
}

claude_check() {
  local ok=0

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0

  local cf
  for cf in $(_claude_managed_files); do
    [[ -f "$user_repo/config/claude/$cf" ]] || continue
    if ! molt_link_healthy "$HOME/.claude/$cf"; then
      molt_info "claude: ~/.claude/${cf} $(molt_link_fault "$HOME/.claude/$cf")"
      ok=1
    fi
  done

  return $ok
}

claude_install() {
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  # ~/.claude is created by Claude Code itself, but a sleeve may be resleeved
  # before Claude Code has ever run on it.
  mkdir -p "$HOME/.claude"

  local cf linked=0
  for cf in $(_claude_managed_files); do
    if [[ -f "$user_repo/config/claude/$cf" ]]; then
      molt_link "$user_repo/config/claude/$cf" "$HOME/.claude/$cf"
      linked=1
    fi
  done

  if [[ $linked -eq 0 ]]; then
    molt_warn "claude: nothing to link -- $user_repo/config/claude/ has no managed files"
  fi

  molt_info "Liberator complete: claude"
}

claude_verify() {
  local errors=0

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0

  local cf
  for cf in $(_claude_managed_files); do
    [[ -f "$user_repo/config/claude/$cf" ]] || continue
    if ! molt_link_healthy "$HOME/.claude/$cf"; then
      molt_error "VERIFY FAIL: ~/.claude/${cf} $(molt_link_fault "$HOME/.claude/$cf")"
      errors=1
    fi
  done

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: claude liberator is fully operational"
  fi
  return $errors
}
