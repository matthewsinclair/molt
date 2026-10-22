#!/usr/bin/env bash
# desktop.sh — Liberator: desktop environment settings
# Frees you from GNOME defaults that steal your keys: applies the GNOME keys the
# user stack declares for this sleeve, links the GTK stylesheet and sets the dock
# favourites. The keys, values included, are the user's, read from
# instances/<host>/desktop/gsettings; none is written into the liberator, and
# each set is read back, so a key that did not take is an error, not silence
# (issue 0035).

# GTK3 and GTK4 read different paths and do not share a stylesheet. Linking
# gtk-3.0 only left GTK4 apps -- now the common case -- unstyled, and molt could
# not repair a gtk-4.0 link because it never created one.
# Dock favourites, read from instances/<host>/desktop/favorite-apps.
#
# Instance-scoped like keys.sh (keyd/default.conf) and ssh.sh (ssh/config.d),
# because which apps a machine pins is per-machine and Linux-only. One .desktop
# id per line; line order is dock order. Blank lines and # comments ignored.
#
# Worth managing because the dock silently outranks every "default terminal"
# setting there is: kovacs had alacritty set as default by gsettings AND by
# /etc/alternatives, and still launched gnome-terminal, because both were
# pinned and the user clicked the icon. A fresh sleeve gets whatever GNOME
# ships, which is how that happened.
_desktop_favorites_file() {
  _desktop_instance_file favorite-apps
}

# GNOME keys, read from instances/<host>/desktop/gsettings, instance-scoped for
# the favourites' reason. One "<schema> <key> <value>" per line, the value
# running to the end of the line and written as `gsettings get` prints it, so
# what install sets is what check compares. Blank lines and lines starting
# with # are ignored; a # later in a line is part of the value.
_desktop_gsettings_file() {
  _desktop_instance_file gsettings
}

# The path of instances/<host>/desktop/$1 in the user repo, failing when it has
# none.
_desktop_instance_file() {
  local user_repo hostname
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")" || return 1
  [[ -n "$user_repo" ]] || return 1
  # molt_hostname, as every reader of instances/ asks. This copy fell back to
  # "unknown" where the others fall back to the long hostname, so a host whose
  # hostname -s failed looked in instances/unknown/ (issue 0020).
  hostname="$(molt_hostname)" || return 1
  local f="$user_repo/instances/$hostname/desktop/$1"
  [[ -f "$f" ]] || return 1
  echo "$f"
}

# The pairs gsettings file $1 declares, one "<schema>\t<key>\t<value>" per
# line. A line with fewer than three fields is a fault naming the file and the
# line, and nothing is printed.
_desktop_gsettings_pairs() {
  local f="$1" line n=0 schema key value out=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    read -r schema key value <<<"$line"
    if [[ -z "$value" ]]; then
      molt_error "desktop: $f line $n: expected <schema> <key> <value>, got: $line"
      return 1
    fi
    out+="${schema}"$'\t'"${key}"$'\t'"${value}"$'\n'
  done <"$f"
  printf '%s' "$out"
}

# What gsettings holds for schema $1, key $2: what `gsettings get` prints on
# stdout, so that a warning GLib prints beside a value does not read as drift.
# A key gsettings cannot read answers with gsettings' words, and fails.
_desktop_gsettings_get() {
  local got
  if got="$(gsettings get "$1" "$2" 2>/dev/null)"; then
    printf '%s\n' "$got"
    return 0
  fi
  # Asked again for its reason; a get changes nothing.
  { gsettings get "$1" "$2" >/dev/null; } 2>&1
  return 1
}

# gsettings' words $1, indented on stderr under the molt_error they explain.
_desktop_gsettings_words() {
  [[ -z "$1" ]] || printf '%s\n' "$1" | sed 's/^/    /' >&2
}

