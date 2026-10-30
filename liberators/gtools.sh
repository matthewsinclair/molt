#!/usr/bin/env bash
# gtools.sh — Liberator: Gtools
# Frees you from hand-installing Gtools.
#
# Each sleeve says how it holds Gtools, on the gtools entry in molt.toml:
#
#     source = "brew"     # Homebrew's gtools is what PATH runs (the default)
#     source = "switch"   # dev, opt and brew trees all held; gtools use chooses
#
# Either way Gtools comes from Homebrew, the way any user gets it:
#
#     brew install matthewsinclair/gtools/gtools
#
# No source checkout, and no link of Molt's own. Under switch the dev tree is
# the checkout, which Gtools owns, and the opt tree is `gtools install` into
# GTOOLS_INSTALL_PREFIX; Molt neither builds nor links either, and switching is
# `gtools use dev|opt|brew` (hv, 29 Oct 2026; issue 0073). check and verify
# then name the tree PATH runs, by its version line, and never fault on the
# choice: only a missing formula or tap, or no gtools on PATH, is a fault.
#
# The tap is private, so brew install cannot tap it over https: install taps it
# over ssh first, as devbin's is.

MOLT_GTOOLS_FORMULA="matthewsinclair/gtools/gtools"
MOLT_GTOOLS_TAP_URL="git@github.com:matthewsinclair/homebrew-gtools.git"

# This sleeve's declared source for Gtools.
_gtools_source() {
  molt_liberator_field gtools source || echo brew
}

_gtools_faults() {
  local source
  source="$(_gtools_source)"
  case "$source" in
    brew) molt_brew_faults "$MOLT_GTOOLS_FORMULA" gtools "$MOLT_GTOOLS_TAP_URL" ;;
    switch)
      molt_brew_install_faults "$MOLT_GTOOLS_FORMULA" gtools "$MOLT_GTOOLS_TAP_URL" || return 0
      command -v gtools &>/dev/null || echo "PATH runs no gtools; gtools use dev, opt or brew chooses the tree that does" ;;
    *) echo "source = \"$source\" on its molt.toml entry is neither brew nor switch" ;;
  esac
}

gtools_check() {
  molt_report_faults molt_warn "" gtools "$(_gtools_faults)" || return 1
  if [[ "$(_gtools_source)" == switch ]]; then
    molt_info "gtools: $(molt_cmd_version gtools) is what PATH runs"
  else
    molt_info "gtools: Homebrew's $(molt_cmd_version "$(brew --prefix)/bin/gtools") is what PATH runs"
  fi
}

gtools_install() {
  local source
  source="$(_gtools_source)"
  case "$source" in
    brew | switch) ;;
    *)
      molt_error "gtools: source = \"$source\" on its molt.toml entry is neither brew nor switch; nothing installed"
      return 1 ;;
  esac
  molt_brew_install "$MOLT_GTOOLS_FORMULA" "$MOLT_GTOOLS_TAP_URL" || return 1
  molt_info "Liberator complete: gtools"
}

gtools_verify() {
  molt_report_faults molt_error "VERIFY FAIL: " gtools "$(_gtools_faults)" || return 1
  if [[ "$(_gtools_source)" == switch ]]; then
    molt_info "Verified: $(molt_cmd_version gtools) is what PATH runs"
  else
    molt_info "Verified: Homebrew's Gtools is what PATH runs"
  fi
}
