#!/usr/bin/env bash
# constants.sh — Single source of truth for all configurable paths and defaults.
# The Highlander Rule: every constant defined here and ONLY here.
# When Molt becomes a brew tap, these defaults change in ONE place.
#
# All variables are consumed by scripts that source this file.
# shellcheck disable=SC2034

# --- Project directories ---
# Where repos live. MUST be set via env var or sleeve config.
# No hardcoded default — every machine chooses its own layout.
MOLT_PRJ_DIR="${MOLT_PRJ_DIR:-}"

# --- Opt directory ---
# Where opt-style installs live. Derived from MOLT_PRJ_DIR's parent.
MOLT_OPT_DIR="${MOLT_OPT_DIR:-${MOLT_PRJ_DIR:+$(dirname "$MOLT_PRJ_DIR")/opt}}"

# --- Config directory ---
# Where config repos live: the Molt-{user} repo, and anything else that is
# configuration rather than a development project. Derived from MOLT_PRJ_DIR's
# parent, like MOLT_OPT_DIR, so ~/Devel/prj gives ~/Devel/cfg.
MOLT_CFG_DIR="${MOLT_CFG_DIR:-${MOLT_PRJ_DIR:+$(dirname "$MOLT_PRJ_DIR")/cfg}}"

# --- Agent directory ---
# Where sleeve agents live, a home each, named <hostname>-<role> (ST0006). The
# agt/ sibling of MOLT_PRJ_DIR, like MOLT_CFG_DIR, so ~/Devel/prj gives
# ~/Devel/agt: the value the user repo's zshenv gives shells, from the same
# MOLT_PRJ_DIR. Empty when MOLT_PRJ_DIR is not set either, rather than a guess
# that would disagree with a sleeve whose projects live elsewhere;
# molt_agt_dir_fault refuses it then, so no home lands at /<name>. This is the
# one resolver of MOLT_AGT_DIR. It is exported, so molt_render substitutes it
# into the claude liberator's home guard (AC014). molt_agt_dir_derived is the
# derivation alone, which molt_agt_dir_fault names in a refusal: a sleeve that
# never set MOLT_AGT_DIR would not know where a value it refuses came from.
molt_agt_dir_derived() {
  [[ -z "${MOLT_PRJ_DIR:-}" ]] || echo "$(dirname "$MOLT_PRJ_DIR")/agt"
}
MOLT_AGT_DIR="${MOLT_AGT_DIR:-$(molt_agt_dir_derived)}"
export MOLT_AGT_DIR

# --- User config repo ---
# The Molt-{user} repo location. Searched in order.
# MOLT_CFG_DIR and MOLT_PRJ_DIR paths only included if set.
#
# MOLT_CFG_DIR is where the repo belongs and is searched first. MOLT_PRJ_DIR is
# where it lived until 2026-09-15 and stays in the list, so a sleeve that has
# not moved its repo yet still resolves instead of failing every command.
#
# Molt-matts and Molt-flynn are Capitalised, like every project under
# MOLT_PRJ_DIR, so the capitalised form is the convention and is searched first.
# The lowercase form is kept as a fallback: it is what
# earlier versions asked for, and a sleeve on a case-sensitive filesystem that
# cloned before this change would otherwise stop resolving entirely.
#
# This only ever mattered on case-sensitive storage. On APFS the lowercase
# lookup folded onto the capitalised directory and nothing noticed for months.
MOLT_USER_REPO_SEARCH_PATHS=()
if [[ -n "$MOLT_CFG_DIR" ]]; then
  MOLT_USER_REPO_SEARCH_PATHS+=(
    "${MOLT_CFG_DIR}/Molt-$(whoami)"
    "${MOLT_CFG_DIR}/molt-$(whoami)"
  )
fi
if [[ -n "$MOLT_PRJ_DIR" ]]; then
  MOLT_USER_REPO_SEARCH_PATHS+=(
    "${MOLT_PRJ_DIR}/Molt-$(whoami)"
    "${MOLT_PRJ_DIR}/molt-$(whoami)"
  )
fi
MOLT_USER_REPO_SEARCH_PATHS+=(
  "$HOME/Molt-$(whoami)"
  "$HOME/molt-$(whoami)"
  "$HOME/.molt-$(whoami)"
)

# --- Tool repos ---
# Where tool liberators look for their repos: MOLT_PRJ_DIR/Utilz and
# MOLT_PRJ_DIR/Pplr, each overridden by its own env var (eg UTILZ_HOME).
MOLT_UTILZ_HOME="${UTILZ_HOME:-${MOLT_PRJ_DIR:+${MOLT_PRJ_DIR}/Utilz}}"
MOLT_PPLR_HOME="${PPLR_HOME:-${MOLT_PRJ_DIR:+${MOLT_PRJ_DIR}/Pplr}}"

# --- Local bin ---
MOLT_LOCAL_BIN="${MOLT_LOCAL_BIN:-$HOME/bin}"

# --- Framework ---
MOLT_VERSION="$(cat "${MOLT_ROOT}/VERSION" 2>/dev/null || echo "0.1.0")"
MOLT_NAME="MOLT"
