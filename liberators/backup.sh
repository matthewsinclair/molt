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

# --- What "working" actually means -------------------------------------------
# SuperDuper aborts an image attach after this long. Hardcoded in sdcopyserver;
# there is no preference key for it.
BACKUP_ATTACH_BUDGET_S=120
# Measured cost of enumerating one band over SMB3 to the Synology: 21m28s for
# 108,413 bands, idle machine, nothing competing. 12ms each.
BACKUP_MS_PER_BAND=12
# Warn once a full image would need this share of the budget.
BACKUP_ATTACH_WARN_PCT=50
# A successful backup older than this is stale.
BACKUP_MAX_AGE_DAYS=3

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

# The destination is not a stored path. SuperDuper re-derives it on every run,
# and deriving an image destination means attaching it, which means hdiutil
# imageinfo -- an operation whose cost grows with the band count, against a
# hardcoded 120s budget. When that budget blows, SuperDuper does not stop: it
# falls back to the nearest matching volume, which is the SHARE the image lives
# on, rewrites the tile and drops the diskImage binding entirely. The next Smart
# Update then runs --delete against the share root and deletes the sparsebundle,
# because the sparsebundle is not part of the source.
#
# That is not a hypothetical. It destroyed the gyges backup on 7 Sep 2026.
# A job that names our share but carries no image binding is armed, not broken.
_backup_sd_share_bound() {
  local tiles="/Library/Application Support/SuperDuper4/tiles.json"
  [[ -r "$tiles" ]] || return 1
  # A correctly bound image destination carries a diskImage object and no
  # networkUrl whatsoever. One that has fallen back to the share carries a
  # networkUrl naming that share. Match on the destination field rather than
  # the file: tiles.json embeds whole run logs, whose prose says "backup"
  # constantly, and a Mac can hold several jobs of which only one is armed.
  /usr/bin/grep -o 'networkUrl[^,}]*' "$tiles" 2>/dev/null \
    | /usr/bin/grep -q "$MOLT_BACKUP_SHARE"
}

# Everything above asserts an *input*: share mounted, script installed, agent
# loaded. None of them imply a backup exists. On 7 Sep 2026 both sleeves printed
# "backup: ok" for days while pointing at a share that had never held one, and
# the image that did hold one was deleted without a single check going red. A
# check that cannot fail is decoration.
#
# So ask SuperDuper directly. tiles.json nests a JSON document inside a JSON
# string; plutil reads both and ships with macOS, so this needs no jq or python.

# Write our tile's proto to $1. Ours is the one whose image lives on our share.
_backup_sd_tile() {
  local out="$1" tiles="/Library/Application Support/SuperDuper4/tiles.json"
  local n i url
  [[ -r "$tiles" ]] || return 1
  n="$(/usr/bin/plutil -extract tiles raw -o - "$tiles" 2>/dev/null)" || return 1
  [[ "$n" =~ ^[0-9]+$ ]] || return 1
  for (( i = 0; i < n; i++ )); do
    /usr/bin/plutil -extract "tiles.$i.proto" raw -o - "$tiles" >"$out" 2>/dev/null || continue
    url="$(/usr/bin/plutil -extract destination.diskImage.hostShareUrl raw -o - "$out" 2>/dev/null)"
    [[ "$url" == */"$MOLT_BACKUP_SHARE" ]] && return 0
  done
  return 1
}

# Most recent run: _SD_OUTCOME, _SD_AGE_DAYS, _SD_BYTES. Absent history is not
# an error -- a freshly created job has none until its first copy finishes.
_backup_last_run() {
  local proto="$1" n last ended
  _SD_OUTCOME="" _SD_AGE_DAYS="" _SD_BYTES=""
  n="$(/usr/bin/plutil -extract recentRuns raw -o - "$proto" 2>/dev/null)" || return 1
  [[ "$n" =~ ^[0-9]+$ ]] && [[ "$n" -gt 0 ]] || return 1
  last=$((n - 1))
  _SD_OUTCOME="$(/usr/bin/plutil -extract "recentRuns.$last.outcome" raw -o - "$proto" 2>/dev/null)"
  _SD_BYTES="$(/usr/bin/plutil -extract "recentRuns.$last.bytesCopied" raw -o - "$proto" 2>/dev/null)"
  ended="$(/usr/bin/plutil -extract "recentRuns.$last.endedAtUnixNanos" raw -o - "$proto" 2>/dev/null)"
  [[ "$ended" =~ ^[0-9]+$ ]] && _SD_AGE_DAYS=$(( ( $(date +%s) - ended / 1000000000 ) / 86400 ))
  return 0
}

