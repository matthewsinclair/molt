#!/usr/bin/env bash
# backup.sh — Liberator: NAS backup share and disk image
# Frees you from hand-mounting a share before a backup can run.
#
# This liberator does not perform backups. SuperDuper does that. What it owns is
# making the destination *reachable*: the SMB share mounted, healthy, speaking a
# sane dialect, with the .asif visible on it — and reporting honestly when it is not.
#
# It deliberately does NOT create, attach or touch the image, and treats an absent
# or unattached image as normal. SuperDuper creates <hostname>.sparsebundle itself
# when you point a job at the SMB share and take its "Use an Image..." button, then
# attaches and detaches it around every copy. Anything we attach ourselves is at
# best useless and at worst poisons the job's destination binding permanently.
#
# Requires these in the instance's vars.sh:
#   MOLT_BACKUP_HOST MOLT_BACKUP_SHARE MOLT_BACKUP_MOUNT
#   MOLT_BACKUP_IMAGE MOLT_BACKUP_SCRIPT MOLT_BACKUP_LOG

_backup_vars() {
  local repo hostname vars
  repo="$(molt_find_user_repo)" || return 1
  hostname="$(hostname -s 2>/dev/null || hostname)"
  vars="$repo/instances/$hostname/vars.sh"
  [[ -f "$vars" ]] || { molt_error "backup: no vars.sh for instance $hostname"; return 1; }
  # shellcheck disable=SC1090
  source "$vars"
  local missing=()
  local v
  for v in MOLT_BACKUP_HOST MOLT_BACKUP_SHARE MOLT_BACKUP_MOUNT \
           MOLT_BACKUP_IMAGE MOLT_BACKUP_SCRIPT MOLT_BACKUP_LOG; do
    [[ -n "${!v:-}" ]] || missing+=("$v")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    molt_error "backup: vars.sh for $hostname is missing: ${missing[*]}"
    return 1
  fi
  _BACKUP_AGENT="$HOME/Library/LaunchAgents/com.${MOLT_USER}.backup-mount.plist"
  _BACKUP_LABEL="com.${MOLT_USER}.backup-mount"
}

# Is the NAS reachable on the SMB port? A laptop away from home is a normal
# state, not a fault, and everything downstream keys off this answer.
_backup_home() {
  /usr/bin/nc -z -G 3 "$MOLT_BACKUP_HOST" 445 >/dev/null 2>&1
}

_backup_mounted()  { /sbin/mount | /usr/bin/grep -q " on ${MOLT_BACKUP_MOUNT} (" ; }
_backup_attached() {
  # Exact match on the resolved path. hdiutil pads image-path with spaces, so a
  # literal grep is brittle; compare the field instead.
  /usr/bin/hdiutil info 2>/dev/null | /usr/bin/awk -v p="$MOLT_BACKUP_IMAGE" '
    /^image-path/ { sub(/^image-path[ \t]*:[ \t]*/, ""); if ($0 == p) { f=1; exit } }
    END { exit !f }'
}

# stat with a watchdog. A wedged smbfs mount blocks forever; a plain stat here
# would hang molt itself. 0 = readable, 1 = failed, 2 = timed out.
_backup_probe() {
  local path="$1" limit="${2:-10}" pid n=0
  ( /usr/bin/stat -f '%z' "$path" >/dev/null 2>&1 ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$n" -ge "$limit" ]]; then
      kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; return 2
    fi
    sleep 1; n=$((n + 1))
  done
  wait "$pid"
}

_backup_dialect() {
  /usr/bin/smbutil statshares -a 2>/dev/null | /usr/bin/awk '/SMB_VERSION/{print $2; exit}'
}

# SuperDuper 4 will happily show "NEXT TOMORROW AT 03:00" while its daemon is
# locked and skipping every single fire. The only honest source is the log.
_backup_sd_locked() {
  local log="/Library/Logs/SuperDuper 4/scheduler.log"
  [[ -r "$log" ]] || return 1
  tail -50 "$log" 2>/dev/null | grep -q "daemon is LOCKED"
}

backup_check() {
  _backup_vars || return 1
  local ok=0

  # A template change alone does not trigger a re-render (molt only installs when
  # a check fails), so ask for one explicitly rather than run a stale script.
  if molt_config_stale "config/backup/backup-mount.sh" "$MOLT_BACKUP_SCRIPT" \
     || molt_config_stale "config/backup/com.${MOLT_USER}.backup-mount.plist" "$_BACKUP_AGENT"; then
    molt_info "backup: rendered config is older than its template — re-rendering"
    ok=1
  fi

  if [[ ! -x "$MOLT_BACKUP_SCRIPT" ]]; then
    molt_info "backup: mount script not installed at $MOLT_BACKUP_SCRIPT"
    ok=1
  fi
  if [[ ! -f "$_BACKUP_AGENT" ]]; then
    molt_info "backup: launch agent not installed at $_BACKUP_AGENT"
    ok=1
  fi

  if ! _backup_home; then
    molt_info "backup: ${MOLT_BACKUP_HOST} not reachable — away from home, nothing to check"
    return $ok
  fi

  if _backup_mounted; then
    if ! _backup_probe "$MOLT_BACKUP_MOUNT"; then
      molt_info "backup: ${MOLT_BACKUP_MOUNT} is mounted but not answering (run: molt maintain backup)"
      ok=1
    fi
  else
    molt_info "backup: ${MOLT_BACKUP_MOUNT} not mounted"
    ok=1
  fi

  local dialect
  dialect="$(_backup_dialect)"
  case "${dialect:-}" in
    SMB_3*) molt_debug "backup: dialect $dialect" ;;
    "")     : ;;
    *)      molt_warn "backup: ${MOLT_BACKUP_HOST} negotiated $dialect, expected SMB_3.x — check DSM SMB settings"
            ok=1 ;;
  esac

  # The image is SuperDuper's to create and mount. Absent means "not set up yet",
  # attached means "a copy is probably running" -- neither is a fault of ours.
  if ! _backup_probe "$MOLT_BACKUP_IMAGE"; then
    molt_info "backup: no image at ${MOLT_BACKUP_IMAGE} — point the job at the ${MOLT_BACKUP_SHARE} share in SuperDuper and use 'Use an Image...'"
  elif _backup_attached; then
    molt_debug "backup: ${MOLT_BACKUP_IMAGE} is attached (SuperDuper is probably copying)"
  fi

  if _backup_sd_locked; then
    molt_warn "backup: SuperDuper is skipping scheduled copies (daemon is LOCKED) — unlock the padlock in its sidebar"
    ok=1
  fi

  return $ok
}

