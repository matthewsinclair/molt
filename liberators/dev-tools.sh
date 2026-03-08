#!/usr/bin/env bash
# dev-tools.sh — Liberator: CLI tools and runtime managers
# Frees you from bare-bones coreutils.

# Base packages needed on any Linux sleeve
_DEVTOOLS_APT_PACKAGES=(
  htop jq tree bat ripgrep fd-find fzf
  wl-clipboard curl wget unzip
  build-essential cmake
)

dev-tools_check() {
  local ok=0

  # Check key CLI tools
  for cmd in jq tree rg fzf curl; do
    if ! command -v "$cmd" &>/dev/null; then
      molt_info "dev-tools: $cmd not installed"
      ok=1
    fi
  done

  # Check mise
  if ! command -v mise &>/dev/null; then
    molt_info "dev-tools: mise not installed"
    ok=1
  fi

  return $ok
}

dev-tools_install() {
  local platform
  platform="$(molt_platform)"

  case "$platform" in
    linux)
      local distro
      distro="$(molt_distro)"
      case "$distro" in
        ubuntu|debian)
          molt_info "Installing CLI tools via apt..."
          sudo apt update
          sudo apt install -y "${_DEVTOOLS_APT_PACKAGES[@]}"
          ;;
        fedora|rhel|centos)
          molt_info "Installing CLI tools via dnf..."
          sudo dnf install -y htop jq tree bat ripgrep fd-find fzf \
            wl-clipboard curl wget unzip gcc make cmake
          ;;
        arch)
          molt_info "Installing CLI tools via pacman..."
          sudo pacman -S --noconfirm htop jq tree bat ripgrep fd fzf \
            wl-clipboard curl wget unzip base-devel cmake
          ;;
        *)
          molt_error "Unsupported distro: $distro"
          return 1
          ;;
      esac
      ;;
    macos)
      molt_info "Installing CLI tools via Homebrew..."
      molt_require brew || return 1
      brew install htop jq tree bat ripgrep fd fzf curl wget
      ;;
  esac

  # Install mise
  if ! command -v mise &>/dev/null; then
    molt_info "Installing mise..."
    curl https://mise.run | sh
  fi

  molt_info "Liberator complete: dev-tools"
}

dev-tools_verify() {
  local errors=0

  for cmd in jq tree rg fzf curl; do
    if ! command -v "$cmd" &>/dev/null; then
      molt_error "VERIFY FAIL: $cmd not installed"
      errors=1
    fi
  done

  if ! command -v mise &>/dev/null; then
    molt_error "VERIFY FAIL: mise not installed"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: dev-tools liberator is fully operational"
  fi
  return $errors
}
