#!/usr/bin/env bash
# npm.sh — Liberator: npm's cache out of $HOME
# npm caches under ~/.npm unless told otherwise, and npx, which the status line
# runs at every refresh, fills it there on every sleeve (issue 0031). ~/.npmrc
# is the one setting every npm reads, from a terminal or a GUI child alike, so
# this renders it from templates/npm/npmrc.tmpl, keeping the user's lines above
# its marker. Nothing here removes ~/.npm: it is data, left for the user.

_npm_template() { echo "${MOLT_ROOT}/templates/npm/npmrc.tmpl"; }
_npm_rc() { echo "$HOME/.npmrc"; }

# Where npm's cache goes: beside the native installer's ~/.cache/claude.
_npm_cache_dir() { echo "${XDG_CACHE_HOME:-$HOME/.cache}/npm"; }

# True when ~/.npmrc is missing, its template or vars.sh moved since it was
# rendered, the cache it names is not _npm_cache_dir, which XDG_CACHE_HOME can
# move and no digest covers, or it is not mode 600.
_npm_rc_stale() {
  local rc; rc="$(_npm_rc)"
  molt_render_stale "$(_npm_template)" "$rc" && return 0
  grep -qxF "cache=$(_npm_cache_dir)" "$rc" || return 0
  [[ "$(molt_file_mode "$rc")" != 600 ]]
}

# molt_render_place keeps the lines above the marker only of a file that
# carries it, so an ~/.npmrc molt has not rendered, hv's allow-scripts line in
# it, would go whole to the backup. Its lines go above the marker in the render
# at ${1}.molt-tmp instead, but for a cache line of its own, which the render
# replaces; the file is still backed up, as any regular file is. A link is read
# through, since molt_render_place removes it with no backup.
_npm_adopt() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  ! grep -qF '@@MOLT:BEGIN@@' "$rc" || return 0
  if ! { awk '!/^[[:space:]]*cache[[:space:]]*=/' "$rc" && cat "${rc}.molt-tmp"; } > "${rc}.molt-tmp2" \
      || ! mv -f "${rc}.molt-tmp2" "${rc}.molt-tmp"; then
    rm -f "${rc}.molt-tmp" "${rc}.molt-tmp2"
    molt_error "npm: could not keep the lines of ~/.npmrc above the marker, so it was not rendered"
    return 1
  fi
}

npm_check() {
  if ! command -v npm &>/dev/null; then
    molt_info "npm: npm is not installed, so there is nothing to configure"
    return 0
  fi
  if [[ -d "$HOME/.npm" ]]; then
    molt_info "npm: ~/.npm is npm's old cache, left for you to remove once ~/.npmrc names $(molt_tilde "$(_npm_cache_dir)")"
  fi
  if _npm_rc_stale; then
    molt_info "npm: ~/.npmrc does not name $(molt_tilde "$(_npm_cache_dir)") as npm's cache"
    return 1
  fi
  return 0
}

npm_install() {
  if ! command -v npm &>/dev/null; then
    molt_info "npm: npm is not installed, so there is nothing to configure"
    molt_info "Liberator complete: npm"
    return 0
  fi
  local rc template
  rc="$(_npm_rc)"
  template="$(_npm_template)"
  MOLT_NPM_CACHE_DIR="$(_npm_cache_dir)"
  export MOLT_NPM_CACHE_DIR
  # An npmrc can hold a registry token, so no copy of it is written readable
  # by others, and the file is made 600 whatever mode it had.
  (
    umask 077
    molt_render_tmp "$template" "$rc" && _npm_adopt "$rc" \
      && molt_render_place "$template" "$rc"
  ) || return 1
  if ! chmod 600 "$rc"; then
    molt_error "npm: could not make ~/.npmrc mode 600"
    return 1
  fi
  molt_info "Liberator complete: npm"
}

# The cache npm reads, from `npm config list` on stdin: the cache line not
# commented out, as npm comments out each one another layer overrides. Nothing
# when no layer sets it. npm 12 refuses `npm config get cache`, the option
# being protected, and lists it still.
_npm_listed_cache() {
  sed -n 's/^cache = "\(.*\)"$/\1/p'
}

npm_verify() {
  if ! command -v npm &>/dev/null; then
    molt_info "Verified: npm is not installed, so nothing was checked"
    return 0
  fi
  local want list have
  want="$(_npm_cache_dir)"
  if ! list="$(npm config list 2>/dev/null)"; then
    molt_error "VERIFY FAIL: npm config list failed"
    return 1
  fi
  have="$(_npm_listed_cache <<< "$list")"
  if [[ "$have" != "$want" ]]; then
    molt_error "VERIFY FAIL: npm's cache is ${have:-its default, ~/.npm}, not $(molt_tilde "$want")"
    return 1
  fi
  molt_info "Verified: npm caches in $(molt_tilde "$want")"
}
