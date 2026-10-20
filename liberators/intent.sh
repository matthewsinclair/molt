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

# Everything standing between this machine and "Homebrew's Intent is what
# runs", one fault per line. No output means nothing to report. Homebrew's half
# is the check every Homebrew liberator shares; the gate home is Intent's own.
_intent_faults() {
  molt_brew_faults "$MOLT_INTENT_FORMULA" intent || return 0

  local prefix root
  if ! prefix="$(brew --prefix 2>/dev/null)"; then
    echo "brew --prefix failed, so the pre-commit gate was not checked"
    return 0
  fi
  if ! root="$(_intent_gate_root)"; then
    echo "the pre-commit gate has no install: $(_intent_home_file) is missing; run: intent bootstrap"
  elif [[ ! -d "$root/lib/templates" ]]; then
    echo "the pre-commit gate's install is gone: $(_intent_home_file) names $root; run: intent bootstrap"
  elif ! molt_same_file "$root" "$prefix/opt/intent/libexec"; then
    echo "the pre-commit gate runs $root, not Homebrew's install"
  fi
}

intent_check() {
  molt_report_faults molt_warn "" intent "$(_intent_faults)" || return 1
  molt_info "intent: Homebrew's $(molt_cmd_version "$(brew --prefix)/bin/intent") is what PATH and the pre-commit gate run"
}

intent_install() {
  molt_brew_install "$MOLT_INTENT_FORMULA" || return 1

  # Only a MISSING or DANGLING gate home is repaired. bootstrap repoints
  # whatever is there, and a gate deliberately pointed at another install is
  # the check's to report, not install's to move -- the formula's caveat draws
  # the same line.
  local root
  if ! root="$(_intent_gate_root)" || [[ ! -d "$root/lib/templates" ]]; then
    molt_info "Pointing Intent's pre-commit gate at the Homebrew install: intent bootstrap"
    "$(brew --prefix)/bin/intent" bootstrap || {
      molt_error "intent bootstrap failed"
      return 1
    }
  fi

  molt_info "Liberator complete: intent"
}

intent_verify() {
  molt_report_faults molt_error "VERIFY FAIL: " intent "$(_intent_faults)" || return 1
  molt_info "Verified: Homebrew's Intent is what PATH and the pre-commit gate run"
}
