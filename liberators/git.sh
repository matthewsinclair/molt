#!/usr/bin/env bash
# git.sh — Liberator: version control
# Frees you from unconfigured git.

git_check() {
  local ok=0

  if ! command -v git &>/dev/null; then
    molt_info "git: not installed"
    return 1
  fi

  if ! command -v git-lfs &>/dev/null; then
    molt_info "git: git-lfs not installed"
    ok=1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ ! -L "$HOME/.gitconfig" ]]; then
    molt_info "git: ~/.gitconfig is not a symlink"
    ok=1
  fi

  return $ok
}

git_install() {
  if ! command -v git &>/dev/null; then
    molt_error "git not found. Install it (eg apt install git, xcode-select --install) then re-run."
    return 1
  fi

  if ! command -v git-lfs &>/dev/null; then
    molt_error "git-lfs not found. Install it (eg apt install git-lfs, brew install git-lfs) then re-run."
    return 1
  fi

  # Link config
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link "$user_repo/config/git/gitconfig" "$HOME/.gitconfig"

  if [[ -f "$user_repo/config/git/gitignore_global" ]]; then
    molt_link "$user_repo/config/git/gitignore_global" "$HOME/.gitignore_global"
  fi

  if [[ -f "$user_repo/config/git/gitconfig_matthewsinclair" ]]; then
    molt_link "$user_repo/config/git/gitconfig_matthewsinclair" "$HOME/.gitconfig_matthewsinclair"
  fi

  molt_info "Liberator complete: git"
}

git_verify() {
  local errors=0

  if ! command -v git &>/dev/null; then
    molt_error "VERIFY FAIL: git not installed"
    errors=1
  fi

  if ! command -v git-lfs &>/dev/null; then
    molt_error "VERIFY FAIL: git-lfs not installed"
    errors=1
  fi

  if [[ ! -L "$HOME/.gitconfig" ]]; then
    molt_error "VERIFY FAIL: ~/.gitconfig not symlinked"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: git liberator is fully operational"
  fi
  return $errors
}