# How long a *full* image would take to attach. Deliberately does NOT count the
# bands directory: enumerating it is the very operation that takes 21 minutes on
# a sick image, so the check would be slowest exactly when things are worst.
# band-size and size are two small reads from Info.plist, and the ceiling is
# what matters anyway -- this warns while the image is still growing, not after.
_backup_attach_projection() {
  local info="$MOLT_BACKUP_IMAGE/Info.plist" bs sz
  _BACKUP_WORST_BANDS="" _BACKUP_WORST_S=""
  [[ -r "$info" ]] || return 1
  bs="$(/usr/bin/plutil -extract band-size raw -o - "$info" 2>/dev/null)"
  sz="$(/usr/bin/plutil -extract size raw -o - "$info" 2>/dev/null)"
  [[ "$bs" =~ ^[0-9]+$ ]] && [[ "$sz" =~ ^[0-9]+$ ]] && [[ "$bs" -gt 0 ]] || return 1
  _BACKUP_WORST_BANDS=$(( sz / bs ))
  _BACKUP_WORST_S=$(( _BACKUP_WORST_BANDS * BACKUP_MS_PER_BAND / 1000 ))
  return 0
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

  # A change to the template OR to instance vars does not trigger a re-render on
  # its own (molt only installs when a check fails), so ask for one explicitly
  # rather than run a stale script.
  if molt_config_stale "config/backup/backup-mount.sh" "$MOLT_BACKUP_SCRIPT" \
     || molt_config_stale "config/backup/com.${MOLT_USER}.backup-mount.plist" "$_BACKUP_AGENT"; then
    molt_info "backup: rendered config differs from its template or instance vars — re-rendering"
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
    molt_warn "backup: no image at ${MOLT_BACKUP_IMAGE} — point the job at the ${MOLT_BACKUP_SHARE} share in SuperDuper and use 'Use an Image...'"
    ok=1
  elif _backup_attached; then
    molt_debug "backup: ${MOLT_BACKUP_IMAGE} is attached (SuperDuper is probably copying)"
  fi

  # The question the old checks never asked: did a backup actually happen?
  local proto; proto="$(mktemp -t molt-sdtile)"
  if _backup_sd_tile "$proto"; then
    if _backup_last_run "$proto"; then
      case "$_SD_OUTCOME" in
        OUTCOME_SUCCEEDED)
          if [[ "$_SD_AGE_DAYS" -gt "$BACKUP_MAX_AGE_DAYS" ]]; then
            molt_warn "backup: last successful copy was ${_SD_AGE_DAYS} days ago (want <= ${BACKUP_MAX_AGE_DAYS})"
            ok=1
          else
            molt_info "backup: last copy succeeded ${_SD_AGE_DAYS} day(s) ago$( [[ -n "$_SD_BYTES" ]] && printf ', %s bytes' "$_SD_BYTES" )"
          fi ;;
        OUTCOME_CANCELLED)
          molt_warn "backup: last copy was cancelled ${_SD_AGE_DAYS} day(s) ago — no complete backup from it"
          ok=1 ;;
        *)
          molt_error "backup: last copy did NOT succeed (${_SD_OUTCOME:-unknown}), ${_SD_AGE_DAYS} day(s) ago"
          ok=1 ;;
      esac
    else
      # Correctly configured but never run is still "you have no backup".
      molt_warn "backup: SuperDuper job is bound correctly but has never completed a copy — no backup exists yet"
      ok=1
    fi
  else
    molt_warn "backup: no SuperDuper job has an image on the ${MOLT_BACKUP_SHARE} share"
    ok=1
  fi
  rm -f "$proto"

  # Predictive: warn while the image is still growing, not once it is fatal.
  if _backup_attach_projection; then
    local pct=$(( _BACKUP_WORST_S * 100 / BACKUP_ATTACH_BUDGET_S ))
    if [[ "$pct" -ge 100 ]]; then
      molt_error "backup: a full image needs ~${_BACKUP_WORST_S}s to attach (${_BACKUP_WORST_BANDS} bands)"
      molt_error "        SuperDuper gives up at ${BACKUP_ATTACH_BUDGET_S}s, then rebinds to the share and deletes the image."
      molt_error "        Rebuild it with a larger sparse-band-size. See instances/yggdrasil/NOTES.md."
      ok=1
    elif [[ "$pct" -ge "$BACKUP_ATTACH_WARN_PCT" ]]; then
      molt_warn "backup: a full image would need ~${_BACKUP_WORST_S}s of SuperDuper's ${BACKUP_ATTACH_BUDGET_S}s attach budget (${pct}%)"
      ok=1
    else
      molt_debug "backup: worst-case attach ~${_BACKUP_WORST_S}s of ${BACKUP_ATTACH_BUDGET_S}s (${_BACKUP_WORST_BANDS} bands)"
    fi
  fi

  if _backup_sd_share_bound; then
    molt_error "backup: SuperDuper's job names ${MOLT_BACKUP_SHARE} but has NO disk-image binding."
    molt_error "        Running it would Smart Update into the share root and DELETE the sparsebundle."
    molt_error "        Fix: re-point the job at the ${MOLT_BACKUP_SHARE} share, then take its 'Use an Image...' button."
    ok=1
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
