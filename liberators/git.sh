#!/usr/bin/env bash
# git.sh — Liberator: version control
# Frees you from unconfigured git.

# Every link git_install makes, one "source<TAB>target" line each. check,
# install and verify all read this one list. When install kept its own list and
# check tested only ~/.gitconfig, ~/.gitignore_global sat as a stale regular
# file on two sleeves and every run reported git ok (issue 0006).
_git_links() {
  local user_repo="$1" identity
  printf '%s\t%s\n' "$user_repo/config/git/gitconfig" "$HOME/.gitconfig"

  if [[ -f "$user_repo/config/git/gitignore_global" ]]; then
    printf '%s\t%s\n' "$user_repo/config/git/gitignore_global" "$HOME/.gitignore_global"
  fi

  # The user's gitconfig pulls identity includes in via
  # [include] path = ~/.gitconfig_<name>. Glob so we never hardcode a specific
  # user's identity filename.
  for identity in "$user_repo"/config/git/gitconfig_*; do
    [[ -e "$identity" ]] || continue
    printf '%s\t%s\n' "$identity" "$HOME/.$(basename "$identity")"
  done
}

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
  if [[ -n "$user_repo" ]]; then
    molt_report_link_faults molt_info "git: " "$(_git_links "$user_repo")" || ok=1
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
  molt_link_all "$(_git_links "$user_repo")" || return 1

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

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -z "$user_repo" ]]; then
    molt_error "VERIFY FAIL: user config repo not found, so no git config link was checked"
    errors=1
  else
    molt_report_link_faults molt_error "VERIFY FAIL: " "$(_git_links "$user_repo")" || errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: git liberator is fully operational"
  fi
  return $errors
}
