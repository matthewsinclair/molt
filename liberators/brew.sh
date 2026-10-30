#!/usr/bin/env bash
# brew.sh — Liberator: Homebrew lifecycle
# Frees you from stale packages, wherever brew is on PATH: Homebrew on macOS,
# Linuxbrew on Linux. It was macOS only, so nothing upgraded kovacs's
# Linuxbrew (issue 0077).

brew_check() {
  if ! command -v brew &>/dev/null; then
    molt_info "brew: Homebrew not installed"
    return 1
  fi

  return 0
}

brew_install() {
  if ! command -v brew &>/dev/null; then
    molt_error "Homebrew not found. Install it (https://brew.sh) then re-run."
    return 1
  fi

  molt_info "Liberator complete: brew"
}

brew_verify() {
  local errors=0

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

  # Each step that fails is named and fails the hook; the rest still run, so
  # one failed step does not leave the others undone (issue 0052).
  local failed=""
  molt_info "Updating Homebrew formulae..."
  brew update || failed+="${failed:+, }brew update"

  molt_info "Upgrading Homebrew packages..."
  brew upgrade || failed+="${failed:+, }brew upgrade"

  # Casks are macOS's alone (issue 0077).
  if [[ "$(molt_platform)" == "macos" ]]; then
    molt_info "Upgrading Homebrew casks..."
    brew upgrade --cask || failed+="${failed:+, }brew upgrade --cask"
  fi

  molt_info "Cleaning up old versions..."
  brew cleanup -s || failed+="${failed:+, }brew cleanup -s"

  molt_info "Running brew doctor..."
  brew doctor || molt_warn "brew doctor reported warnings (review above)"

  molt_info "Checking for missing dependencies..."
  brew missing || true

  # Update global npm packages if npm is installed
  if command -v npm &>/dev/null; then
    molt_info "Updating global npm packages..."
    npm update --location=global || molt_warn "npm global update had warnings"
  fi

  if [[ -n "$failed" ]]; then
    molt_error "Homebrew maintenance failed: $failed (above)"
    return 1
  fi
  molt_info "Homebrew maintenance complete."
}
