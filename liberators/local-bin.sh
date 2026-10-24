#!/usr/bin/env bash
# local-bin.sh — Liberator: local bin directory
# Frees you from scattering executables.
#
# $MOLT_LOCAL_BIN/molt is the switch between the dev, opt and brew trees
# (ST0008), and molt use is what flips it. This liberator does not choose: a
# link to any tree's bin/molt is healthy, and install makes one, to the running
# tree, only when there is none to keep. Before, install linked it to whichever
# tree was running, so a resleeve from the checkout flipped an opt sleeve back
# to dev.

local-bin_check() {
  local ok=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "local-bin: $MOLT_LOCAL_BIN does not exist"
    ok=1
  fi

  # PATH is zsh's responsibility (via path_add in .zshrc), not the liberator's.
  # Only log at debug level — not a failure condition.
  if [[ ":$PATH:" != *":$MOLT_LOCAL_BIN:"* ]]; then
    molt_debug "local-bin: $MOLT_LOCAL_BIN is not on PATH (expected if not running from zsh)"
  fi

  local served
  if ! served="$(molt_served_tree)"; then
    molt_info "local-bin: $served"
    ok=1
  fi

  return $ok
}

local-bin_install() {
  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "Creating $MOLT_LOCAL_BIN..."
    mkdir -p "$MOLT_LOCAL_BIN" || { molt_error "local-bin: $MOLT_LOCAL_BIN could not be made"; return 1; }
  fi

  # A link to any tree is the sleeve's choice, made with molt use, and kept.
  local fault
  if ! fault="$(molt_served_tree)"; then
    # What is replaced is named; molt_link backs up a file that is not a link.
    if [[ -e "$MOLT_LOCAL_BIN/molt" || -L "$MOLT_LOCAL_BIN/molt" ]]; then
      molt_info "local-bin: relinking to the running tree, since $fault"
    fi
    molt_link "$MOLT_ROOT/bin/molt" "$MOLT_LOCAL_BIN/molt" || return 1
  fi

  molt_info "Liberator complete: local-bin"
}

local-bin_verify() {
  local errors=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_error "VERIFY FAIL: $MOLT_LOCAL_BIN does not exist"
    errors=1
  fi

  local served
  if ! served="$(molt_served_tree)"; then
    molt_error "VERIFY FAIL: $served"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: local-bin liberator is fully operational; $(molt_tilde "$MOLT_LOCAL_BIN/molt") serves $(molt_version_line "$served")"
  fi
  return $errors
}
