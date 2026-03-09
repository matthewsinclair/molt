#!/usr/bin/env bash
# constants.sh — Single source of truth for all configurable paths and defaults.
# The Highlander Rule: every constant defined here and ONLY here.
# When Molt becomes a brew tap, these defaults change in ONE place.

# --- Project directories ---
# Where repos live. MUST be set via env var or sleeve config.
# No hardcoded default — every machine chooses its own layout.
MOLT_PROJECTS_DIR="${MOLT_PROJECTS_DIR:-}"

# --- User config repo ---
# The molt-{user} repo location. Searched in order.
# MOLT_PROJECTS_DIR path only included if set.
MOLT_USER_REPO_SEARCH_PATHS=()
if [[ -n "$MOLT_PROJECTS_DIR" ]]; then
  MOLT_USER_REPO_SEARCH_PATHS+=("${MOLT_PROJECTS_DIR}/molt-$(whoami)")
fi
MOLT_USER_REPO_SEARCH_PATHS+=(
  "$HOME/molt-$(whoami)"
  "$HOME/.molt-$(whoami)"
)

# --- Tool repos ---
# Where tool liberators look for their repos. Each can be overridden
# individually via env var (eg UTILZ_HOME), or they fall back to
# searching MOLT_PROJECTS_DIR.
MOLT_UTILZ_HOME="${UTILZ_HOME:-${MOLT_PROJECTS_DIR:+${MOLT_PROJECTS_DIR}/Utilz}}"
MOLT_INTENT_HOME="${INTENT_HOME:-${MOLT_PROJECTS_DIR:+${MOLT_PROJECTS_DIR}/Intent}}"

# --- Local bin ---
MOLT_LOCAL_BIN="${MOLT_LOCAL_BIN:-$HOME/bin}"

# --- Framework ---
MOLT_VERSION="0.1.0"
MOLT_NAME="MOLT"
