#!/usr/bin/env bash
# backup.sh — Liberator: verify the NAS backup is real
#
# This liberator OBSERVES. It configures nothing, mounts nothing, and installs
# nothing, because there is nothing here it can usefully own.
#
# It used to render a mount script and a LaunchAgent that mounted the SMB share
# on every network change. All three were deleted on 7 Sep 2026. SuperDuper
# mounts the share itself from the hostShareUrl in its own job definition, so
# that machinery duplicated work already being done — and it was worse than
# redundant. A share mounted for no reason is another volume for SuperDuper's
# destination resolver to fall back onto when it cannot open the image, and on
# 7 Sep it did exactly that: fell back onto an unrelated share and began a
# Smart Update into its root.
#
# What is left is the only thing molt can honestly assert about a backup that
# lives inside a GUI app's private state: whether one actually happened, whether
# the job is still bound to the image rather than the share, and whether the
# next attach will fit inside SuperDuper's budget. See instances/yggdrasil/NOTES.md.
#
# Requires these in the instance's vars.sh:
#   MOLT_BACKUP_HOST MOLT_BACKUP_SHARE MOLT_BACKUP_MOUNT MOLT_BACKUP_IMAGE

# --- What "working" actually means -------------------------------------------
# SuperDuper aborts an image attach after this long. Hardcoded in sdcopyserver;
# there is no preference key for it.
BACKUP_ATTACH_BUDGET_S=120
# Cost of one band during an attach, over SMB3 to the Synology. This is NOT a
# constant: it rises with band size, so a single figure under-reports badly on
# large-band images. Two measurements, same NAS, same wire:
#
#     8 MB bands   108,413 bands   1288s   ->  11.9 ms/band
#     1 GiB bands      849 bands     70s   ->  78   ms/band
#
# 128x the band size costs 6.5x per band. Larger bands still win by a mile (66s
# against 1288s for the same 850 GB) but nowhere near the 128x that band count
# alone suggests, and assuming they do is how you conclude an image is at 10% of
# budget when it is at 59%. Bracketed rather than fitted: two points do not
# justify a curve, and the brackets round the wrong way on purpose.
# Re-derive with: time hdiutil imageinfo <image>, divided by its band count.
_backup_ms_per_band() {
  local bs="$1"
  if   [[ "$bs" -le 16777216   ]]; then echo 12    # <= 16 MB
  elif [[ "$bs" -le 268435456  ]]; then echo 40    # <= 256 MB
  elif [[ "$bs" -le 1073741824 ]]; then echo 80    # <= 1 GiB
  else                                  echo 105   # larger
  fi
}
# Fixed cost of the attach itself, measured on an empty image: ~4s.
BACKUP_ATTACH_FIXED_S=4
# Warn once a full image would need this share of the budget.
BACKUP_ATTACH_WARN_PCT=75
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
  for v in MOLT_BACKUP_HOST MOLT_BACKUP_SHARE MOLT_BACKUP_MOUNT MOLT_BACKUP_IMAGE; do
    [[ -n "${!v:-}" ]] || missing+=("$v")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    molt_error "backup: vars.sh for $hostname is missing: ${missing[*]}"
    return 1
  fi
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
  # Project from what the source actually holds, not from the image ceiling.
  # SuperDuper sizes the image to the whole source container, so on a machine
  # whose disk is largely empty the ceiling is wildly pessimistic -- rhadamanth's
  # image can hold 3,722 GiB but its source has 1.38 TB in it, and projecting the
  # ceiling would keep it permanently red over bands that will never exist.
  # Fall back to the ceiling when the source cannot be read.
  local used total free
  total="$(/usr/sbin/diskutil info / 2>/dev/null | /usr/bin/awk -F'[()]' '/Container Total Space/{print $2}' | /usr/bin/awk '{print $1}')"
  free="$(/usr/sbin/diskutil info / 2>/dev/null | /usr/bin/awk -F'[()]' '/Container Free Space/{print $2}' | /usr/bin/awk '{print $1}')"
  if [[ "$total" =~ ^[0-9]+$ ]] && [[ "$free" =~ ^[0-9]+$ ]] && [[ "$total" -gt "$free" ]]; then
    used=$(( total - free ))
    [[ "$used" -lt "$sz" ]] && sz="$used"
  fi

  _BACKUP_WORST_BANDS=$(( sz / bs ))
  local per; per="$(_backup_ms_per_band "$bs")"
  _BACKUP_WORST_S=$(( BACKUP_ATTACH_FIXED_S + _BACKUP_WORST_BANDS * per / 1000 ))
  return 0
}

# SuperDuper 4 will happily show "NEXT TOMORROW AT 03:00" while its daemon is
# locked and skipping every single fire. The only honest source is the log.
_backup_sd_locked() {
  local log="/Library/Logs/SuperDuper 4/scheduler.log"
  [[ -r "$log" ]] || return 1
  tail -50 "$log" 2>/dev/null | grep -q "daemon is LOCKED"
}

