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
# Any contributor that cannot answer stops the whole publish, so the files are
# never written from part of the set.

# Every pair this sleeve publishes, one "NAME<TAB>scope<TAB>value" line each.
# Fails, printing why, when a contributor cannot answer.
_env_pairs() {
  local pairs out
  if ! declare -f claude_env_pairs &>/dev/null; then
    # shellcheck source=/dev/null
    source "${MOLT_LIBERATORS_DIR:-$MOLT_ROOT/liberators}/claude.sh" || { echo "the claude liberator could not be loaded"; return 1; }
  fi
  out="$(claude_env_pairs)" || { echo "$out"; return 1; }
  pairs="$out"
  out="$(molt_env_prefix_pairs)" || { echo "$out"; return 1; }
  pairs="${pairs:+$pairs${out:+$'\n'}}$out"
  out="$(molt_env_path_pair)" || { echo "$out"; return 1; }
  pairs="${pairs:+$pairs$'\n'}$out"
  printf '%s\n' "$pairs"
}

# Where each pair is published, as verify names it.
_env_published_line() {
  local pairs="$1" gui shell_names gui_names
  gui="$(molt_tilde "$(molt_env_gui_file)")"
  shell_names="$(awk -F'\t' '$2 == "all" { print $1 }' <<< "$pairs" | paste -sd, - | sed 's/,/, /g')"
  gui_names="$(awk -F'\t' '$2 == "gui" { print $1 }' <<< "$pairs" | paste -sd, - | sed 's/,/, /g')"
  printf '%s' "${shell_names:+$shell_names in $(molt_tilde "$(molt_env_file)")${gui:+ and $gui}; }"
  printf '%s' "${gui_names:+$gui_names in ${gui:-no GUI file}}"
  [[ -z "$gui" ]] || printf '; %s takes effect for apps launched after the next login' "$gui"
}

env_check() {
  local pairs
  if ! pairs="$(_env_pairs)"; then
    molt_info "env: $pairs"
    return 1
  fi
  molt_env_report_faults molt_info "env: " "$pairs"
}

env_install() {
  local pairs
  if ! pairs="$(_env_pairs)"; then
    molt_error "env: $pairs; nothing was published"
    return 1
  fi
  molt_env_publish "$pairs" || return 1
  molt_info "env: published $(_env_published_line "$pairs")"
  molt_info "Liberator complete: env"
}

env_verify() {
  local pairs
  if ! pairs="$(_env_pairs)"; then
    molt_error "VERIFY FAIL: env: $pairs"
    return 1
  fi
  molt_env_report_faults molt_error "VERIFY FAIL: env: " "$pairs" || return 1
  molt_info "Verified: env liberator is fully operational; $(_env_published_line "$pairs")"
}