backup_install() {
  _backup_vars || return 1

  molt_install_config "config/backup/backup-mount.sh" "$MOLT_BACKUP_SCRIPT" || return 1
  chmod 755 "$MOLT_BACKUP_SCRIPT"

  mkdir -p "$(dirname "$MOLT_BACKUP_LOG")"
  mkdir -p "$HOME/Library/LaunchAgents"
  molt_install_config "config/backup/com.${MOLT_USER}.backup-mount.plist" "$_BACKUP_AGENT" || return 1

  # Reload so an edited plist actually takes effect.
  launchctl bootout "gui/$(id -u)/${_BACKUP_LABEL}" 2>/dev/null
  if launchctl bootstrap "gui/$(id -u)" "$_BACKUP_AGENT" 2>/dev/null; then
    molt_info "Loaded launch agent: ${_BACKUP_LABEL}"
  else
    molt_warn "backup: could not bootstrap ${_BACKUP_LABEL} (already loaded?)"
  fi

  molt_info "Liberator complete: backup"
}

backup_verify() {
  _backup_vars || return 1
  local errors=0

  [[ -x "$MOLT_BACKUP_SCRIPT" ]] || { molt_error "VERIFY FAIL: $MOLT_BACKUP_SCRIPT missing or not executable"; errors=1; }
  [[ -f "$_BACKUP_AGENT" ]]      || { molt_error "VERIFY FAIL: $_BACKUP_AGENT missing"; errors=1; }

  launchctl print "gui/$(id -u)/${_BACKUP_LABEL}" >/dev/null 2>&1 \
    || { molt_error "VERIFY FAIL: launch agent ${_BACKUP_LABEL} not loaded"; errors=1; }

  if ! _backup_home; then
    # Being away is not a verification failure. The installed pieces are what
    # this hook is entitled to assert on.
    molt_info "backup: away from ${MOLT_BACKUP_HOST}; skipped share and image checks"
    [[ $errors -eq 0 ]] && molt_info "Verified: backup liberator installed (share checks deferred)"
    return $errors
  fi

  _backup_mounted || { molt_error "VERIFY FAIL: ${MOLT_BACKUP_MOUNT} not mounted"; errors=1; }
  _backup_probe "$MOLT_BACKUP_MOUNT" || { molt_error "VERIFY FAIL: ${MOLT_BACKUP_MOUNT} not readable"; errors=1; }
  # Not a verification failure: the image belongs to SuperDuper and legitimately
  # does not exist until a job has been pointed at the share.
  _backup_probe "$MOLT_BACKUP_IMAGE" || molt_info "backup: no image at ${MOLT_BACKUP_IMAGE} yet (SuperDuper creates it)"

  local dialect
  dialect="$(_backup_dialect)"
  case "${dialect:-}" in
    SMB_3*) ;;
    *) molt_error "VERIFY FAIL: expected SMB_3.x, got ${dialect:-unknown}"; errors=1 ;;
  esac

  [[ $errors -eq 0 ]] && molt_info "Verified: backup liberator is fully operational"
  return $errors
}

# Force a clean session. Use when the share has wedged.
# We never detach the image: if it is open, SuperDuper is very likely copying
# into it, and pulling it out from under a running copy is how you corrupt a
# backup. An open image also pins the mount, so there is nothing safe to do.
backup_maintain() {
  _backup_vars || return 1

  if ! _backup_home; then
    molt_info "backup: ${MOLT_BACKUP_HOST} not reachable — nothing to repair"
    return 0
  fi

  if pgrep -f 'sdcopy --progress-fd' >/dev/null 2>&1; then
    molt_error "backup: a SuperDuper copy is running — refusing to tear down the share"
    return 1
  fi

  if _backup_attached; then
    molt_error "backup: ${MOLT_BACKUP_IMAGE} is open — refusing to tear down the share under it"
    return 1
  fi

  molt_info "Rebuilding the ${MOLT_BACKUP_HOST} session..."
  if _backup_mounted; then
    /sbin/umount -f "$MOLT_BACKUP_MOUNT" >/dev/null 2>&1 \
      && molt_info "  unmounted ${MOLT_BACKUP_MOUNT}"
  fi

  "$MOLT_BACKUP_SCRIPT" || { molt_error "backup: remount failed — see $MOLT_BACKUP_LOG"; return 1; }
  molt_info "Session rebuilt. $(_backup_dialect)"
  backup_check
}
