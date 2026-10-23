#!/usr/bin/env bash
# tiling.sh — Liberator: tiling window management via Tactile
# Frees you from manual window positioning with a Divvy-like grid picker.
#
# Tactile workflow: the activation binding shows the grid overlay, then you type
# two keys to define a rectangle (eg Q,Z = full left column, Q,M = full screen).
# Keyboard maps to a 7x3 grid: QWERTYU=top, ASDFGHJ=middle, ZXCVBNM=bottom.

TACTILE_UUID="tactile@lundal.io"
TACTILE_SCHEMA="org.gnome.shell.extensions.tactile"
TACTILE_EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$TACTILE_UUID"

# gsettings reads Tactile's schema from the system schema dir, where install
# puts a copy of the extension's own. MOLT_SYSTEM_SCHEMA_DIR stands in for it in
# tests.
TACTILE_SCHEMA_XML="$TACTILE_SCHEMA.gschema.xml"
TACTILE_SYSTEM_SCHEMA_DIR="${MOLT_SYSTEM_SCHEMA_DIR:-/usr/share/glib-2.0/schemas}"

# Default activation binding. A sleeve that needs a different one exports
# MOLT_TACTILE_ACTIVATE in its instance vars.sh — the binding is the one piece
# of this liberator that is a per-machine choice, so the value lives there and
# nowhere else.
TACTILE_ACTIVATE_DEFAULT="<Shift><Alt><Super>t"

# The activation binding this sleeve's vars.sh declares, or the default when it
# declares none or there is no user repo. Fails, printing why instead, when
# vars.sh cannot be read: a broken file is not a sleeve that wants the default.
_tiling_activate() {
  local activate status=0
  activate="$(molt_instance_var MOLT_TACTILE_ACTIVATE)" || status=$?
  case "$status" in
    0) echo "${activate:-$TACTILE_ACTIVATE_DEFAULT}" ;;
    3) echo "$TACTILE_ACTIVATE_DEFAULT" ;;
    *) echo "$activate"; return 1 ;;
  esac
}

# Names why the system copy of Tactile's schema is not the installed
# extension's, and prints nothing when it is. Returns non-zero when it cannot
# tell. A stale copy is not harmless: molt's gsettings writes go through it, so
# after a Tactile update they would follow the previous version's keys
# (issue 0014).
_tiling_schema_fault() {
  local ours="$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML"
  local installed="$TACTILE_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
  if [[ ! -f "$ours" ]]; then
    echo "cannot be checked: $ours is missing"
    return 1
  fi
  if [[ ! -f "$installed" ]]; then
    echo "is not installed in $TACTILE_SYSTEM_SCHEMA_DIR"
    return 0
  fi
  # cmp exits 1 when the files differ and 2 when it could not compare them.
  local rc=0
  cmp -s "$ours" "$installed" || rc=$?
  case "$rc" in
    0) ;;
    1) echo "in $TACTILE_SYSTEM_SCHEMA_DIR is not the installed extension's" ;;
    *)
      echo "cannot be checked: cmp could not compare $ours with $installed"
      return 1
      ;;
  esac
}

# Copies the extension's schema into the system schema dir and compiles it
# there. gsettings reads the compiled database, not the XML, so a copy that did
# not compile must not stay behind: the next check would find the XML matching
# and pass over a stale database. The extension's schema is compiled first, as
# a dry run under --strict, because without --strict glib-compile-schemas skips
# a file it cannot parse and still exits 0.
_tiling_install_schema() {
  local ours="$TACTILE_EXT_DIR/schemas/$TACTILE_SCHEMA_XML"
  local installed="$TACTILE_SYSTEM_SCHEMA_DIR/$TACTILE_SCHEMA_XML"
  if ! glib-compile-schemas --strict --dry-run "$TACTILE_EXT_DIR/schemas"; then
    molt_error "tiling: Tactile's own schema does not compile, so it was not installed: $ours"
    return 1
  fi
  local why
  if ! why="$(molt_sudo_install "$ours" "$installed")"; then
    molt_error "tiling: could not install Tactile's gsettings schema into $TACTILE_SYSTEM_SCHEMA_DIR: $why"
    return 1
  fi
  if ! sudo glib-compile-schemas "$TACTILE_SYSTEM_SCHEMA_DIR/"; then
    if why="$(molt_sudo_remove "$installed")"; then
      molt_error "tiling: could not compile the schemas in $TACTILE_SYSTEM_SCHEMA_DIR, so Tactile's copy was taken back out"
    else
      molt_error "tiling: could not compile the schemas in $TACTILE_SYSTEM_SCHEMA_DIR, nor take Tactile's copy back out ($why). Remove $installed by hand, or the next check passes over a stale database"
    fi
    return 1
  fi
}

# Reports, through $1 (molt_info or molt_error) after the prefix $2, why the
# system copy of Tactile's schema is not the extension's. Returns non-zero when
# it reported one.
_tiling_report_schema_fault() {
  local fault
  if ! fault="$(_tiling_schema_fault)" || [[ -n "$fault" ]]; then
    "$1" "${2}Tactile's gsettings schema $fault"
    return 1
  fi
}

