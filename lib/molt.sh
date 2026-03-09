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

# --- Template Rendering ---

molt_render() {
  local template="$1"
  local target="$2"

  if [[ ! -f "$template" ]]; then
    molt_error "Template not found: $template"
    return 1
  fi

  # Load instance vars
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"
  local vars_file="$user_repo/instances/$hostname/vars.sh"

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")"

  if [[ -f "$vars_file" ]]; then
    # Source vars in a subshell so exports don't leak into framework
    (
      source "$vars_file"
      envsubst < "$template"
    ) > "${target}.molt-tmp"
  else
    molt_warn "No vars.sh for instance $hostname — rendering template with env only"
    envsubst < "$template" > "${target}.molt-tmp"
  fi

  # Handle existing file before replacing
  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    if [[ -L "$target" ]]; then
      # Symlinks are removed, not backed up (they cause permission issues in
      # directories like ~/.ssh where sshd demands regular files with strict perms)
      molt_info "Removing existing symlink: $target"
      rm "$target"
    elif [[ -f "${target}.molt-rendered" ]]; then
      # Previously rendered by molt — check if content actually changed
      if ! diff -q "$target" "${target}.molt-tmp" &>/dev/null; then
        local backup="${target}.molt-backup.$(date +%Y%m%d%H%M%S)"
        molt_warn "Rendered file changed since last render, backing up: $target -> $backup"
        mv "$target" "$backup"
      fi
    else
      # Regular file that wasn't rendered by molt — back up
      local backup="${target}.molt-backup.$(date +%Y%m%d%H%M%S)"
      molt_warn "Backing up existing file: $target -> $backup"
      mv "$target" "$backup"
    fi
  fi

  mv "${target}.molt-tmp" "$target"

  # Leave a marker so we know this file was rendered (not symlinked).
  echo "rendered $(date -Iseconds) from $template" > "${target}.molt-rendered"

  # If parent directory is locked down (eg ~/.ssh at 700), restrict file perms
  # to match. sshd and similar tools reject files with open permissions.
  local parent_perms
  parent_perms="$(stat -c '%a' "$(dirname "$target")" 2>/dev/null || echo "755")"
  if [[ "$parent_perms" == "700" ]]; then
    chmod 600 "$target" "${target}.molt-rendered"
  fi

  molt_info "Rendered: $template -> $target"
}

molt_install_config() {
  local source="$1"    # relative path: "config/ssh/config"
  local target="$2"    # absolute path: "$HOME/.ssh/config"

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  local full_source="$user_repo/$source"
  local template="${full_source}.tmpl"

  if [[ -f "$template" ]]; then
    molt_render "$template" "$target"
  elif [[ -f "$full_source" ]]; then
    molt_link "$full_source" "$target"
  else
    molt_warn "Config not found: $source (checked template and static)"
    return 1
  fi
}

# --- Manifest (molt.toml) ---

