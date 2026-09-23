#!/usr/bin/env bash
# intent.sh — Liberator: Intent project management framework
# Frees you from unstructured project planning.
#
# Intent comes from Homebrew, the way any user gets it:
#
#     brew install matthewsinclair/intent/intent
#
# No source checkout, and no link of Molt's own. Until ST0004 (2026-09-23) this
# liberator found a checkout under MOLT_INTENT_HOME and linked its dispatcher
# into ~/bin. On gyges that link reached Intent 2.6.0 while a login shell ran
# Homebrew's 3.2.0 and a non-login shell ran 2.6.0, and the check printed ok
# over all of it: it asked whether the link was sound, never which Intent ran.
#
# Two things decide which Intent runs, so the check asks both: PATH, for every
# `intent` typed or scripted, and the gate home, the pointer Intent's pre-commit
# shim reads to find its install.
#
# NOT ENABLED ON RHADAMANTH, deliberately. Intent is developed there, and hv
# ruled that nothing about Intent on that machine is Molt's to touch.

MOLT_INTENT_FORMULA="matthewsinclair/intent/intent"

# The gate home, resolved the way Intent's pre-commit shim resolves it.
_intent_home_file() {
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/intent/home"
}

# The install the gate home names. Fails when there is no gate home.
_intent_gate_root() {
  local file
  file="$(_intent_home_file)"
  [[ -f "$file" ]] || return 1
  head -n 1 "$file"
}

# First line of a binary's --version, captured then trimmed (no pipe to head).
_intent_version() {
  local v
  v="$("$1" --version 2>/dev/null)" || v="version unknown"
  echo "${v%%$'\n'*}"
}

# Everything standing between this machine and "Homebrew's Intent is what
# runs", one fault per line. No output means nothing to report.
_intent_faults() {
  local prefix
  if ! prefix="$(brew --prefix 2>/dev/null)"; then
    echo "Homebrew not found; Intent installs with: brew install $MOLT_INTENT_FORMULA"
    return 0
  fi
  if ! brew list --versions intent &>/dev/null; then
    echo "not installed; run: brew install $MOLT_INTENT_FORMULA"
    return 0
  fi

  local brew_intent="$prefix/bin/intent"
  if [[ ! -x "$brew_intent" ]]; then
    echo "installed but not linked into $prefix/bin"
    return 0
  fi

  local on_path
  on_path="$(command -v intent 2>/dev/null)" || on_path=""
  if [[ -z "$on_path" ]]; then
    echo "no intent on PATH: $prefix/bin is not on it"
  elif [[ "$(_molt_realpath "$on_path")" != "$(_molt_realpath "$brew_intent")" ]]; then
    echo "PATH runs $on_path ($(_intent_version "$on_path")), not Homebrew's $brew_intent"
  fi

  local root
  if ! root="$(_intent_gate_root)"; then
    echo "the pre-commit gate has no install: $(_intent_home_file) is missing; run: intent bootstrap"
  elif [[ ! -d "$root/lib/templates" ]]; then
    echo "the pre-commit gate's install is gone: $(_intent_home_file) names $root; run: intent bootstrap"
  elif [[ "$(_molt_realpath "$root")" != "$(_molt_realpath "$prefix/opt/intent/libexec")" ]]; then
    echo "the pre-commit gate runs $root, not Homebrew's install"
  fi
}

# Log each fault through $1 with the lead $2. True when there are none.
_intent_report_faults() {
  local log="$1" lead="$2" faults fault
  faults="$(_intent_faults)"
  [[ -z "$faults" ]] && return 0
  while IFS= read -r fault; do
    "$log" "${lead}intent: $fault"
  done <<<"$faults"
  return 1
}

intent_check() {
  _intent_report_faults molt_warn "" || return 1
  molt_info "intent: Homebrew's $(_intent_version "$(brew --prefix)/bin/intent") is what PATH and the pre-commit gate run"
}

intent_install() {
  local prefix
  if ! prefix="$(brew --prefix 2>/dev/null)"; then
    molt_error "Intent installs from Homebrew, and brew is not on PATH"
    return 1
  fi

  if ! brew list --versions intent &>/dev/null; then
    molt_info "Installing Intent: brew install $MOLT_INTENT_FORMULA"
    brew install "$MOLT_INTENT_FORMULA" || {
      molt_error "brew install $MOLT_INTENT_FORMULA failed"
      return 1
    }
  fi

  # Only a MISSING or DANGLING gate home is repaired. bootstrap repoints
  # whatever is there, and a gate deliberately pointed at another install is
  # the check's to report, not install's to move -- the formula's caveat draws
  # the same line.
  local root
  if ! root="$(_intent_gate_root)" || [[ ! -d "$root/lib/templates" ]]; then
    molt_info "Pointing Intent's pre-commit gate at the Homebrew install: intent bootstrap"
    "$prefix/bin/intent" bootstrap || {
      molt_error "intent bootstrap failed"
      return 1
    }
  fi

  molt_info "Liberator complete: intent"
}

intent_verify() {
  _intent_report_faults molt_error "VERIFY FAIL: " || return 1
  molt_info "Verified: Homebrew's Intent is what PATH and the pre-commit gate run"
}
