#!/usr/bin/env bash
# web.sh — Liberator: web scraper for LLMs
# Frees you from copy-pasting web content.

# Locate the web repo by a repo marker (not a built binary — those are
# platform-specific and may not exist on a fresh clone).
_web_find_repo() {
  local web_dir="${MOLT_OPT_DIR}/web"
  if [[ -d "$web_dir" ]] && { [[ -f "$web_dir/go.mod" ]] || [[ -d "$web_dir/.git" ]]; }; then
    echo "$web_dir"
    return 0
  fi
  return 1
}

# Resolve the binary to link: a locally built ./web if present, otherwise the
# prebuilt platform binary web-<os>-<arch> shipped in the repo. Echoes the
# path, or returns 1 if none is usable.
_web_binary() {
  local repo="$1"
  if [[ -x "$repo/web" ]]; then
    echo "$repo/web"
    return 0
  fi
  local os
  case "$(molt_platform)" in
    macos) os="darwin" ;;
    linux) os="linux" ;;
    *)     return 1 ;;
  esac
  local arch candidate
  arch="$(molt_arch)"
  candidate="$repo/web-${os}-${arch}"
  if [[ -x "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi
  return 1
}

web_repo() { _web_find_repo; }
web_repo_git_commands() { echo "pull status log diff fetch"; }

web_check() {
  local ok=0

  if ! _web_find_repo &>/dev/null; then
    molt_info "web: repo not found"
    return 1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/web" ]]; then
    molt_info "web: not linked in ~/bin"
    ok=1
  fi

  return $ok
}

web_install() {
  local repo
  if ! repo="$(_web_find_repo)"; then
    molt_error "web repo not found at: ${MOLT_OPT_DIR}/web"
    molt_error "Clone it: git clone <web-repo-url> ${MOLT_OPT_DIR}/web"
    return 1
  fi

  local bin
  if ! bin="$(_web_binary "$repo")"; then
    molt_error "web: no usable binary in $repo"
    molt_error "Expected a built ./web or a prebuilt web-<os>-<arch> for this platform."
    molt_error "Build it (eg 'make build' in $repo) then re-run."
    return 1
  fi

  molt_info "Found web binary: $bin"

  mkdir -p "$MOLT_LOCAL_BIN"
  molt_link "$bin" "$MOLT_LOCAL_BIN/web"

  molt_info "Liberator complete: web"
}

web_verify() {
  local errors=0

  if ! _web_find_repo &>/dev/null; then
    molt_error "VERIFY FAIL: web repo not found"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/web" ]]; then
    molt_error "VERIFY FAIL: web not linked in ~/bin"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: web liberator is fully operational"
  fi
  return $errors
}

web_upgrade() {
  local repo
  if ! repo="$(_web_find_repo)"; then
    molt_error "web repo not found — cannot upgrade"
    return 1
  fi

  molt_info "Pulling web repo..."
  if git -C "$repo" pull --ff-only 2>/dev/null; then
    molt_info "web repo updated."
  else
    molt_warn "web pull skipped (not on tracking branch or already up-to-date)."
  fi
}
