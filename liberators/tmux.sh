#!/usr/bin/env bash
# tmux.sh — Liberator: terminal multiplexer
# Frees you from single-pane terminal life.

tmux_check() {
  local ok=0

  if ! command -v tmux &>/dev/null; then
    molt_info "tmux: not installed"
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ ! -L "$HOME/.tmux.conf" ]]; then
    molt_info "tmux: ~/.tmux.conf is not a symlink"
    ok=1
  fi

  return $ok
}

tmux_install() {
  if ! command -v tmux &>/dev/null; then
    molt_error "tmux not found. Install it (eg apt install tmux, brew install tmux) then re-run."
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link "$user_repo/config/tmux/tmux.conf" "$HOME/.tmux.conf"

  molt_info "Liberator complete: tmux"
}

tmux_verify() {
  local errors=0

  if ! command -v tmux &>/dev/null; then
    molt_error "VERIFY FAIL: tmux not installed"
    errors=1
  fi

  if [[ ! -L "$HOME/.tmux.conf" ]]; then
    molt_error "VERIFY FAIL: ~/.tmux.conf not symlinked"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: tmux liberator is fully operational"
  fi
  return $errors
}
