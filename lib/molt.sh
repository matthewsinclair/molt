#!/usr/bin/env bash
# molt.sh — Core functions for MOLT framework
# The Highlander Rule: this is the ONE place for shared utilities.

set -euo pipefail

MOLT_VERSION="0.1.0"
MOLT_NAME="MOLT"

# --- Logging ---

molt_log() {
  local level="$1"; shift
  local prefix
  case "$level" in
    info)  prefix="Zen:" ;;
    warn)  prefix="Zen [warning]:" ;;
    error) prefix="Zen [error]:" ;;
    debug) [[ "${MOLT_DEBUG:-0}" == "1" ]] || return 0; prefix="Zen [debug]:" ;;
    *)     prefix="Zen:" ;;
  esac
  echo "$prefix $*"
}

molt_info()  { molt_log info "$@"; }
molt_warn()  { molt_log warn "$@"; }
molt_error() { molt_log error "$@"; }
molt_debug() { molt_log debug "$@"; }

# --- Platform Detection ---

molt_platform() {
  local uname_s
  uname_s="$(uname -s)"
  case "$uname_s" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *)      echo "unknown" ;;
  esac
}

molt_distro() {
  if [[ "$(molt_platform)" != "linux" ]]; then
    echo "none"
    return
  fi
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

molt_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    *)       echo "$arch" ;;
  esac
}

# --- Dependency Checks ---

molt_require() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    molt_error "Required command not found: $cmd"
    return 1
  fi
}

molt_require_all() {
  local failed=0
  for cmd in "$@"; do
    molt_require "$cmd" || failed=1
  done
  return $failed
}

# --- Symlink Management ---

molt_link() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    molt_error "Source does not exist: $source"
    return 1
  fi

  # If target already points to source, nothing to do
  if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
    molt_debug "Already linked: $target -> $source"
    return 0
  fi

  # If target exists and is not a symlink, back it up
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    local backup="${target}.molt-backup.$(date +%Y%m%d%H%M%S)"
    molt_warn "Backing up existing file: $target -> $backup"
    mv "$target" "$backup"
  fi

  # Remove existing symlink if it points elsewhere
  if [[ -L "$target" ]]; then
    rm "$target"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")"

  ln -s "$source" "$target"
  molt_info "Linked: $target -> $source"
}

# --- Stack Discovery ---

molt_find_user_repo() {
  local user="${1:-$(whoami)}"
  local search_paths=(
    "$HOME/Devel/prj/molt-${user}"
    "$HOME/molt-${user}"
    "$HOME/.molt-${user}"
  )
  for path in "${search_paths[@]}"; do
    if [[ -d "$path/config" ]]; then
      echo "$path"
      return 0
    fi
  done
  molt_error "Could not find molt-${user} repo"
  return 1
}