# Each declared pair gsettings does not hold, one "<schema> <key> is <got>,
# wanted <value>" per line, for check and verify to report as each reports. A
# key gsettings cannot read is reported with gsettings' words as what it got.
_desktop_gsettings_drift() {
  local pairs schema key value got
  pairs="$(_desktop_gsettings_pairs "$1")" || return 1
  [[ -n "$pairs" ]] || return 0
  while IFS=$'\t' read -r schema key value; do
    # A key that cannot be read is drift too, its reason standing as what it got.
    got="$(_desktop_gsettings_get "$schema" "$key")" || true
    [[ "$got" == "$value" ]] || echo "$schema $key is $got, wanted $value"
  done <<<"$pairs"
}

# Sets each pair gsettings file $1 declares and reads it back. A set gsettings
# refuses, or a key that reads back other than declared, is an error naming the
# key; every pair is tried, and any such error fails the whole with 1. A
# malformed file sets nothing and fails with 2.
_desktop_gsettings_apply() {
  local f="$1" pairs schema key value out got failed=0
  pairs="$(_desktop_gsettings_pairs "$f")" || return 2
  if [[ -z "$pairs" ]]; then
    molt_debug "desktop: ${f#"$HOME/"} declares no keys"
    return 0
  fi
  molt_info "Setting GNOME keys from ${f#"$HOME/"}..."
  while IFS=$'\t' read -r schema key value; do
    if ! out="$(gsettings set "$schema" "$key" "$value" 2>&1)"; then
      molt_error "desktop: gsettings refused $schema $key:"
      _desktop_gsettings_words "$out"
      failed=1
      continue
    fi
    # A set that exits 0 can still have warned, eg dconf failing to commit,
    # and the read-back below is then explained by what it said.
    [[ -z "$out" ]] || printf '%s\n' "$out" >&2
    if ! got="$(_desktop_gsettings_get "$schema" "$key")"; then
      molt_error "desktop: $schema $key could not be read back:"
      _desktop_gsettings_words "$got"
      failed=1
    elif [[ "$got" != "$value" ]]; then
      molt_error "desktop: $schema $key did not take: wanted $value, got $got"
      failed=1
    fi
  done <<<"$pairs"
  return $failed
}

# True when the favourites file yields no entries.
#
# "Present but empty" is almost always a malformed file or a glob that matched
# nothing, not a deliberate request for a bare dock -- and applying it wipes
# every pinned app, which the user sees immediately. kovacs demonstrated this
# for real while testing the empty case: one gsettings set with an empty list
# emptied the live dock. Recoverable only because the favourites file existed
# to restore from. Refuse it rather than apply it.
_desktop_favorites_empty() {
  [[ "$(_desktop_favorites_wanted "$1")" == "@as []" ]]
}

# The value gsettings would need, as a GVariant string array literal.
_desktop_favorites_wanted() {
  local f="$1" line first=1 out="["
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]')"
    [[ -n "$line" ]] || continue
    [[ $first -eq 1 ]] || out+=", "
    out+="'${line}'"
    first=0
  done < "$f"
  out+="]"
  # gsettings prints an empty string array as "@as []", not "[]", so an empty
  # favourites list would otherwise read as permanent drift.
  [[ $first -eq 1 ]] && out="@as []"
  echo "$out"
}

_desktop_gtk_versions() {
  echo "gtk-3.0 gtk-4.0"
}

desktop_check() {
  local ok=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_debug "desktop: only applicable on Linux"
    return 0
  fi

  if ! command -v gsettings &>/dev/null; then
    molt_debug "desktop: gsettings not available (no GNOME?)"
    return 0
  fi

  # Declared GNOME keys drift
  local gs_file drift line
  if gs_file="$(_desktop_gsettings_file)"; then
    if drift="$(_desktop_gsettings_drift "$gs_file")"; then
      if [[ -n "$drift" ]]; then
        while IFS= read -r line; do
          molt_info "desktop: $line"
        done <<<"$drift"
        ok=1
      fi
    else
      ok=1
    fi
  fi

  # Check GTK config
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gv
    for gv in $(_desktop_gtk_versions); do
      if ! molt_link_healthy "$HOME/.config/$gv/gtk.css"; then
        molt_info "desktop: ~/.config/${gv}/gtk.css $(molt_link_fault "$HOME/.config/$gv/gtk.css")"
        ok=1
      fi
    done
  fi

  # Dock favourites drift
  local fav_file
  if fav_file="$(_desktop_favorites_file)" && command -v gsettings &>/dev/null; then
    if _desktop_favorites_empty "$fav_file"; then
      molt_warn "desktop: ${fav_file#"$HOME/"} has no entries -- ignoring it."
      molt_warn "        Applying it would empty the dock, which is far more likely"
      molt_warn "        to be a malformed file than a deliberate choice."
    else
      local want have
      want="$(_desktop_favorites_wanted "$fav_file")"
      have="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
      if [[ "$want" != "$have" ]]; then
        molt_info "desktop: dock favourites differ from ${fav_file#"$HOME/"}"
        ok=1
      fi
    fi
  fi

  return $ok
}