# Find the molt.toml manifest. Checks instance-specific first, then repo root.
molt_find_manifest() {
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  [[ -z "$user_repo" ]] && return 1

  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"

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

# --- CLI Commands ---

cmd_version() {
  echo "${MOLT_NAME} v${MOLT_VERSION}"
}

cmd_list() {
  echo "${MOLT_NAME} v${MOLT_VERSION} — Liberators"
  echo ""

  # Get enabled list from manifest (if available)
  local enabled_list=" "
  local disabled_list=" "
  local has_manifest=0
  local manifest_liberators
  if manifest_liberators="$(molt_enabled_liberators 2>/dev/null)"; then
    has_manifest=1
    while IFS= read -r lib; do
      [[ -n "$lib" ]] && enabled_list="${enabled_list}${lib} "
    done <<< "$manifest_liberators"
  fi

  # Also parse disabled liberators from manifest directly
  if [[ "$has_manifest" -eq 1 ]]; then
    local manifest
    manifest="$(molt_find_manifest 2>/dev/null || echo "")"
    if [[ -n "$manifest" ]]; then
      local all_names
      all_names="$(awk '/^name[[:space:]]*=/ { gsub(/^name[[:space:]]*=[[:space:]]*"/, ""); gsub(/".*/, ""); print }' "$manifest")"
      while IFS= read -r lib; do
        [[ -z "$lib" ]] && continue
        if [[ "$enabled_list" != *" ${lib} "* ]]; then
          disabled_list="${disabled_list}${lib} "
        fi
      done <<< "$all_names"
    fi
  fi

  for lib in $(liberator_list); do
    local status_str
    if [[ "$has_manifest" -eq 1 ]]; then
      if [[ "$disabled_list" == *" ${lib} "* ]]; then
        status_str="disabled"
      elif [[ "$enabled_list" == *" ${lib} "* ]]; then
        if liberator_load "$lib" &>/dev/null && liberator_check "$lib" &>/dev/null; then
          status_str="installed"
        else
          status_str="not installed"
        fi
      else
        status_str="not in manifest"
      fi
    else
      if liberator_load "$lib" &>/dev/null && liberator_check "$lib" &>/dev/null; then
        status_str="installed"
      else
        status_str="not installed"
      fi
    fi
    echo "  $lib: $status_str"
  done
}

cmd_doctor() {
  echo "${MOLT_NAME} v${MOLT_VERSION} — Doctor"
  echo ""

  local total=9
  local step=0
  local warnings=0

  # 1. MOLT_HOME is valid
  step=$((step + 1))
  if [[ -x "${MOLT_ROOT:-}/bin/molt" && -d "${MOLT_ROOT:-}/lib" ]]; then
    echo "[$step/$total] Checking MOLT_ROOT... ✓ $MOLT_ROOT"
  else
    echo "[$step/$total] Checking MOLT_ROOT... ✗ invalid or not found"
    warnings=$((warnings + 1))
  fi

  # 2. Directory structure
  step=$((step + 1))
  local dirs_ok=1
  for dir in lib liberators test; do
    if [[ ! -d "${MOLT_ROOT}/$dir" ]]; then
      dirs_ok=0
    fi
  done
  if [[ "$dirs_ok" -eq 1 ]]; then
    echo "[$step/$total] Checking directory structure... ✓ lib/ liberators/ test/"
  else
    echo "[$step/$total] Checking directory structure... ⚠ missing directories"
    warnings=$((warnings + 1))
  fi

  # 3. User stack repo
  step=$((step + 1))
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" && -d "$user_repo" ]]; then
    echo "[$step/$total] Checking user stack repo... ✓ $user_repo"
  else
    echo "[$step/$total] Checking user stack repo... ✗ not found"
    warnings=$((warnings + 1))
  fi

  # 4. Manifest
  step=$((step + 1))
  local manifest
  manifest="$(molt_find_manifest 2>/dev/null || echo "")"
  if [[ -n "$manifest" && -f "$manifest" ]]; then
    echo "[$step/$total] Checking manifest... ✓ $manifest"
  else
    echo "[$step/$total] Checking manifest... ⚠ no molt.toml found"
    warnings=$((warnings + 1))
  fi

  # 5. Liberators: each .sh is executable, has _check function
  step=$((step + 1))
  local lib_errors=0
  local lib_count=0
  for lib in $(liberator_list); do
    lib_count=$((lib_count + 1))
    local script="${MOLT_LIBERATORS_DIR}/${lib}.sh"
    if [[ ! -f "$script" ]]; then
      lib_errors=$((lib_errors + 1))
      continue
    fi
    # Check for _check function (source and test)
    if ! grep -q "^${lib}_check()" "$script" 2>/dev/null; then
      lib_errors=$((lib_errors + 1))
    fi
  done
  if [[ "$lib_errors" -eq 0 ]]; then
    echo "[$step/$total] Checking liberators... ✓ $lib_count liberators, all have _check"
  else
    echo "[$step/$total] Checking liberators... ⚠ $lib_errors of $lib_count have issues"
    warnings=$((warnings + 1))
  fi

  # 6. Enabled liberator status
  step=$((step + 1))
  if [[ -n "$manifest" ]]; then
    local enabled
    enabled="$(molt_enabled_liberators 2>/dev/null || echo "")"
    local enabled_count=0
    local installed_count=0
    while IFS= read -r lib; do
      [[ -z "$lib" ]] && continue
      enabled_count=$((enabled_count + 1))
      if liberator_load "$lib" &>/dev/null && liberator_check "$lib" &>/dev/null; then
        installed_count=$((installed_count + 1))
      fi
    done <<< "$enabled"
    echo "[$step/$total] Checking enabled liberators... ✓ $installed_count/$enabled_count installed"
  else
    echo "[$step/$total] Checking enabled liberators... ⚠ no manifest (skipped)"
    warnings=$((warnings + 1))
  fi

  # 7. External dependencies
  step=$((step + 1))
  local deps_ok=1
  local missing_deps=""
  for dep in bats; do
    if ! command -v "$dep" &>/dev/null; then
      deps_ok=0
      missing_deps="$missing_deps $dep"
    fi
  done
  if [[ "$deps_ok" -eq 1 ]]; then
    echo "[$step/$total] Checking external dependencies... ✓ bats"
  else
    echo "[$step/$total] Checking external dependencies... ⚠ missing:$missing_deps"
    warnings=$((warnings + 1))
  fi

  # 8. SSH key (check common names + any key referenced in SSH config)
  step=$((step + 1))
  local ssh_key_found=""
  for keyname in id_ed25519 id_rsa; do
    if [[ -f "$HOME/.ssh/$keyname" ]]; then
      ssh_key_found="$keyname"
      break
    fi
  done
  if [[ -z "$ssh_key_found" ]] && [[ -f "$HOME/.ssh/config" ]]; then
    # Check keys referenced in SSH config
    local referenced_key
    referenced_key="$(grep -m1 'IdentityFile' "$HOME/.ssh/config" 2>/dev/null | awk '{print $2}' | sed "s|~|$HOME|" || true)"
    if [[ -n "$referenced_key" ]] && [[ -f "$referenced_key" ]]; then
      ssh_key_found="$(basename "$referenced_key")"
    fi
  fi
  if [[ -n "$ssh_key_found" ]]; then
    echo "[$step/$total] Checking SSH key... ✓ ~/.ssh/$ssh_key_found"
  else
    echo "[$step/$total] Checking SSH key... ⚠ no SSH key found"
    warnings=$((warnings + 1))
  fi

  # 9. GitHub auth
  step=$((step + 1))
  local gh_auth_output
  if gh_auth_output="$(timeout 5 ssh -T git@github.com 2>&1)"; then
    :
  fi
  if echo "$gh_auth_output" | grep -q "successfully authenticated"; then
    local gh_user
    gh_user="$(echo "$gh_auth_output" | grep -o 'Hi [^!]*' | sed 's/Hi //')"
    echo "[$step/$total] Checking GitHub auth... ✓ authenticated as $gh_user"
  else
    echo "[$step/$total] Checking GitHub auth... ⚠ not authenticated"
    warnings=$((warnings + 1))
  fi

  echo ""
  if [[ "$warnings" -eq 0 ]]; then
    echo "All checks passed."
  else
    echo "$warnings warning(s). Review above for details."
  fi
}

cmd_test() {
  local target="${1:-}"

  if ! command -v bats &>/dev/null; then
    molt_error "bats is required to run tests. Install via: utilz or apt install bats"
    return 1
  fi

  local test_dir="${MOLT_ROOT}/test"
  if [[ ! -d "$test_dir" ]]; then
    molt_error "Test directory not found: $test_dir"
    return 1
  fi

  if [[ -n "$target" ]]; then
    # Run specific liberator test
    local target_file="$test_dir/liberators/${target}.bats"
    if [[ ! -f "$target_file" ]]; then
      molt_error "Test not found: $target_file"
      return 1
    fi
    bats "$target_file"
  else
    # Run all tests
    local test_files=()
    for f in "$test_dir"/*.bats; do
      [[ -f "$f" ]] && test_files+=("$f")
    done
    for f in "$test_dir"/liberators/*.bats; do
      [[ -f "$f" ]] && test_files+=("$f")
    done
    if [[ ${#test_files[@]} -eq 0 ]]; then
      molt_error "No test files found"
      return 1
    fi
    bats "${test_files[@]}"
  fi
}

# --- Upgrade ---

cmd_upgrade() {
  local dry_run=false
  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
  fi

  local old_version="$MOLT_VERSION"

  echo "${MOLT_NAME} v${MOLT_VERSION} — Upgrade"
  echo ""

  # 1. Check framework repo for uncommitted changes
  molt_info "Checking framework repo: $MOLT_ROOT"
  if ! git -C "$MOLT_ROOT" diff --quiet 2>/dev/null || ! git -C "$MOLT_ROOT" diff --cached --quiet 2>/dev/null; then
    molt_error "Framework repo has uncommitted changes. Commit or stash first."
    return 1
  fi

  # 2. Find and check user config repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || {
    molt_error "Cannot upgrade without a user config repo."
    return 1
  }
  molt_info "Checking user config repo: $user_repo"
  if ! git -C "$user_repo" diff --quiet 2>/dev/null || ! git -C "$user_repo" diff --cached --quiet 2>/dev/null; then
    molt_error "User config repo has uncommitted changes. Commit or stash first."
    return 1
  fi

  # 3. Pull framework repo
  echo ""
  molt_info "Pulling framework repo..."
  if git -C "$MOLT_ROOT" pull --ff-only 2>/dev/null; then
    molt_info "Framework repo updated."
  else
    molt_warn "Framework pull skipped (not on tracking branch or already up-to-date)."
  fi

  # 4. Pull user config repo
  molt_info "Pulling user config repo..."
  if git -C "$user_repo" pull --ff-only 2>/dev/null; then
    molt_info "User config repo updated."
  else
    molt_warn "User config pull skipped (not on tracking branch or already up-to-date)."
  fi

  # 5. Re-source constants to pick up any version change
  source "${MOLT_LIB_DIR}/constants.sh"
  if [[ "$old_version" != "$MOLT_VERSION" ]]; then
    echo ""
    molt_info "Version changed: v${old_version} -> v${MOLT_VERSION}"
  fi

  # 6. Resleeve
  echo ""
  if $dry_run; then
    molt_info "Dry run — showing what resleeve would do:"
    echo ""
    cmd_resleeve --dry-run
  else
    molt_info "Running resleeve..."
    echo ""
    cmd_resleeve
  fi
}

# --- Stack Discovery ---

molt_find_user_repo() {
  for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
    if [[ -d "$path/config" ]]; then
      echo "$path"
      return 0
    fi
  done
  molt_error "Could not find user config repo (molt-$(whoami))."
  if [[ -z "$MOLT_PROJECTS_DIR" ]]; then
    molt_error "Set MOLT_PROJECTS_DIR to the directory containing your molt repos, eg:"
    molt_error "  export MOLT_PROJECTS_DIR=\$HOME/Devel/prj"
  else
    molt_error "Searched:"
    for path in "${MOLT_USER_REPO_SEARCH_PATHS[@]}"; do
      molt_error "  $path"
    done
  fi
  return 1
}
