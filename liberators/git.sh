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
  local platform
  platform="$(molt_platform)"

  if ! command -v git &>/dev/null; then
    case "$platform" in
      linux)
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y git ;;
          fedora|rhel|centos) sudo dnf install -y git ;;
          arch) sudo pacman -S --noconfirm git ;;
          *) molt_error "Unsupported distro: $distro"; return 1 ;;
        esac
        ;;
      macos)
        molt_info "git ships with macOS (Xcode CLT)"
        ;;
    esac
  fi

  # Install git-lfs
  if ! command -v git-lfs &>/dev/null; then
    case "$platform" in
      linux)
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y git-lfs ;;
          fedora|rhel|centos) sudo dnf install -y git-lfs ;;
          arch) sudo pacman -S --noconfirm git-lfs ;;
        esac
        ;;
      macos) brew install git-lfs ;;
    esac
    git lfs install
  fi

  # Link config
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  molt_link "$user_repo/config/git/gitconfig" "$HOME/.gitconfig"

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
