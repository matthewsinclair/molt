#!/usr/bin/env bash
# dev-tools.sh — Liberator: CLI tools and runtime managers
# Frees you from bare-bones coreutils.

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
  # Verify key CLI tools are present
  local missing=()
  for cmd in jq tree rg fzf curl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    molt_error "Missing CLI tools: ${missing[*]}"
    molt_error "Install them (eg apt install jq tree ripgrep fd-find fzf, brew install jq tree ripgrep fd fzf) then re-run."
    return 1
  fi

  # Verify mise is installed
  if ! command -v mise &>/dev/null; then
    molt_error "mise not found. Install it (https://mise.run) then re-run."
    return 1
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