tiling_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "tiling: only applicable on Linux"
    return 0
  fi

  if ! command -v gnome-extensions &>/dev/null; then
    molt_debug "tiling: gnome-extensions not available (no GNOME?)"
    return 0
  fi

  # Check Tactile is installed
  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    molt_info "tiling: Tactile extension not installed"
    ok=1
    return $ok
  fi

  # Check Tactile is enabled (may fail before first shell restart). sed rather
  # than grep -P, which BSD grep lacks, so the check runs under test on macOS.
  local state
  state="$(gnome-extensions info "$TACTILE_UUID" 2>/dev/null \
    | sed -n 's/^[[:space:]]*State:[[:space:]]*\([^[:space:]]*\).*/\1/p')" || state=""
  [[ -n "$state" ]] || state="UNKNOWN"
  if [[ "$state" != "ACTIVE" ]] && [[ "$state" != "ENABLED" ]]; then
    molt_info "tiling: Tactile not active (state: $state, may need shell restart)"
    ok=1
  fi

  _tiling_report_schema_fault molt_info "tiling: " || ok=1

  # Check grid is configured as 7x3
  if command -v gsettings &>/dev/null; then
    local col6 row2
    col6="$(gsettings get "$TACTILE_SCHEMA" col-6 2>/dev/null || echo "0")"
    row2="$(gsettings get "$TACTILE_SCHEMA" row-2 2>/dev/null || echo "0")"
    if [[ "$col6" != "1" ]] || [[ "$row2" != "1" ]]; then
      molt_info "tiling: Tactile grid not configured as 7x3"
      ok=1
    fi
  fi

  return $ok
}

tiling_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "tiling: skipping on $platform (Linux only)"
    return 0
  fi

  if ! command -v gnome-extensions &>/dev/null; then
    molt_info "tiling: no GNOME desktop detected, skipping"
    return 0
  fi

  # Check Tactile is installed (we don't install extensions — just configure).
  # The hint asks extensions.gnome.org for the build that fits this shell, as
  # GNOME Shell's own installer does. It pinned version_tag=65140, one build for
  # one range of shells (issue 0014).
  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    local shell_version
    shell_version="$(gnome-shell --version 2>/dev/null | awk '{print $3}')" || shell_version=""
    molt_error "Tactile extension not found. Install it first:"
    molt_error "  curl -sL 'https://extensions.gnome.org/download-extension/${TACTILE_UUID}.shell-extension.zip?shell_version=${shell_version:-<GNOME Shell version>}' -o /tmp/tactile.zip"
    molt_error "  gnome-extensions install /tmp/tactile.zip --force"
    molt_error "  # Then log out and back in to activate"
    return 1
  fi

  # The system copy of the schema is the one gsettings reads, so it must be the
  # installed extension's: refreshed whenever the two differ, not only when it
  # is missing (issue 0014).
  local fault
  if ! fault="$(_tiling_schema_fault)"; then
    molt_error "tiling: Tactile's gsettings schema $fault"
    return 1
  fi
  if [[ -n "$fault" ]]; then
    molt_info "tiling: Tactile's gsettings schema $fault, so installing the extension's..."
    _tiling_install_schema || return 1
  fi

  # Enable the extension (may fail before shell restart — that's OK)
  gnome-extensions enable "$TACTILE_UUID" 2>/dev/null || \
    molt_warn "Could not enable Tactile (shell restart may be needed)"

  # A 7x3 grid of equal-weight columns and rows, the activation binding (see
  # MOLT_TACTILE_ACTIVATE above), the window gap and maximize. Every write is
  # checked: resleeve runs install inside an `if`, where set -e does not apply.
  local activate setting
  if ! activate="$(_tiling_activate)"; then
    molt_error "tiling: the activation binding could not be read: $activate"
    return 1
  fi
  molt_info "Configuring Tactile: 7x3 grid (QWERTYU/ASDFGHJ/ZXCVBNM)..."
  for setting in col-0=1 col-1=1 col-2=1 col-3=1 col-4=1 col-5=1 col-6=1 \
      grid-cols=7 grid-rows=3 row-0=1 row-1=1 row-2=1 row-3=0 row-4=0 \
      "show-tiles=['$activate']" gap-size=4 maximize=true; do
    if ! gsettings set "$TACTILE_SCHEMA" "${setting%%=*}" "${setting#*=}"; then
      molt_error "tiling: could not set Tactile's ${setting%%=*}"
      return 1
    fi
  done

  molt_info "Liberator complete: tiling"
  molt_info "  Activate: $activate → type two keys to tile (eg Q,M = full screen)"
  molt_info "  Grid: Q W E R T Y U / A S D F G H J / Z X C V B N M"
}

tiling_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: tiling liberator not applicable on $platform"
    return 0
  fi

  if [[ ! -d "$TACTILE_EXT_DIR" ]]; then
    molt_error "VERIFY FAIL: Tactile extension not installed"
    errors=1
  else
    _tiling_report_schema_fault molt_error "VERIFY FAIL: " || errors=1
  fi

  if command -v gsettings &>/dev/null; then
    local col6
    col6="$(gsettings get "$TACTILE_SCHEMA" col-6 2>/dev/null || echo "0")"
    if [[ "$col6" != "1" ]]; then
      molt_error "VERIFY FAIL: Tactile grid not configured"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: tiling liberator is fully operational"
  fi
  return $errors
}
