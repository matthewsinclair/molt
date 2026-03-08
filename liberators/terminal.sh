#!/usr/bin/env bash
# terminal.sh — Liberator: terminal emulator
# Frees you from the default terminal.

terminal_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  case "$platform" in
    linux)
      if ! command -v alacritty &>/dev/null; then
        molt_info "terminal: Alacritty not installed"
        ok=1
      fi

      local user_repo
      user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
      if [[ -n "$user_repo" ]] && [[ ! -L "$HOME/.config/alacritty/alacritty.toml" ]]; then
        molt_info "terminal: Alacritty config not symlinked"
        ok=1
      fi
      ;;
    macos)
      # macOS uses native Terminal.app or user-installed terminal
      molt_debug "terminal: skipping on macOS"
      ;;
  esac

  return $ok
}

terminal_install() {
  local platform
  platform="$(molt_platform)"

  case "$platform" in
    linux)
      if ! command -v alacritty &>/dev/null; then
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y alacritty ;;
          fedora|rhel|centos) sudo dnf install -y alacritty ;;
          arch) sudo pacman -S --noconfirm alacritty ;;
          *) molt_error "Unsupported distro: $distro"; return 1 ;;
        esac
      fi

      local user_repo
      user_repo="$(molt_find_user_repo)" || return 1
      if [[ -f "$user_repo/config/alacritty/alacritty.toml" ]]; then
        mkdir -p "$HOME/.config/alacritty"
        molt_link "$user_repo/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
      fi
      ;;
    macos)
      molt_info "terminal: no terminal emulator to install on macOS"
      ;;
  esac

  molt_info "Liberator complete: terminal"
}

terminal_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" == "linux" ]]; then
    if ! command -v alacritty &>/dev/null; then
      molt_error "VERIFY FAIL: Alacritty not installed"
      errors=1
    fi

    if [[ ! -L "$HOME/.config/alacritty/alacritty.toml" ]]; then
      molt_error "VERIFY FAIL: Alacritty config not symlinked"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: terminal liberator is fully operational"
  fi
  return $errors
}