# Assert SuperDuper's schedule for this sleeve sits inside the window the
# instance claims. Two failures this catches, both seen on 7 Sep 2026:
#
#   - A schedule block that the scheduler ignores. Both NAS jobs carried
#     {"weeks":[1..5],"minuteOfDay":1380} while the scheduler logged
#     scheduled=0 and the panel read "not on a schedule". A real schedule also
#     carries scheduleOn and days, so every backup either machine had ever
#     completed was triggered by hand.
#   - A schedule edited months from now with no memory of the other machine.
#     Attaching an image costs ~260s while another copy is running against the
#     same NAS, against a 120s budget, so two jobs must not overlap. Windows are
#     assigned per sleeve and do not intersect; this asserts the local one.
#
# It cannot see the other machine, and does not pretend to. It only checks that
# this sleeve stayed inside the lane it was given.
_backup_window_check() {
  local proto="$1" win="${MOLT_BACKUP_WINDOW:-}"
  [[ -n "$win" ]] || return 0
  [[ "$win" =~ ^([0-9]{1,2}):([0-9]{2})-([0-9]{1,2}):([0-9]{2})$ ]] || {
    molt_warn "backup: MOLT_BACKUP_WINDOW is not HH:MM-HH:MM: $win"; return 1; }
  local lo=$(( 10#${BASH_REMATCH[1]} * 60 + 10#${BASH_REMATCH[2]} ))
  local hi=$(( 10#${BASH_REMATCH[3]} * 60 + 10#${BASH_REMATCH[4]} ))

  local on min
  on="$(/usr/bin/plutil -extract schedule.scheduleOn raw -o - "$proto" 2>/dev/null)"
  min="$(/usr/bin/plutil -extract schedule.minuteOfDay raw -o - "$proto" 2>/dev/null)"

  if [[ "$on" != "true" ]]; then
    molt_warn "backup: job is not actually scheduled — it only runs when you click Copy Now"
    molt_warn "        (a schedule block without scheduleOn is inert; the scheduler ignores it)"
    return 1
  fi
  if [[ ! "$min" =~ ^[0-9]+$ ]]; then
    molt_warn "backup: job is scheduled but carries no start time"; return 1
  fi
  if [[ "$min" -lt "$lo" ]] || [[ "$min" -gt "$hi" ]]; then
    molt_warn "backup: scheduled at $(printf '%02d:%02d' $((min/60)) $((min%60))) — outside this sleeve's window ${win}"
    molt_warn "        Windows are assigned so the machines never copy at once. See instances/yggdrasil/NOTES.md."
    return 1
  fi
  molt_debug "backup: scheduled $(printf '%02d:%02d' $((min/60)) $((min%60))), inside ${win}"
  return 0
}

backup_check() {
  _backup_vars || return 1
  local ok=0

  if ! _backup_home; then
    molt_info "backup: ${MOLT_BACKUP_HOST} not reachable — away from home, nothing to check"
    return $ok
  fi

  # An unmounted share is no longer a fault: nothing here mounts it any more,
  # and SuperDuper mounts it itself when a copy runs. It only costs us the two
  # checks that have to read the image, so say which were skipped and move on.
  # Everything derived from tiles.json is local and runs either way.
  local share_readable=0
  if _backup_mounted; then
    if _backup_probe "$MOLT_BACKUP_MOUNT"; then
      share_readable=1
    else
      molt_warn "backup: ${MOLT_BACKUP_MOUNT} is mounted but not answering (run: molt maintain backup)"
      ok=1
    fi
  else
    molt_debug "backup: ${MOLT_BACKUP_MOUNT} not mounted — image checks skipped (SuperDuper mounts it when it runs)"
  fi

  if [[ "$share_readable" -eq 1 ]]; then
    local dialect
    dialect="$(_backup_dialect)"
    case "${dialect:-}" in
      SMB_3*) molt_debug "backup: dialect $dialect" ;;
      "")     : ;;
      *)      molt_warn "backup: ${MOLT_BACKUP_HOST} negotiated $dialect, expected SMB_3.x — check DSM SMB settings"
              ok=1 ;;
    esac

    if ! _backup_probe "$MOLT_BACKUP_IMAGE"; then
      molt_warn "backup: no image at ${MOLT_BACKUP_IMAGE} — point the job at the ${MOLT_BACKUP_SHARE} share in SuperDuper and use 'Use an Image...'"
      ok=1
    elif _backup_attached; then
      molt_debug "backup: ${MOLT_BACKUP_IMAGE} is attached (SuperDuper is probably copying)"
    fi
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
  _backup_window_check "$proto" || ok=1
  rm -f "$proto"

  # Predictive: warn while the image is still growing, not once it is fatal.
  if [[ "$share_readable" -eq 1 ]] && _backup_attach_projection; then
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
      molt_debug "backup: worst-case attach ~${_BACKUP_WORST_S}s of ${BACKUP_ATTACH_BUDGET_S}s (${_BACKUP_WORST_BANDS} bands, NAS idle)"
    fi
    # The figure above is an idle floor, not a guarantee. Measured on the same
    # image minutes apart: 70s with the NAS quiet, 268s while the other Mac was
    # mid-copy -- 78ms against 316ms per band, roughly 4x, and 223% of the
    # budget. Nothing here can see the other machine, so this cannot be checked
    # from one sleeve; it is an operational rule (never let two copies overlap)
    # recorded in instances/yggdrasil/NOTES.md and in each share's README.
    if [[ $(( _BACKUP_WORST_S * 4 )) -ge "$BACKUP_ATTACH_BUDGET_S" ]]; then
      molt_debug "backup: would exceed the attach budget if another copy ran concurrently (~$(( _BACKUP_WORST_S * 4 ))s) — do not overlap the two machines"
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

# Nothing to install. Kept because resleeve calls _install whenever _check
# fails, and a red check here is a fact about the backup -- no recent copy, a
# job bound to the share, an image that can no longer be attached in time --
# not a missing file that molt can put back. SuperDuper's destination binding
# can only be set from its UI, via the "Use an Image..." button; anything
# written directly into tiles.json is silently discarded by the daemon.
backup_install() {
  _backup_vars || return 1
  molt_info "backup: nothing to install — this liberator verifies, it does not configure."
  molt_info "        A warning above is about the backup itself. See instances/yggdrasil/NOTES.md."
  return 0
}

backup_verify() {
  _backup_vars || return 1
  local errors=0

  if ! _backup_home; then
    molt_info "backup: away from ${MOLT_BACKUP_HOST}; share and image checks skipped"
    return 0
  fi

  # Bound to the image, not the share. This is the one that matters: a
  # share-bound job does not merely fail, it Smart Updates into the share root
  # and deletes the sparsebundle, because the sparsebundle is not on the source.
  if _backup_sd_share_bound; then
    molt_error "VERIFY FAIL: SuperDuper's job names ${MOLT_BACKUP_SHARE} with no disk-image binding"
    errors=1
  fi

  local proto; proto="$(mktemp -t molt-sdtile)"
  if _backup_sd_tile "$proto"; then
    if _backup_last_run "$proto"; then
      case "$_SD_OUTCOME" in
        OUTCOME_SUCCEEDED)
          if [[ "$_SD_AGE_DAYS" -gt "$BACKUP_MAX_AGE_DAYS" ]]; then
            molt_error "VERIFY FAIL: last successful copy was ${_SD_AGE_DAYS} days ago"
            errors=1
          fi ;;
        *) molt_error "VERIFY FAIL: last copy did not succeed (${_SD_OUTCOME:-unknown})"; errors=1 ;;
      esac
    else
      molt_error "VERIFY FAIL: SuperDuper job has never completed a copy — no backup exists"
      errors=1
    fi
  else
    molt_error "VERIFY FAIL: no SuperDuper job has an image on the ${MOLT_BACKUP_SHARE} share"
    errors=1
  fi
  rm -f "$proto"

  if _backup_mounted && _backup_probe "$MOLT_BACKUP_MOUNT"; then
    local dialect; dialect="$(_backup_dialect)"
    case "${dialect:-}" in
      SMB_3*) ;;
      *) molt_error "VERIFY FAIL: expected SMB_3.x, got ${dialect:-unknown}"; errors=1 ;;
    esac
    if _backup_attach_projection \
       && [[ $(( _BACKUP_WORST_S * 100 / BACKUP_ATTACH_BUDGET_S )) -ge 100 ]]; then
      molt_error "VERIFY FAIL: a full image needs ~${_BACKUP_WORST_S}s to attach, budget is ${BACKUP_ATTACH_BUDGET_S}s"
      errors=1
    fi
  else
    molt_info "backup: ${MOLT_BACKUP_MOUNT} not mounted; dialect and attach checks skipped"
  fi

  [[ $errors -eq 0 ]] && molt_info "Verified: a recent backup exists and the job is bound to its image"
  return $errors
}

# Force a clean session when the share has wedged. Unmount only -- we no longer
# remount, because SuperDuper does that itself from its own hostShareUrl, and
# leaving a share mounted for no reason is what gave its resolver somewhere
# wrong to fall back to.
#
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

  if _backup_mounted; then
    if /sbin/umount -f "$MOLT_BACKUP_MOUNT" >/dev/null 2>&1; then
      molt_info "backup: unmounted ${MOLT_BACKUP_MOUNT} — SuperDuper will remount it on its next copy"
    else
      molt_error "backup: could not unmount ${MOLT_BACKUP_MOUNT}"
      return 1
    fi
  else
    molt_info "backup: ${MOLT_BACKUP_MOUNT} is not mounted — nothing to repair"
  fi

  backup_check
}
