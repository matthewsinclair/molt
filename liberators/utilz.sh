#!/usr/bin/env bash
# utilz.sh — Liberator: Utilz framework
# Frees you from writing the same shell utilities twice.

_utilz_find_repo() {
  # Check MOLT_UTILZ_HOME from constants.sh first
  if [[ -d "${MOLT_UTILZ_HOME}/bin" ]] && [[ -f "${MOLT_UTILZ_HOME}/bin/utilz" ]]; then
    echo "${MOLT_UTILZ_HOME}"
    return 0
  fi
  return 1
}

utilz_check() {
  local ok=0

  # Is the repo present?
  local repo
  if ! repo="$(_utilz_find_repo)"; then
    molt_info "utilz: repo not found"
    return 1
  fi

  # Is utilz linked into ~/bin?
  if [[ ! -L "$MOLT_LOCAL_BIN/utilz" ]]; then
    molt_info "utilz: not linked in ~/bin"
    ok=1
  fi

  # Is bats installed? (needed for utilz test)
  if ! command -v bats &>/dev/null; then
    molt_info "utilz: bats-core not installed"
    ok=1
  fi

  return $ok
}

utilz_install() {
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
  molt_link "$repo/bin/utilz" "$MOLT_LOCAL_BIN/utilz"

  # Link all utility symlinks from the Utilz bin/ directory
  for link in "$repo/bin/"*; do
    [[ -L "$link" ]] || continue
    local name
    name="$(basename "$link")"
    molt_link "$repo/bin/$name" "$MOLT_LOCAL_BIN/$name"
  done

  # Set UTILZ_HOME in environment if not already handled
  # (zshrc should pick this up — we just inform)
  molt_info "Ensure UTILZ_HOME=$repo is in your shell config"

  # Install bats-core if not present
  if ! command -v bats &>/dev/null; then
    local platform
    platform="$(molt_platform)"
    case "$platform" in
      linux)
        local distro
        distro="$(molt_distro)"
        case "$distro" in
          ubuntu|debian) sudo apt install -y bats ;;
          fedora|rhel|centos) sudo dnf install -y bats ;;
          arch) sudo pacman -S --noconfirm bash-bats ;;
          *)
            molt_warn "Install bats-core manually: https://bats-core.readthedocs.io"
            ;;
        esac
        ;;
      macos) brew install bats-core ;;
    esac
  fi

  molt_info "Liberator complete: utilz"
}

utilz_verify() {
  local errors=0

  if ! _utilz_find_repo &>/dev/null; then
    molt_error "VERIFY FAIL: Utilz repo not found"
    errors=1
  fi

  if [[ ! -L "$MOLT_LOCAL_BIN/utilz" ]]; then
    molt_error "VERIFY FAIL: utilz not linked in ~/bin"
    errors=1
  fi

  if ! command -v bats &>/dev/null; then
    molt_error "VERIFY FAIL: bats-core not installed"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: utilz liberator is fully operational"
  fi
  return $errors
}
