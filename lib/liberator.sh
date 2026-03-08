#!/usr/bin/env bash
# liberator.sh — Liberator loading and execution framework
# Each liberator frees you from a default. This is the runner.

# Directory containing liberator scripts
MOLT_LIBERATORS_DIR="${MOLT_LIBERATORS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../liberators" && pwd)}"

# Track loaded liberators
declare -A _MOLT_LOADED_LIBERATORS 2>/dev/null || true

# --- Liberator Lifecycle ---

liberator_load() {
  local name="$1"
  local script="${MOLT_LIBERATORS_DIR}/${name}.sh"

  if [[ ! -f "$script" ]]; then
    molt_error "Liberator not found: $name (expected $script)"
    return 1
  fi

  # shellcheck source=/dev/null
  source "$script"
  _MOLT_LOADED_LIBERATORS["$name"]=1
  molt_debug "Loaded liberator: $name"
}

liberator_check() {
  local name="$1"

  if [[ -z "${_MOLT_LOADED_LIBERATORS[$name]:-}" ]]; then
    liberator_load "$name" || return 1
  fi

  local check_fn="${name}_check"
  if declare -f "$check_fn" &>/dev/null; then
    "$check_fn"
  else
    molt_warn "Liberator $name has no check function"
    return 1
  fi
}

liberator_run() {
  local name="$1"
  local action="${2:-install}"

  if [[ -z "${_MOLT_LOADED_LIBERATORS[$name]:-}" ]]; then
    liberator_load "$name" || return 1
  fi

  local action_fn="${name}_${action}"
  if declare -f "$action_fn" &>/dev/null; then
    molt_info "Running liberator: $name ($action)"
    "$action_fn"
  else
    molt_error "Liberator $name has no $action function"
    return 1
  fi
}

liberator_verify() {
  local name="$1"

  local verify_fn="${name}_verify"
  if declare -f "$verify_fn" &>/dev/null; then
    "$verify_fn"
  else
    # Fall back to check
    liberator_check "$name"
  fi
}

# --- Batch Operations ---

liberator_run_all() {
  local action="${1:-install}"
  shift
  local liberators=("$@")

  local failed=0
  for lib in "${liberators[@]}"; do
    if ! liberator_run "$lib" "$action"; then
      molt_error "Liberator failed: $lib"
      failed=1
    fi
  done
  return $failed
}

liberator_status_all() {
  local liberators=("$@")

  # Get enabled list from manifest (if available)
  local -A enabled_map
  local manifest_liberators
  if manifest_liberators="$(molt_enabled_liberators 2>/dev/null)"; then
    while IFS= read -r lib; do
      [[ -n "$lib" ]] && enabled_map["$lib"]=1
    done <<< "$manifest_liberators"
  fi

  for lib in "${liberators[@]}"; do
    liberator_load "$lib" 2>/dev/null || continue

    # If manifest exists, show enabled/disabled status
    if [[ ${#enabled_map[@]} -gt 0 ]]; then
      if [[ -z "${enabled_map[$lib]:-}" ]]; then
        echo "  $lib: disabled"
        continue
      fi
    fi

    if liberator_check "$lib" 2>/dev/null; then
      echo "  $lib: installed"
    else
      echo "  $lib: not installed"
    fi
  done
}

# --- Discovery ---

liberator_list() {
  local dir="${MOLT_LIBERATORS_DIR}"
  if [[ ! -d "$dir" ]]; then
    molt_error "Liberators directory not found: $dir"
    return 1
  fi
  for f in "$dir"/*.sh; do
    [[ -f "$f" ]] || continue
    basename "$f" .sh
  done
}
