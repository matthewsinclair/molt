#!/usr/bin/env bash
# brew.sh — Liberator: Homebrew lifecycle
# Frees you from stale packages, wherever brew is on PATH: Homebrew on macOS,
# Linuxbrew on Linux. It was macOS only, so nothing upgraded kovacs's
# Linuxbrew (issue 0077).
#
# A sleeve may list the packages it needs in a Brewfile of its own in the user
# repo, instances/<host>/Brewfile. With one, check and verify fail while
# Homebrew lacks anything it lists, and install adds what is missing, through
# `brew bundle` (issue 0101). The file is a minimum: nothing it leaves out is
# removed, and what it lists is upgraded by brew_maintain alone. Molt ships no
# Brewfile and writes none, and a sleeve without one is as it was.

# This sleeve's Brewfile. Fails when its stack has none, or there is no stack.
_brew_brewfile() {
  local f
  f="$(molt_instance_file Brewfile)" || return 1
  [[ -f "$f" ]] || return 1
  echo "$f"
}

# One line per fault between the Brewfile $1 and "Homebrew has everything it
# lists", or nothing: what `brew bundle check` said, which names each thing
# missing, or why the file cannot be read, and then the file and what installs
# it. brew says it on stderr, which resleeve drops from a check, so the lines
# are for the caller to log.
#
# A check is a read, so brew is kept from two things. --no-upgrade passes a
# listed formula that is only outdated: without it doctor would fail at each
# new version of one. HOMEBREW_NO_AUTO_UPDATE keeps brew from fetching first:
# `bundle` is among the commands Homebrew updates itself before, once its last
# fetch is a day old, and refreshes its API cache for.
_brew_bundle_faults() {
  local brewfile="$1" said line
  said="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file="$brewfile" 2>&1)" && return 0
  [[ -n "$said" ]] || said="brew bundle check failed, and said nothing"
  while IFS= read -r line; do
    [[ -z "$line" ]] || printf '%s\n' "$line"
  done <<< "$said"
  echo "this sleeve's Brewfile is $(molt_tilde "$brewfile"), and molt resleeve installs what it lists"
}

brew_check() {
  if ! command -v brew &>/dev/null; then
    molt_info "brew: Homebrew not installed"
    return 1
  fi

  local brewfile
  if brewfile="$(_brew_brewfile)"; then
    molt_report_faults molt_info "" brew "$(_brew_bundle_faults "$brewfile")" || return 1
  fi

  return 0
}

brew_install() {
  if ! command -v brew &>/dev/null; then
    molt_error "Homebrew not found. Install it (https://brew.sh) then re-run."
    return 1
  fi

  # What the sleeve's Brewfile lists and Homebrew lacks. --no-upgrade leaves
  # what is installed as it is, since brew_maintain upgrades. No cleanup, ever:
  # the file is a minimum, and a cleanup removes whatever it does not list.
  local brewfile
  if brewfile="$(_brew_brewfile)"; then
    molt_info "Installing what $(molt_tilde "$brewfile") lists and Homebrew lacks..."
    if ! brew bundle install --no-upgrade --file="$brewfile"; then
      molt_error "brew: brew bundle install failed for $(molt_tilde "$brewfile") (above)"
      return 1
    fi
  fi

  molt_info "Liberator complete: brew"
}

brew_verify() {
  local errors=0 brewfile

  if ! command -v brew &>/dev/null; then
    molt_error "VERIFY FAIL: brew not installed"
    errors=1
  elif brewfile="$(_brew_brewfile)"; then
    molt_report_faults molt_error "VERIFY FAIL: " brew "$(_brew_bundle_faults "$brewfile")" || errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: brew liberator is fully operational"
  fi
  return $errors
}

brew_maintain() {
  if ! command -v brew &>/dev/null; then
    molt_error "Homebrew not found — cannot maintain"
    return 1
  fi

  # Each step that fails is named and fails the hook; the rest still run, so
  # one failed step does not leave the others undone (issue 0052).
  local failed=""
  molt_info "Updating Homebrew formulae..."
  brew update || failed+="${failed:+, }brew update"

  molt_info "Upgrading Homebrew packages..."
  brew upgrade || failed+="${failed:+, }brew upgrade"

  # Casks are macOS's alone (issue 0077).
  if [[ "$(molt_platform)" == "macos" ]]; then
    molt_info "Upgrading Homebrew casks..."
    brew upgrade --cask || failed+="${failed:+, }brew upgrade --cask"
  fi

  molt_info "Cleaning up old versions..."
  brew cleanup -s || failed+="${failed:+, }brew cleanup -s"

  molt_info "Running brew doctor..."
  brew doctor || molt_warn "brew doctor reported warnings (review above)"

  molt_info "Checking for missing dependencies..."
  brew missing || true

  # Update global npm packages if npm is installed
  if command -v npm &>/dev/null; then
    molt_info "Updating global npm packages..."
    npm update --location=global || molt_warn "npm global update had warnings"
  fi

  if [[ -n "$failed" ]]; then
    molt_error "Homebrew maintenance failed: $failed (above)"
    return 1
  fi
  molt_info "Homebrew maintenance complete."
}
