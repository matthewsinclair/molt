#!/usr/bin/env bash
# dev-tools.sh — Liberator: CLI tools
# Frees you from bare-bones coreutils: jq, tree, rg, fzf and curl. It checks for
# them and installs none; install names the package manager's line. mise, which
# it once required, is its own liberator, off on every sleeve (issue 0082).

# The CLI tools check, install and verify all look for, named once.
MOLT_DEV_TOOLS=(jq tree rg fzf curl)

dev-tools_check() {
  local ok=0 cmd

  for cmd in "${MOLT_DEV_TOOLS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      molt_info "dev-tools: $cmd not installed"
      ok=1
    fi
  done

  return $ok
}

dev-tools_install() {
  local missing=() cmd
  for cmd in "${MOLT_DEV_TOOLS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    molt_error "Missing CLI tools: ${missing[*]}"
    molt_error "Install them (eg apt install jq tree ripgrep fzf curl, brew install jq tree ripgrep fzf curl) then re-run."
    return 1
  fi

  molt_info "Liberator complete: dev-tools"
}

dev-tools_verify() {
  local errors=0 cmd

  for cmd in "${MOLT_DEV_TOOLS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      molt_error "VERIFY FAIL: $cmd not installed"
      errors=1
    fi
  done

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: dev-tools liberator is fully operational"
  fi
  return $errors
}
