#!/usr/bin/env bash
# utilz.sh — Liberator: Utilz framework
# Frees you from writing the same shell utilities twice.
#
# Each sleeve says where its Utilz comes from, on the utilz entry in molt.toml:
#
#     source = "checkout"   # a dev checkout at MOLT_UTILZ_HOME, linked into ~/bin
#     source = "brew"       # brew install matthewsinclair/utilz/utilz; Molt links nothing
#
# No source means checkout. Either way the verdict names the utilz that PATH
# actually runs. Until ST0005 (2026-10-20) there was only the checkout, and the
# check asked whether ~/bin/utilz resolved, never what ran: on rhadamanth it
# passed while Homebrew's utilz ran ahead of the checkout's links, and on
# kovacs, brew-only by hv's ruling, it said "repo not found" over a working
# Homebrew install.
#
# brew upgrades a Homebrew install. Utilz's own upgrade, relink and use refuse
# inside the keg, and Molt never calls them.

MOLT_UTILZ_FORMULA="matthewsinclair/utilz/utilz"

# This sleeve's declared source for Utilz.
_utilz_source() {
  local source
  source="$(molt_liberator_field utilz source)" || source="checkout"
  echo "$source"
}

_utilz_find_repo() {
  # Check MOLT_UTILZ_HOME from constants.sh first
  if [[ -d "${MOLT_UTILZ_HOME}/bin" ]] && [[ -f "${MOLT_UTILZ_HOME}/bin/utilz" ]]; then
    echo "${MOLT_UTILZ_HOME}"
    return 0
  fi
  return 1
}

# molt git manages the checkout only on a sleeve that declares one.
utilz_repo() {
  [[ "$(_utilz_source)" == "checkout" ]] || return 1
  _utilz_find_repo
}
utilz_repo_git_commands() { echo "pull status log diff fetch"; }

# The checkout's utilities, one per line: the symlinks to the dispatcher in its
# bin/, which install links into ~/bin beside the dispatcher.
_utilz_checkout_utilities() {
  local link
  for link in "$1/bin/"*; do
    if [[ -L "$link" ]]; then
      echo "${link##*/}"
    fi
  done
}

# The utilities the Homebrew keg's bin/ $1 holds, one per line, the dispatcher
# aside. The formula links every one of them into Homebrew's bin.
_utilz_keg_utilities() {
  local entry
  for entry in "$1"/*; do
    if [[ -e "$entry" && "${entry##*/}" != "utilz" ]]; then
      echo "${entry##*/}"
    fi
  done
}

_utilz_checkout_faults() {
  local repo missed
  if ! repo="$(_utilz_find_repo)"; then
    echo "checkout not found at ${MOLT_UTILZ_HOME}"
    return 0
  fi
  molt_path_runs_fault utilz "$repo/bin/utilz" "the checkout's $repo/bin/utilz"
  missed="$(molt_path_misses "$repo/bin" "$(_utilz_checkout_utilities "$repo")")"
  if [[ -n "$missed" ]]; then
    echo "PATH runs these from somewhere other than the checkout, or not at all: $missed"
  fi
  if ! command -v bats &>/dev/null; then
    echo "bats-core not installed (utilz test needs it)"
  fi
}

_utilz_brew_faults() {
  molt_brew_faults "$MOLT_UTILZ_FORMULA" utilz || return 0
  local prefix missed
  prefix="$(brew --prefix)"
  missed="$(molt_path_misses "$prefix/bin" "$(_utilz_keg_utilities "$prefix/opt/utilz/libexec/bin")")"
  if [[ -n "$missed" ]]; then
    echo "PATH runs these from somewhere other than Homebrew's install, or not at all: $missed"
  fi
}

# Everything standing between this sleeve and its declared utilz running, one
# fault per line. No output means nothing to report.
_utilz_faults() {
  local source
  source="$(_utilz_source)"
  case "$source" in
    checkout) _utilz_checkout_faults ;;
    brew) _utilz_brew_faults ;;
    *) echo "source = \"$source\" on its molt.toml entry is neither checkout nor brew" ;;
  esac
}

utilz_check() {
  local source
  source="$(_utilz_source)"
  molt_report_faults molt_info "" "utilz ($source)" "$(_utilz_faults)" || return 1
  molt_info "utilz ($source): $(molt_cmd_version utilz) is what PATH runs"
}

_utilz_install_checkout() {
  local repo
  if ! repo="$(_utilz_find_repo)"; then
    molt_error "Utilz repo not found at: ${MOLT_UTILZ_HOME}"
    molt_error "Set UTILZ_HOME env var to override"
    return 1
  fi

  molt_info "Found Utilz at: $repo"

  # Ensure ~/bin exists
  mkdir -p "$MOLT_LOCAL_BIN"

  # Link the utilz dispatcher into ~/bin
  molt_link "$repo/bin/utilz" "$MOLT_LOCAL_BIN/utilz" || return 1

  # Link all utility symlinks from the Utilz bin/ directory
  local name
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    molt_link "$repo/bin/$name" "$MOLT_LOCAL_BIN/$name" || return 1
  done <<< "$(_utilz_checkout_utilities "$repo")"

  # Set UTILZ_HOME in environment if not already handled
  # (zshrc should pick this up — we just inform)
  molt_info "Ensure UTILZ_HOME=$repo is in your shell config"

  # Verify bats-core is installed
  if ! command -v bats &>/dev/null; then
    molt_error "bats-core not found. Install it (eg apt install bats, brew install bats-core) then re-run."
    return 1
  fi
}

utilz_install() {
  local source
  source="$(_utilz_source)"
  case "$source" in
    checkout) _utilz_install_checkout || return 1 ;;
    brew) molt_brew_install "$MOLT_UTILZ_FORMULA" || return 1 ;;
    *)
      molt_error "utilz: source = \"$source\" on its molt.toml entry is neither checkout nor brew; nothing installed"
      return 1
      ;;
  esac
  molt_info "Liberator complete: utilz"
}

utilz_upgrade() {
  local source repo
  source="$(_utilz_source)"
  case "$source" in
    checkout) ;;
    brew)
      molt_info "utilz comes from Homebrew here, so brew upgrade upgrades it, not molt upgrade"
      return 0
      ;;
    *)
      molt_error "utilz: source = \"$source\" on its molt.toml entry is neither checkout nor brew; not upgraded"
      return 1
      ;;
  esac

  if ! repo="$(_utilz_find_repo)"; then
    molt_error "Utilz repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling Utilz repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "Utilz repo updated."
  else
    molt_warn "Utilz pull skipped (not on tracking branch or already up-to-date)."
  fi
}

utilz_verify() {
  local source
  source="$(_utilz_source)"
  molt_report_faults molt_error "VERIFY FAIL: " "utilz ($source)" "$(_utilz_faults)" || return 1
  molt_info "Verified: utilz ($source) is what PATH runs"
}
