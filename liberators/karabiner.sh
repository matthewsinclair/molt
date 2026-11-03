#!/usr/bin/env bash
# karabiner.sh — Liberator: Karabiner-Elements
# Frees you from re-mapping each Mac's keyboard by hand in Karabiner's Settings
# (issue 0081, hv 3 Nov 2026).
#
# Karabiner-Elements reads karabiner.json from the karabiner directory under
# the XDG config home, ~/.config unless XDG_CONFIG_HOME says otherwise. The
# file holds the user's own key mappings and device entries, so it lives in the
# user repo at config/karabiner/. Karabiner saves it by writing a new file and
# renaming it over the old one, which would replace a linked file with a plain
# copy on the first save, so the whole directory is linked, as Karabiner's docs
# say (karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/),
# and only when the user repo has config/karabiner.
#
# A real directory already there is adopted, not only backed up: each of its
# entries (karabiner.json, assets/, automatic_backups/) moves into the repo
# directory where the repo has no entry of that name, and molt_link keeps
# whatever is left as the dated .molt-backup. When both hold a karabiner.json
# and the two differ, install refuses before moving anything and names both
# files, so the user chooses which is kept.
#
# Karabiner's agent goes on watching the directory it found when it started,
# so once install has made the link it restarts the agent, as the docs say, or
# changes to the file go undetected.
#
# It links config only: Karabiner-Elements itself is installed by hand, since
# its driver needs the user's approval. Karabiner reads XDG_CONFIG_HOME from its
# launchd agent's environment, so a sleeve that sets it publishes it through
# the env liberator.
#
# macOS only: Karabiner-Elements runs on the Macs.

MOLT_KARABINER_AGENT="org.pqrs.service.agent.Karabiner-Console-User-Server"

# Every link karabiner_install makes, one "source<TAB>target" line each, for
# the sources the user repo $1 has: config/karabiner to the karabiner directory
# under the XDG config home. check, install and verify all read this list.
_karabiner_links() {
  local user_repo="$1"
  if [[ -d "$user_repo/config/karabiner" ]]; then
    printf '%s\t%s\n' "$user_repo/config/karabiner" "$(molt_xdg_config_home)/karabiner"
  fi
}

# Adopts a real directory at the target $2 into the repo directory $1, before
# install links it. Refuses, moving nothing, when both hold a karabiner.json
# and the two differ; else moves each of $2's entries into $1 where $1 has no
# entry of that name, so a karabiner.json the repo lacks comes with the rest.
# Nothing to adopt when $2 is missing or a link.
_karabiner_adopt() {
  local source="$1" target="$2" entry name
  [[ -d "$target" && ! -L "$target" ]] || return 0
  if [[ -e "$target/karabiner.json" && -e "$source/karabiner.json" ]] && ! cmp -s "$target/karabiner.json" "$source/karabiner.json"; then
    molt_error "karabiner: $(molt_tilde "$target/karabiner.json") differs from $(molt_tilde "$source/karabiner.json"), so nothing was moved or linked: copy the one to keep over the other, then install again"
    return 1
  fi
  for entry in "$target"/* "$target"/.[!.]* "$target"/..?*; do
    # A glob that matched nothing is left as written.
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="${entry##*/}"
    if [[ -e "$source/$name" || -L "$source/$name" ]]; then
      continue
    fi
    mv "$entry" "$source/$name" || { molt_error "karabiner: could not move $(molt_tilde "$entry") into $(molt_tilde "$source"), so it was not linked"; return 1; }
    molt_info "karabiner: adopted $(molt_tilde "$entry") into $(molt_tilde "$source")"
  done
}

# Restarts Karabiner's agent, so it watches karabiner.json through the link
# install has just made. An agent that is not loaded reads the link when it
# starts, so it is left alone.
_karabiner_restart_agent() {
  local service
  service="gui/$(id -u)/$MOLT_KARABINER_AGENT"
  if ! launchctl print "$service" &>/dev/null; then
    molt_debug "karabiner: $MOLT_KARABINER_AGENT is not loaded, so it reads the link when it starts"
    return 0
  fi
  if ! launchctl kickstart -k "$service"; then
    molt_error "karabiner: could not restart $MOLT_KARABINER_AGENT, so it may not see changes to karabiner.json; run: launchctl kickstart -k $service"
    return 1
  fi
  molt_info "karabiner: restarted $MOLT_KARABINER_AGENT, so it watches the linked karabiner.json"
}

karabiner_check() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "karabiner: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -n "$user_repo" ]] || return 0
  molt_report_link_faults molt_info "karabiner: " "$(_karabiner_links "$user_repo")"
}

karabiner_install() {
  local user_repo links source target made_link=true
  if [[ "$(molt_platform)" != "macos" ]]; then
    molt_debug "karabiner: only applicable on macOS"
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  links="$(_karabiner_links "$user_repo")"
  if [[ -n "$links" ]]; then
    IFS=$'\t' read -r source target <<< "$links"
    if molt_link_points_to "$target" "$source"; then
      made_link=false
    fi
    _karabiner_adopt "$source" "$target" || return 1
    molt_link_all "$links" || return 1
    if [[ "$made_link" == true ]]; then
      _karabiner_restart_agent || return 1
    fi
  fi
  molt_info "Liberator complete: karabiner"
}

karabiner_verify() {
  local user_repo
  if [[ "$(molt_platform)" != "macos" ]]; then
    return 0
  fi
  user_repo="$(molt_find_user_repo)" || return 1
  molt_report_link_faults molt_error "VERIFY FAIL: karabiner: " "$(_karabiner_links "$user_repo")" || return 1
  molt_info "Verified: karabiner liberator is fully operational"
}
