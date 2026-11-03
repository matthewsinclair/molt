#!/usr/bin/env bash
# mise.sh — Liberator: mise
# Frees you from installing each language runtime by hand: mise manages them,
# per project or globally, apart from the system's packages.
#
# Off on every sleeve (hv, 3 Nov 2026): both templates name it with
# enabled = false, and turning it on is a molt.toml change, its [[liberator]]
# entry set to enabled = true. It moved out of dev-tools with its behaviour
# unchanged (issue 0082): check and verify look for mise on PATH, and install
# installs nothing, pointing at mise's own installer.

mise_check() {
  if ! command -v mise &>/dev/null; then
    molt_info "mise: not installed"
    return 1
  fi
}

mise_install() {
  if ! command -v mise &>/dev/null; then
    molt_error "mise not found. Install it (https://mise.run) then re-run."
    return 1
  fi
  molt_info "Liberator complete: mise"
}

mise_verify() {
  if ! command -v mise &>/dev/null; then
    molt_error "VERIFY FAIL: mise not installed"
    return 1
  fi
  molt_info "Verified: mise liberator is fully operational"
}
