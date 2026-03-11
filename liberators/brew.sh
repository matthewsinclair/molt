#!/usr/bin/env bash
# brew.sh — Liberator: Homebrew lifecycle
# Frees you from stale packages.

brew_check() {
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_info "brew: not applicable (macOS only)"
    return 1
  fi

  if ! command -v brew &>/dev/null; then
    molt_info "brew: Homebrew not installed"
    return 1
  fi

  return 0
}

brew_install() {
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_error "brew liberator is macOS only"
    return 1
  fi

  if ! command -v brew &>/dev/null; then
    molt_error "Homebrew not found. Install it (https://brew.sh) then re-run."
    return 1
  fi

  molt_info "Liberator complete: brew"
}

brew_verify() {
  local errors=0

  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_error "VERIFY FAIL: brew is macOS only"
    return 1
  fi

  if ! command -v brew &>/dev/null; then
    molt_error "VERIFY FAIL: brew not installed"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: brew liberator is fully operational"
  fi
  return $errors
}

brew_maintain() {
  if ! command -v brew &>/dev/null; then
    molt_error "Homebrew not found — cannot maintain"
    return 1
  fi

  molt_info "Updating Homebrew formulae..."
  brew update

  molt_info "Upgrading Homebrew packages..."
  brew upgrade

  molt_info "Upgrading Homebrew casks..."
  brew upgrade --cask

  molt_info "Cleaning up old versions..."
  brew cleanup -s

  molt_info "Running brew doctor..."
  brew doctor || molt_warn "brew doctor reported warnings (review above)"

  molt_info "Checking for missing dependencies..."
  brew missing || true

  # Update global npm packages if npm is installed
  if command -v npm &>/dev/null; then
    molt_info "Updating global npm packages..."
    npm update --location=global || molt_warn "npm global update had warnings"
  fi

  molt_info "Homebrew maintenance complete."
}
