#!/usr/bin/env bash
# gtools.sh — Liberator: Gtools
# Frees you from hand-installing Gtools.
#
# Gtools comes from Homebrew, the way any user gets it:
#
#     brew install matthewsinclair/gtools/gtools
#
# No source checkout, and no link of Molt's own. A sleeve that develops Gtools
# runs its dev or opt tree under devbin's dev/opt/brew contract, never through
# this liberator.
#
# The tap is private, so brew install cannot tap it over https: install taps it
# over ssh first, as devbin's is.

MOLT_GTOOLS_FORMULA="matthewsinclair/gtools/gtools"
MOLT_GTOOLS_TAP_URL="git@github.com:matthewsinclair/homebrew-gtools.git"

_gtools_faults() {
  molt_brew_faults "$MOLT_GTOOLS_FORMULA" gtools "$MOLT_GTOOLS_TAP_URL"
}

gtools_check() {
  molt_report_faults molt_warn "" gtools "$(_gtools_faults)" || return 1
  molt_info "gtools: Homebrew's $(molt_cmd_version "$(brew --prefix)/bin/gtools") is what PATH runs"
}

gtools_install() {
  molt_brew_install "$MOLT_GTOOLS_FORMULA" "$MOLT_GTOOLS_TAP_URL" || return 1
  molt_info "Liberator complete: gtools"
}

gtools_verify() {
  molt_report_faults molt_error "VERIFY FAIL: " gtools "$(_gtools_faults)" || return 1
  molt_info "Verified: Homebrew's Gtools is what PATH runs"
}
