#!/usr/bin/env bash
# molt.sh — Core functions for MOLT framework
# The Highlander Rule: this is the ONE place for shared utilities.

set -euo pipefail

# Source constants (single source of truth for all configurable values)
MOLT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=constants.sh
source "${MOLT_LIB_DIR}/constants.sh"

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

# --- Manifest (molt.toml) ---

# Find the molt.toml manifest. Checks instance-specific first, then repo root.
molt_find_manifest() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -z "$user_repo" ]] && return 1

  local hostname
  hostname="$(hostname)"

  # Instance-specific overrides repo-level
  local instance_manifest="$user_repo/instances/$hostname/molt.toml"
  if [[ -f "$instance_manifest" ]]; then
    echo "$instance_manifest"
    return 0
  fi

  # Repo-level default
  local repo_manifest="$user_repo/molt.toml"
  if [[ -f "$repo_manifest" ]]; then
    echo "$repo_manifest"
    return 0
  fi

  return 1
}

# Parse enabled liberators from molt.toml.
# Returns one liberator name per line for enabled liberators on this platform.
# If no manifest found, returns empty (caller falls back to directory scan).
molt_enabled_liberators() {
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null || echo "")"
  [[ -z "$manifest" ]] && return 1

  local platform
  platform="$(molt_platform)"

  # Simple TOML parser for [[liberator]] blocks.
  # Reads name, enabled, and os fields from each block.
  awk -v platform="$platform" '
    /^\[\[liberator\]\]/ {
      if (name != "" && enabled == "true" && os_match) {
        print name
      }
      name = ""
      enabled = "true"  # default to enabled if not specified
      os_match = 1       # default to all platforms if not specified
      os_seen = 0
    }
    /^name[[:space:]]*=/ {
      gsub(/^name[[:space:]]*=[[:space:]]*"/, "")
      gsub(/".*/, "")
      name = $0
    }
    /^enabled[[:space:]]*=/ {
      if ($0 ~ /false/) enabled = "false"
      else enabled = "true"
    }
    /^os[[:space:]]*=/ {
      os_seen = 1
      if ($0 ~ platform) os_match = 1
      else os_match = 0
    }
    END {
      if (name != "" && enabled == "true" && os_match) {
        print name
      }
    }
  ' "$manifest"
}

# --- Stack Discovery ---

molt_find_user_repo() {
  for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
    if [[ -d "$path/config" ]]; then
      echo "$path"
      return 0
    fi
  done
  molt_error "Could not find user config repo. Searched:"
  for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
    molt_error "  $path"
  done
  return 1
}
