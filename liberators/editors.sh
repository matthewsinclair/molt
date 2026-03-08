#!/usr/bin/env bash
# editors.sh — Liberator: Doom Emacs + LazyVim
# Frees you from nano.

editors_check() {
  local ok=0

  if ! command -v emacs &>/dev/null; then
    molt_info "editors: emacs not installed"
    ok=1
  fi

  if ! command -v nvim &>/dev/null; then
    molt_info "editors: neovim not installed"
    ok=1
  fi

  # Doom Emacs installed?
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "editors: Doom Emacs not installed"
    ok=1
  fi

  # Doom config linked?
  if [[ ! -L "$HOME/.config/doom" ]]; then
    molt_info "editors: ~/.config/doom is not a symlink"
    ok=1
  fi

  # LazyVim installed?
  if [[ ! -f "$HOME/.config/nvim/init.lua" ]]; then
    molt_info "editors: LazyVim not installed"
    ok=1
  fi

  return $ok
}

editors_install() {
  local platform
  platform="$(molt_platform)"

  # Install emacs
  if ! command -v emacs &>/dev/null; then
    case "$platform" in
      linux)
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y emacs ;;
          fedora|rhel|centos) sudo dnf install -y emacs ;;
          arch) sudo pacman -S --noconfirm emacs ;;
          *) molt_error "Unsupported distro: $distro"; return 1 ;;
        esac
        ;;
      macos)
        brew install emacs-plus@29
        ;;
    esac
  fi

  # Install neovim
  if ! command -v nvim &>/dev/null; then
    case "$platform" in
      linux)
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y neovim ;;
          fedora|rhel|centos) sudo dnf install -y neovim ;;
          arch) sudo pacman -S --noconfirm neovim ;;
        esac
        ;;
      macos) brew install neovim ;;
    esac
  fi

  # Install Doom Emacs
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "Installing Doom Emacs..."
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
  fi

  # Link Doom config from user repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  if [[ -d "$user_repo/config/doom" ]]; then
    molt_link "$user_repo/config/doom" "$HOME/.config/doom"
  fi

  # Run doom install/sync if doom config is present
  if [[ -f "$HOME/.config/emacs/bin/doom" ]] && [[ -L "$HOME/.config/doom" ]]; then
    if [[ ! -d "$HOME/.config/emacs/.local" ]]; then
      molt_info "Running doom install..."
      "$HOME/.config/emacs/bin/doom" install --no-config
    else
      molt_info "Running doom sync..."
      "$HOME/.config/emacs/bin/doom" sync
    fi
  fi

  # Install LazyVim
  if [[ ! -f "$HOME/.config/nvim/init.lua" ]]; then
    molt_info "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
  fi

  molt_info "Liberator complete: editors"
}

editors_verify() {
  local errors=0

  if ! command -v emacs &>/dev/null; then
    molt_error "VERIFY FAIL: emacs not installed"
    errors=1
  fi

  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_error "VERIFY FAIL: Doom Emacs not installed"
    errors=1
  fi

  if [[ ! -L "$HOME/.config/doom" ]]; then
    molt_error "VERIFY FAIL: ~/.config/doom not symlinked"
    errors=1
  fi

  if ! command -v nvim &>/dev/null; then
    molt_error "VERIFY FAIL: neovim not installed"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: editors liberator is fully operational"
  fi
  return $errors
}
