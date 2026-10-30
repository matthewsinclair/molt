#!/usr/bin/env bash
# local-bin.sh — Liberator: local bin directory
# Frees you from scattering executables.
#
# $MOLT_LOCAL_BIN/molt is the switch between the dev, opt and brew trees, and
# molt use is what flips it (ST0008; devbin docs/dev-opt-brew.md T5). This
# liberator does not choose: a link to a dev or opt tree's bin/molt is kept,
# and no link at all is brew. Install makes a missing or broken link only when
# the running tree is dev or opt and Homebrew's molt is not what PATH runs,
# pointing it at that tree; in brew, or with brew serving molt, it makes
# nothing, since a link would undo molt use brew at the next resleeve. It never removes a link, and anything else at the link's path, a
# file or a link to no tree, is somebody's, and is refused by name. Before,
# install linked it to whichever tree was running, so a resleeve from the
# checkout flipped an opt sleeve back to dev.

# True when there is no switch link and Homebrew's molt is what PATH runs: the
# sleeve has chosen brew, whichever tree this molt runs from (issue 0067). A dev
# clone's doctor once read that as local-bin not installed and advised a
# resleeve, and the resleeve would have linked the sleeve to the clone.
_local-bin_brew_serves() {
  local link
  link="$(molt_switch_link)"
  [[ ! -e "$link" && ! -L "$link" ]] && molt_brew_on_path >/dev/null
}

# Why the switch is not as this liberator wants it, or nothing when it is:
# a healthy link to a dev or opt tree, or no link while brew is running or
# serves molt. A link into the brew tree is the old way to choose brew, which
# molt use brew now does by removing it.
_local-bin_fault() {
  local link root
  link="$(molt_switch_link)"
  if [[ ! -e "$link" && ! -L "$link" ]] && [[ "$(molt_tree)" == brew ]]; then
    return 0
  fi
  _local-bin_brew_serves && return 0
  if ! root="$(molt_served_tree)"; then
    echo "$root"
  elif [[ "$(molt_tree "$root")" == brew ]]; then
    echo "$(molt_tilde "$link") leads into the brew tree; run molt use brew, which removes it, since no link means brew"
  fi
}

# What serves molt, as verify names it: the link's tree, or brew with no link,
# named by the brew tree PATH runs, not by the tree this molt runs from.
_local-bin_served_line() {
  local link root
  link="$(molt_switch_link)"
  if root="$(molt_served_tree)"; then
    echo "$(molt_tilde "$link") serves $(molt_version_line "$root")"
  elif root="$(molt_brew_on_path)"; then
    echo "there is no $(molt_tilde "$link"), so brew serves $(molt_version_line "$root")"
  else
    echo "there is no $(molt_tilde "$link"), so brew serves $(molt_version_line)"
  fi
}

local-bin_check() {
  local ok=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "local-bin: $MOLT_LOCAL_BIN does not exist"
    ok=1
  fi

  # PATH is zsh's responsibility (via path_add in .zshrc), not the liberator's.
  # Only log at debug level — not a failure condition.
  if [[ ":$PATH:" != *":$MOLT_LOCAL_BIN:"* ]]; then
    molt_debug "local-bin: $MOLT_LOCAL_BIN is not on PATH (expected if not running from zsh)"
  fi

  local fault
  fault="$(_local-bin_fault)"
  if [[ -n "$fault" ]]; then
    molt_info "local-bin: $fault"
    ok=1
  fi

  return $ok
}

local-bin_install() {
  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_info "Creating $MOLT_LOCAL_BIN..."
    mkdir -p "$MOLT_LOCAL_BIN" || { molt_error "local-bin: $MOLT_LOCAL_BIN could not be made"; return 1; }
  fi

  # A link to any tree is the sleeve's choice, made with molt use, and kept.
  local link fault tree
  link="$(molt_switch_link)"
  tree="$(molt_tree)"
  if ! fault="$(molt_served_tree)"; then
    if [[ -e "$link" ]]; then
      molt_error "local-bin: $fault; it is left as it is, so move it aside, then run molt use dev, opt or brew"
      return 1
    fi
    case "$tree" in
      dev|opt)
        if _local-bin_brew_serves; then
          molt_info "local-bin: no $(molt_tilde "$link"), so brew serves molt, not this $tree tree at $(molt_tilde "$MOLT_ROOT"); molt use $tree links it, and nothing here does"
        else
          molt_link "$MOLT_ROOT/bin/molt" "$link" || return 1
        fi ;;
      brew)
        if [[ -L "$link" ]]; then
          molt_error "local-bin: $fault; it is left as it is, so remove it with molt use brew"
          return 1
        fi
        molt_info "local-bin: no $(molt_tilde "$link"), so brew serves molt" ;;
      *)
        molt_error "local-bin: $(molt_tilde "$MOLT_ROOT") is no dev, opt or brew tree, so $(molt_tilde "$link") is not made"
        return 1 ;;
    esac
  fi

  molt_info "Liberator complete: local-bin"
}

local-bin_verify() {
  local errors=0

  if [[ ! -d "$MOLT_LOCAL_BIN" ]]; then
    molt_error "VERIFY FAIL: $MOLT_LOCAL_BIN does not exist"
    errors=1
  fi

  local fault
  fault="$(_local-bin_fault)"
  if [[ -n "$fault" ]]; then
    molt_error "VERIFY FAIL: $fault"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: local-bin liberator is fully operational; $(_local-bin_served_line)"
  fi
  return $errors
}
