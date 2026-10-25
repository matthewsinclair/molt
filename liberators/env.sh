#!/usr/bin/env bash
# env.sh — Liberator: the sleeve's published environment
# Frees you from setting the same variables by hand in every shell and for
# every GUI app. It gathers what each contributor gives and publishes it
# through Molt's one env writer, lib/env.sh (ST0008 WP05):
#
# - CLAUDE_CONFIG_DIR, which the claude liberator gives only once Claude
#   Code's state is in the declared dir, so it runs after claude;
# - each <TOOL>_INSTALL_PREFIX this sleeve's vars.sh exports;
# - PATH for GUI apps, as a login shell builds it.
#
# Each pair stands alone (vc, 24 Oct): every pair that passes is published, a
# refused one is left out, and the run fails naming each refused one, so one
# bad PATH never takes CLAUDE_CONFIG_DIR out of env.sh.

# Every contributor's lines: a "NAME<TAB>scope<TAB>value" line per pair, and a
# "!<TAB>why" line per refusal.
_env_lines() {
  if ! declare -f claude_env_pairs &>/dev/null; then
    # shellcheck source=/dev/null
    if ! source "${MOLT_LIBERATORS_DIR:-$MOLT_ROOT/liberators}/claude.sh"; then
      printf '!\t%s\n' "CLAUDE_CONFIG_DIR: the claude liberator could not be loaded"
    fi
  fi
  if declare -f claude_env_pairs &>/dev/null; then
    claude_env_pairs
  fi
  molt_env_prefix_pairs
  molt_env_path_pair
}

# Reports, through $1 after the prefix $2, each refusal in the lines $3.
# Returns non-zero when there was one.
_env_report_refusals() {
  local log="$1" prefix="$2" why ok=0
  while IFS= read -r why; do
    [[ -n "$why" ]] || continue
    "$log" "${prefix}$why"
    ok=1
  done <<< "$(molt_env_refusals <<< "$3")"
  return $ok
}

# The names in the pairs $1 of scope $2, joined by ", ".
_env_scope_names() {
  awk -F'\t' -v s="$2" '$2 == s { print $1 }' <<< "$1" | paste -sd, - | sed 's/,/, /g'
}

# Where each pair is published, as install and verify name it.
_env_published_line() {
  local pairs="$1" gui shell_names gui_names out=""
  gui="$(molt_tilde "$(molt_env_gui_file)")"
  shell_names="$(_env_scope_names "$pairs" all)"
  gui_names="$(_env_scope_names "$pairs" gui)"
  [[ -z "$shell_names" ]] || out="$shell_names in $(molt_tilde "$(molt_env_file)")${gui:+ and $gui}"
  [[ -z "$gui_names" ]] || out="${out:+$out; }$gui_names in ${gui:-no GUI file}"
  [[ -z "$gui" ]] || out="${out:+$out; }$gui takes effect for apps launched after the next login"
  printf '%s' "${out:-nothing}"
}

env_check() {
  local lines pairs ok=0
  lines="$(_env_lines)"
  pairs="$(molt_env_given <<< "$lines")"
  _env_report_refusals molt_info "env: " "$lines" || ok=1
  molt_env_report_faults molt_info "env: " "$pairs" || ok=1
  molt_env_report_launchd molt_info "env: " "$pairs" || ok=1
  return $ok
}

env_install() {
  local lines pairs ok=0
  lines="$(_env_lines)"
  pairs="$(molt_env_given <<< "$lines")"
  molt_env_publish "$pairs" || return 1
  molt_info "env: published $(_env_published_line "$pairs")"
  _env_report_refusals molt_error "env: " "$lines" || ok=1
  [[ $ok -eq 0 ]] || return 1
  molt_info "Liberator complete: env"
}

env_verify() {
  local lines pairs ok=0
  lines="$(_env_lines)"
  pairs="$(molt_env_given <<< "$lines")"
  _env_report_refusals molt_error "VERIFY FAIL: env: " "$lines" || ok=1
  molt_env_report_faults molt_error "VERIFY FAIL: env: " "$pairs" || ok=1
  [[ $ok -eq 0 ]] || return 1
  molt_info "Verified: env liberator is fully operational; $(_env_published_line "$pairs")"
}
