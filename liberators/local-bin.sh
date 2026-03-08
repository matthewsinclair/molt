#!/usr/bin/env bash
# local-bin.sh — Liberator: local bin directory
# Frees you from scattering executables.

local-bin_check() {
  local ok=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "local-bin: $MOLT_LOCAL_BIN does not exist"
    ok=1
  fi

  # Check that local bin is on PATH
  if [[ ":$PATH:" != *":$MOLT_LOCAL_BIN:"* ]]; then
    molt_info "local-bin: $MOLT_LOCAL_BIN is not on PATH"
    ok=1
  fi

  # Check molt itself is linked
  if [[ ! -L "$MOLT_LOCAL_BIN/molt" ]]; then
    molt_info "local-bin: molt not linked in $MOLT_LOCAL_BIN"
    ok=1
  fi

  return $ok
}

local-bin_install() {
  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "Creating $MOLT_LOCAL_BIN..."
    mkdir -p "$MOLT_LOCAL_BIN"
  fi

  # Link molt CLI into local bin
  local molt_bin="${MOLT_ROOT:-}/bin/molt"
  if [[ -z "${MOLT_ROOT:-}" ]]; then
    molt_bin="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)/molt"
  fi

  if [[ -f "$molt_bin" ]]; then
    molt_link "$molt_bin" "$MOLT_LOCAL_BIN/molt"
  fi

  molt_info "Liberator complete: local-bin"
}

local-bin_verify() {
  local errors=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_error "VERIFY FAIL: $MOLT_LOCAL_BIN does not exist"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/molt" ]]; then
    molt_error "VERIFY FAIL: molt not linked in $MOLT_LOCAL_BIN"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: local-bin liberator is fully operational"
  fi
  return $errors
}
