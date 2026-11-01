#!/usr/bin/env bash
# cldr.sh — Liberator: cldr
# Frees you from keeping a time journal's numbers by hand (issue 0080, hv 1 Nov
# 2026).
#
# cldr renders a plain-text time journal: week and month summaries, a JSON
# document per month, a year's hours report, a Daily Briefing. It comes from
# Homebrew, the way any user gets it:
#
#     brew install matthewsinclair/cldr/cldr
#
# The tap is public. Installing by the formula's full name trusts it, so
# brew upgrade includes it; a cldr installed before the trust gate is trusted
# by install, as every Homebrew liberator's is (molt_brew_install).
#
# Its config is $XDG_CONFIG_HOME/cldr/config.toml, and it holds the user's own
# numbers (zones, tag spellings, what counts as work, what bills), so it lives
# in the user repo at config/cldr/. An editor's save may replace a linked file
# with a plain copy, so the whole directory is linked, made only when the user
# repo has config/cldr.
#
# cldr reads the calendar store, which needs Full Disk Access for the terminal:
# that grant is the user's, not Molt's, and `cldr doctor` reports it.

MOLT_CLDR_FORMULA="matthewsinclair/cldr/cldr"

# The config directory cldr reads: $XDG_CONFIG_HOME/cldr when that is set and
# absolute, as the XDG spec has it, else ~/.config/cldr.
_cldr_config_dir() {
  if [[ "${XDG_CONFIG_HOME:-}" == /* ]]; then
    echo "$XDG_CONFIG_HOME/cldr"
  else
    echo "$HOME/.config/cldr"
  fi
}

# Every link cldr_install makes, one "source<TAB>target" line each, for the
# sources the user repo $1 has. check, install and verify all read this list.
_cldr_links() {
  local user_repo="$1"
  if [[ -d "$user_repo/config/cldr" ]]; then
    printf '%s\t%s\n' "$user_repo/config/cldr" "$(_cldr_config_dir)"
  fi
}

# Checks Homebrew's cldr, then the config link, through the logger $1 with the
# lead $2. True when there is nothing to report.
_cldr_report() {
  local log="$1" lead="$2" ok=0 user_repo
  molt_report_faults "$log" "$lead" cldr "$(molt_brew_faults "$MOLT_CLDR_FORMULA" cldr)" || ok=1
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    molt_report_link_faults "$log" "${lead}cldr: " "$(_cldr_links "$user_repo")" || ok=1
  fi
  return "$ok"
}

cldr_check() {
  _cldr_report molt_warn "" || return 1
  molt_info "cldr: Homebrew's $(molt_cmd_version "$(brew --prefix)/bin/cldr") is what PATH runs"
}

cldr_install() {
  molt_brew_install "$MOLT_CLDR_FORMULA" || return 1
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    molt_link_all "$(_cldr_links "$user_repo")" || return 1
  fi
  molt_info "Liberator complete: cldr"
}

cldr_verify() {
  _cldr_report molt_error "VERIFY FAIL: " || return 1
  molt_info "Verified: Homebrew's cldr is what PATH runs, its config linked"
}
