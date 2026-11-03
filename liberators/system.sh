#!/usr/bin/env bash
# system.sh — Liberator: base system setup
# Frees you from a bare OS.
#
# It installs nothing: it names what a sleeve lacks, and how to get it.

# What keeps this sleeve from being ready, one fault a line with its remedy, or
# nothing: no sudo; on Linux, a user in neither the sudo group (Debian, Ubuntu)
# nor the wheel group (Fedora, RHEL, Arch); on macOS, no Homebrew. Check,
# install and verify all read it, so they cannot disagree (issue 0085).
_system_faults() {
  if ! command -v sudo &>/dev/null; then
    echo "sudo is not installed: install it as root, then re-run"
  fi
  case "$(molt_platform)" in
    linux)
      # Capture, then match (issue 0008): under pipefail a SIGPIPE'd writer
      # would read as membership of no group.
      local user user_groups
      user="$(whoami)"
      user_groups="$(groups "$user" 2>/dev/null)" || user_groups=""
      case " $user_groups " in
        *" sudo "* | *" wheel "*) ;;
        *) echo "$user is in neither the sudo group nor the wheel group: as root, add $user to sudo (Debian, Ubuntu) or wheel (Fedora, RHEL, Arch), then log in again" ;;
      esac
      ;;
    macos)
      if ! command -v brew &>/dev/null; then
        echo "Homebrew is not installed: install it from https://brew.sh, then re-run"
      fi
      ;;
  esac
}

system_check() {
  molt_report_faults molt_info "" system "$(_system_faults)"
}

# Names each fault and fails: what a fault needs is the user's to install.
system_install() {
  molt_report_faults molt_error "" system "$(_system_faults)" || return 1
  molt_info "Liberator complete: system"
}

system_verify() {
  molt_report_faults molt_error "VERIFY FAIL: " system "$(_system_faults)" || return 1
  molt_info "Verified: system liberator is fully operational"
}
