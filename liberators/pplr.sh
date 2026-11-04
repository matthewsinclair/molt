#!/usr/bin/env bash
# pplr.sh — Liberator: pplr
# Frees you from losing track of people.
#
# pplr is a personal relationship manager over a plain-text People tree. It
# comes from Homebrew, the way any user gets it:
#
#     brew install matthewsinclair/pplr/pplr
#
# The tap is public. Installing by the formula's full name trusts it, so brew
# upgrade includes it; a pplr installed before the trust gate is trusted by
# install, as every Homebrew liberator's is (molt_brew_install). The formula is
# for macOS on Apple silicon alone, and brew refuses it anywhere else.
#
# Where this differs from the cldr liberator: cldr has no tree but Homebrew's,
# and pplr has a switch of its own (devbin's dev, opt, brew contract T5).
# `pplr use dev` or `pplr use opt` points ~/.local/bin/pplr at a checkout's
# build or at an opt tree, and which tree runs is the user's choice, not Molt's
# to judge (hv, 27 Oct 2026, issue 0071). So when PATH runs a pplr whose
# version line names the dev or opt tree, check and verify name that tree, and
# fault only on a Homebrew pplr that is not installed, which `pplr use brew`
# needs to hand the command back to. Otherwise Homebrew's pplr must be what
# PATH runs, as cldr's must.
#
# Until Molt 1.4.1 this liberator linked a checkout's bin/pplr into
# MOLT_LOCAL_BIN and pulled the checkout on upgrade. pplr 2.0 has no bin/pplr,
# so the upgrade hook failed molt upgrade, and the link is dead, or runs pplr
# 1.x ahead of Homebrew's. check names that link, install removes it, and there
# is no upgrade hook: brew upgrade upgrades pplr (issue 0086).

MOLT_PPLR_FORMULA="matthewsinclair/pplr/pplr"

# The version line of the pplr PATH runs (contract T4: `pplr <version>
# (<tree>, <sha12>)`) when it names the dev or opt tree, as a tree pplr use
# chose does. Fails when PATH runs no pplr, or one whose line names neither.
_pplr_own_tree() {
  local version
  command -v pplr &>/dev/null || return 1
  version="$(molt_cmd_version pplr)"
  case "$version" in
    *" (dev, "* | *" (opt, "*) echo "$version" ;;
    *) return 1 ;;
  esac
}

# The link this liberator made until Molt 1.4.1: MOLT_LOCAL_BIN/pplr to the
# bin/pplr of a checkout, a directory holding .git, written absolute. pplr's
# own switch links a checkout's target/release/pplr, or an opt tree's
# bin/pplr where no .git is, so it is never taken for this. Prints the link's
# target; fails when MOLT_LOCAL_BIN/pplr is anything else, or nothing.
_pplr_checkout_link() {
  local link="$MOLT_LOCAL_BIN/pplr" target
  [[ -L "$link" ]] || return 1
  target="$(readlink "$link")" || return 1
  [[ "$target" == /*/bin/pplr && -e "${target%/bin/pplr}/.git" ]] || return 1
  echo "$target"
}

# Everything standing between this sleeve and its pplr, one fault per line:
# with a tree of pplr's own on PATH, only a Homebrew pplr not installed, and
# otherwise all that molt_brew_faults names, another pplr on PATH included.
# Then the old checkout link, whatever PATH runs. No output means nothing to
# report.
_pplr_faults() {
  local target
  if _pplr_own_tree >/dev/null; then
    molt_brew_install_faults "$MOLT_PPLR_FORMULA" pplr
  else
    molt_brew_faults "$MOLT_PPLR_FORMULA" pplr
  fi
  if target="$(_pplr_checkout_link)"; then
    echo "$(molt_tilde "$MOLT_LOCAL_BIN/pplr") is Molt's old link to a checkout's $(molt_tilde "$target"); install removes it"
  fi
}

# What PATH runs for pplr, once nothing stands in its way.
_pplr_runs() {
  local tree
  if tree="$(_pplr_own_tree)"; then
    echo "$tree is what PATH runs; pplr use brew hands the command back to Homebrew"
  else
    echo "Homebrew's $(molt_cmd_version "$(brew --prefix)/bin/pplr") is what PATH runs"
  fi
}

pplr_check() {
  molt_report_faults molt_warn "" pplr "$(_pplr_faults)" || return 1
  molt_info "pplr: $(_pplr_runs)"
}

pplr_install() {
  molt_brew_install "$MOLT_PPLR_FORMULA" || return 1
  local target
  if target="$(_pplr_checkout_link)"; then
    rm "$MOLT_LOCAL_BIN/pplr" || {
      molt_error "pplr: $(molt_tilde "$MOLT_LOCAL_BIN/pplr") could not be removed"
      return 1
    }
    molt_info "Removed $(molt_tilde "$MOLT_LOCAL_BIN/pplr"), Molt's old link to a checkout's $(molt_tilde "$target")"
  fi
  molt_info "Liberator complete: pplr"
}

pplr_verify() {
  molt_report_faults molt_error "VERIFY FAIL: " pplr "$(_pplr_faults)" || return 1
  molt_info "Verified: $(_pplr_runs)"
}
