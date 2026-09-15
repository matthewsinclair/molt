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

# Names why a target is not linked to its source. molt_link_fault calls a
# resolving link to the wrong place "resolves", which reads as healthy.
_git_link_fault() {
  local target="$1"
  if molt_link_healthy "$target"; then
    echo "points at $(readlink "$target"), not the user repo"
  else
    molt_link_fault "$target"
  fi
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

  local user_repo links source target
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    links="$(_git_links "$user_repo")"
    while IFS=$'\t' read -r source target; do
      if ! molt_link_points_to "$target" "$source"; then
        molt_info "git: "'~'"${target#"$HOME"} $(_git_link_fault "$target")"
        ok=1
      fi
    done <<< "$links"
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
  local user_repo links source target
  user_repo="$(molt_find_user_repo)" || return 1
  links="$(_git_links "$user_repo")"
  while IFS=$'\t' read -r source target; do
    molt_link "$source" "$target" || return 1
  done <<< "$links"

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

  local user_repo links source target
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -z "$user_repo" ]]; then
    molt_error "VERIFY FAIL: user config repo not found, so no git config link was checked"
    errors=1
  else
    links="$(_git_links "$user_repo")"
    while IFS=$'\t' read -r source target; do
      if ! molt_link_points_to "$target" "$source"; then
        molt_error "VERIFY FAIL: "'~'"${target#"$HOME"} $(_git_link_fault "$target")"
        errors=1
      fi
    done <<< "$links"
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: git liberator is fully operational"
  fi
  return $errors
}