desktop_install() {
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "desktop: skipping on $platform (Linux only)"
    return 0
  fi

  if ! command -v gsettings &>/dev/null; then
    molt_info "desktop: no GNOME desktop detected, skipping"
    return 0
  fi

  # GNOME keys the user stack declares. A malformed file stops install here; a
  # key that did not take fails it once the rest is done.
  local gs_file failed=0
  if gs_file="$(_desktop_gsettings_file)"; then
    local gs_status=0
    _desktop_gsettings_apply "$gs_file" || gs_status=$?
    case $gs_status in
      0) ;;
      1) failed=1 ;;
      *) return 1 ;;
    esac
  else
    molt_debug "desktop: no instances/<host>/desktop/gsettings, so no GNOME keys to set"
  fi

  # Install GTK config
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  if [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gv
    for gv in $(_desktop_gtk_versions); do
      mkdir -p "$HOME/.config/$gv"
      molt_link "$user_repo/config/gtk/gtk.css" "$HOME/.config/$gv/gtk.css" || return 1
    done
  fi

  # Dock favourites
  local fav_file
  if fav_file="$(_desktop_favorites_file)"; then
    if _desktop_favorites_empty "$fav_file"; then
      molt_warn "desktop: refusing to apply ${fav_file#"$HOME/"} -- it has no entries."
      molt_warn "        That would empty the dock. Fix the file, or delete it if you"
      molt_warn "        want molt to leave dock favourites alone entirely."
    elif command -v gsettings &>/dev/null; then
      local want
      want="$(_desktop_favorites_wanted "$fav_file")"
      if gsettings set org.gnome.shell favorite-apps "$want" 2>/dev/null; then
        molt_info "Dock favourites set from ${fav_file#"$HOME/"}"
      else
        molt_warn "desktop: could not set dock favourites (gsettings refused '${want}')"
      fi
    else
      molt_warn "desktop: ${fav_file#"$HOME/"} present but gsettings is not available"
    fi
  fi

  [[ $failed -eq 0 ]] || return 1
  molt_info "Liberator complete: desktop"
}

desktop_verify() {
  local errors=0
  local platform
  platform="$(molt_platform)"

  if [[ "$platform" != "linux" ]]; then
    molt_info "Verified: desktop liberator not applicable on $platform"
    return 0
  fi

  local gs_file drift line
  if command -v gsettings &>/dev/null && gs_file="$(_desktop_gsettings_file)"; then
    if drift="$(_desktop_gsettings_drift "$gs_file")"; then
      if [[ -n "$drift" ]]; then
        while IFS= read -r line; do
          molt_error "VERIFY FAIL: desktop: $line"
        done <<<"$drift"
        errors=1
      fi
    else
      errors=1
    fi
  fi

  # _install links the GTK stylesheet; verify never checked it.
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/gtk/gtk.css" ]]; then
    local gv
    for gv in $(_desktop_gtk_versions); do
      if ! molt_link_healthy "$HOME/.config/$gv/gtk.css"; then
        molt_error "VERIFY FAIL: ~/.config/${gv}/gtk.css $(molt_link_fault "$HOME/.config/$gv/gtk.css")"
        errors=1
      fi
    done
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: desktop liberator is fully operational"
  fi
  return $errors
}
