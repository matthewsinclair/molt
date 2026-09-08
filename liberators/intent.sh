#!/usr/bin/env bash
# intent.sh — Liberator: Intent project management framework
# Frees you from unstructured project planning.

# Find the repo BY THE REPO, not by one of its binaries.
#
# This probed for bin/intent, which answered two different questions with one
# test: "is the Intent repo here?" and "is there something to link?". Intent
# carries an unexecuted decision to rebind off bin/intent and then delete it;
# the moment that lands, this returns 1 for a repo sitting right there and
# intent_install tells the user to clone what they already have. A repo is
# identified by being a repo -- a checkout marker or its Intent config.
_intent_find_repo() {
  [[ -n "${MOLT_INTENT_HOME}" ]] || return 1
  [[ -d "${MOLT_INTENT_HOME}" ]] || return 1
  if [[ -e "${MOLT_INTENT_HOME}/.git" ]] ||
     [[ -f "${MOLT_INTENT_HOME}/intent/.config/config.json" ]]; then
    echo "${MOLT_INTENT_HOME}"
    return 0
  fi
  return 1
}

# The dispatcher this liberator should link, given a repo.
#
# Intent v3 is a Rust binary; v2 was a bash script at bin/intent. Preferring the
# built binary is correct today, correct after Intent's flip, and correct after
# it deletes the v2 script -- without Molt needing to know which has happened.
#
# REMOVAL TRIGGER, stated as a checkable condition rather than an event so it
# does not depend on anyone remembering what the event was:
#
#     remove the fallback when [[ ! -f "$INTENT_HOME/bin/intent" ]]
#
# Two candidate targets for one link is two code paths for one concern, and that
# is only tolerable while the transition is genuinely in flight. The risk is not
# the fallback existing; it is the fallback becoming permanent furniture because
# nothing ever says when it expires.
#
# Prefer the release binary ALWAYS. The v2 script does not refuse a v3 tree: its
# guard compares the project version against $INTENT_HOME/VERSION, and because
# bin/intent lives inside the v3 repo that reads 3.0.0, so it compares 3.0.0 to
# itself and operates. Under v3 the markdown is a generated view, so v2's writes
# land where the database has no row and the next regeneration discards them
# without a word. The fallback must fire only where the release binary is
# genuinely absent.
_intent_dispatcher() {
  local repo="$1"
  if [[ -x "$repo/native/rust/target/release/intent" ]]; then
    echo "$repo/native/rust/target/release/intent"
    return 0
  fi
  if [[ -f "$repo/bin/intent" ]]; then
    echo "$repo/bin/intent"
    return 0
  fi
  return 1
}

intent_repo() { _intent_find_repo; }
intent_repo_git_commands() { echo "pull status log diff fetch"; }

intent_check() {
  local ok=0

  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_info "intent: repo not found"
    return 1
  fi

  local dispatcher
  if ! dispatcher="$(_intent_dispatcher "$repo")"; then
    # Repo present, nothing built. A DIFFERENT failure from "repo not found",
    # and it needs a different instruction -- see intent_install.
    molt_warn "intent: repo at $repo has no built dispatcher"
    return 1
  fi

  if ! molt_link_healthy "$MOLT_LOCAL_BIN/intent"; then
    molt_info "intent: $MOLT_LOCAL_BIN/intent $(molt_link_fault "$MOLT_LOCAL_BIN/intent")"
    ok=1
  elif ! molt_link_points_to "$MOLT_LOCAL_BIN/intent" "$dispatcher"; then
    # Resolves, but not to what _install creates. Reporting ok here means
    # reporting on a link this liberator does not govern.
    molt_warn "intent: $MOLT_LOCAL_BIN/intent resolves to $(_molt_realpath "$MOLT_LOCAL_BIN/intent")"
    molt_warn "        but this liberator installs $dispatcher. Not repairing it:"
    molt_warn "        the link was placed by something else and may be deliberate."
  fi

  # Whatever is linked, PATH may resolve a different binary entirely -- a brew
  # install lands at $(brew --prefix)/bin, ahead of both ~/.local/bin and ~/bin.
  _intent_warn_path_shadow

  return $ok
}

# Warn when the intent on PATH is not the one this liberator manages.
_intent_warn_path_shadow() {
  local on_path
  on_path="$(command -v intent 2>/dev/null)" || return 0
  [[ -n "$on_path" ]] || return 0
  if [[ "$(_molt_realpath "$on_path")" != "$(_molt_realpath "$MOLT_LOCAL_BIN/intent")" ]]; then
    molt_warn "intent: PATH resolves intent to ${on_path}, not $MOLT_LOCAL_BIN/intent."
    molt_warn "        This liberator manages a symlink that nothing is using."
  fi
}

intent_install() {
  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_error "Intent repo not found at: ${MOLT_INTENT_HOME}"
    molt_error "Clone it: git clone <intent-repo-url> ${MOLT_INTENT_HOME}"
    return 1
  fi

  molt_info "Found Intent at: $repo"

  local dispatcher
  if ! dispatcher="$(_intent_dispatcher "$repo")"; then
    molt_error "Intent repo at $repo has no dispatcher to link."
    molt_error "Build it: cd $repo/native/rust && cargo build --release"
    return 1
  fi

  mkdir -p "$MOLT_LOCAL_BIN"

  # Link the intent dispatcher into ~/bin
  molt_link "$dispatcher" "$MOLT_LOCAL_BIN/intent"

  molt_info "Liberator complete: intent"
}

intent_verify() {
  local errors=0

  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_error "VERIFY FAIL: Intent repo not found"
    return 1
  fi

  local dispatcher
  if ! dispatcher="$(_intent_dispatcher "$repo")"; then
    molt_error "VERIFY FAIL: Intent repo at $repo has no built dispatcher"
    return 1
  fi

  if ! molt_link_healthy "$MOLT_LOCAL_BIN/intent"; then
    molt_error "VERIFY FAIL: $MOLT_LOCAL_BIN/intent $(molt_link_fault "$MOLT_LOCAL_BIN/intent")"
    errors=1
  elif ! molt_link_points_to "$MOLT_LOCAL_BIN/intent" "$dispatcher"; then
    # Verify asked only whether the link RESOLVED, so it passed on exactly the
    # mismatched state intent_check warns about: two functions, two answers,
    # one estate. A resolving link to a binary this liberator never installed
    # is not "fully operational".
    molt_error "VERIFY FAIL: $MOLT_LOCAL_BIN/intent resolves to $(_molt_realpath "$MOLT_LOCAL_BIN/intent")"
    molt_error "             but this liberator installs $dispatcher"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: intent liberator is fully operational"
  fi
  return $errors
}

intent_upgrade() {
  local repo
  if ! repo="$(_intent_find_repo)"; then
    molt_error "Intent repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling Intent repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "Intent repo updated."
  else
    molt_warn "Intent pull skipped (not on tracking branch or already up-to-date)."
  fi
}
