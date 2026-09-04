#!/usr/bin/env bash
# editors.sh — Liberator: Doom Emacs + LazyVim
# Frees you from nano.

editors_repo() {
  local doom_config="$HOME/.config/doom"
  if [[ -L "$doom_config" ]]; then
    local doom_repo
    doom_repo="$(readlink -f "$doom_config")"
    if git -C "$doom_repo" rev-parse --git-dir &>/dev/null 2>&1; then
      echo "$doom_repo"
      return 0
    fi
  elif [[ -d "$doom_config/.git" ]]; then
    echo "$doom_config"
    return 0
  fi
  return 1
}
editors_repo_git_commands() { echo "pull status log diff fetch"; }

# --- Emacs.app linkage (macOS) ----------------------------------------------
# Homebrew's opt/ prefix is version-stable: opt/emacs-plus@31 keeps following
# the formula as it moves 31.1 -> 31.2 -> ..., so linking /Applications/Emacs.app
# there survives patch bumps with no manual intervention.
#
# We deliberately resolve a NUMBERED formula and never the emacs-plus@master
# alias. @master tracks the unreleased Emacs master branch (32.0.50 at time of
# writing), so linking through it would silently move the GUI app onto a
# development build on some future brew upgrade.
editors_emacs_formula() {
  [[ "$(molt_platform)" == "macos" ]] || return 1
  command -v brew &>/dev/null || return 1

  # Explicit pin wins: export MOLT_EMACS_FORMULA=emacs-plus@32 to override.
  if [[ -n "${MOLT_EMACS_FORMULA:-}" ]]; then
    echo "$MOLT_EMACS_FORMULA"
    return 0
  fi

  # Otherwise the highest-numbered emacs-plus that is actually installed.
  local formula
  formula="$(brew list --formula 2>/dev/null \
    | grep -E '^emacs-plus@[0-9]+$' \
    | sort -t@ -k2,2n \
    | tail -1)"

  [[ -n "$formula" ]] || return 1
  echo "$formula"
}

editors_emacs_app_source() {
  local formula prefix
  formula="$(editors_emacs_formula)" || return 1
  prefix="$(brew --prefix 2>/dev/null)" || return 1
  echo "$prefix/opt/$formula/Emacs.app"
}

# --- Doom profile freshness -------------------------------------------------
# Doom compiles startup into $DOOMLOCALDIR/etc/@/init.<major>.<minor>.el. A brew
# upgrade that changes the Emacs version (eg 31.0.91 -> 31.1) leaves that file
# behind under the old name; Doom then starts with no profile at all and dies
# with "void-variable doom-modules". Catch it before Emacs is next opened.
#
# Returns 0 (true) only when we can positively determine the profile is stale.
editors_doom_profile_stale() {
  command -v emacs &>/dev/null || return 1

  local doom_local="${DOOMLOCALDIR:-$HOME/.config/emacs/.local}"
  [[ -d "$doom_local/etc/@" ]] || return 1  # never synced — not our warning

  local v
  v="$(editors_emacs_series)" || return 1
  [[ -n "$v" ]] || return 1

  [[ ! -f "$doom_local/etc/@/init.$v.el" ]]
}

# major.minor as Doom names it: 31.1 -> 31.1, 31.0.91 -> 31.0
# emacs-plus built --with-imagemagick hard-links libMagickWand/libMagickCore by
# exact soname, and imagemagick bumps that soname often and in both directions.
# Every bump then breaks Emacs at launch with a DYLD "Library not loaded" abort
# that also takes out `doom sync`, and the only cure is a ~15 minute source
# rebuild. It has cost this stack four separate mornings.
#
# Nothing is gained by it: svg, webp, png, jpeg, tiff and gif all come from
# librsvg, libtiff and webp directly, so dropping the flag leaves only
# (image-type-available-p 'imagemagick) nil. The tap deprecates the option too.
#
# Warn rather than fail: the fix is a long rebuild the user should choose when to
# run, and `brew reinstall` will NOT do it -- reinstall silently reuses
# used_options from INSTALL_RECEIPT.json, so it must be uninstall + install.
editors_warn_emacs_imagemagick() {
  [[ "$(molt_platform)" == "macos" ]] || return 0

  local formula app_bin
  formula="$(editors_emacs_formula)" || return 0
  app_bin="$(brew --prefix 2>/dev/null)/opt/${formula}/Emacs.app/Contents/MacOS/Emacs"
  [[ -x "$app_bin" ]] || return 0

  otool -L "$app_bin" 2>/dev/null | grep -qiE 'libMagick(Wand|Core)' || return 0

  molt_warn "editors: ${formula} is linked against ImageMagick — every imagemagick soname bump will break Emacs at launch"
  molt_warn "  Rebuild without it (reinstall is NOT enough, it reuses the recorded options):"
  molt_warn "    brew uninstall ${formula} && brew install ${formula} && molt resleeve editors"
  return 0
}

editors_emacs_series() {
  emacs --version 2>/dev/null | head -1 | awk '{print $3}' | cut -d. -f1,2
}

editors_check() {
  local ok=0

  if ! command -v emacs &>/dev/null; then
    molt_info "editors: emacs not installed"
    ok=1
  fi

  if ! command -v nvim &>/dev/null; then
    molt_info "editors: neovim not installed"
    ok=1
  fi

  editors_warn_emacs_imagemagick

  # Doom Emacs installed?
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "editors: Doom Emacs not installed"
    ok=1
  fi

  # Doom config linked?
  if ! molt_link_healthy "$HOME/.config/doom"; then
    molt_info "editors: ~/.config/doom $(molt_link_fault "$HOME/.config/doom")"
    ok=1
  fi

  # LazyVim installed?
  if [[ ! -f "$HOME/.config/nvim/init.lua" ]]; then
    molt_info "editors: LazyVim not installed"
    ok=1
  fi

  # macOS: the GUI app must exist and resolve to a real Emacs binary
  if [[ "$(molt_platform)" == "macos" ]]; then
    if [[ ! -e "/Applications/Emacs.app/Contents/MacOS/Emacs" ]]; then
      molt_info "editors: /Applications/Emacs.app missing or dangling"
      ok=1
    fi
  fi

  # Doom's compiled profile must match the running Emacs version
  if editors_doom_profile_stale; then
    molt_info "editors: no Doom profile for Emacs $(editors_emacs_series) — run: ~/.config/emacs/bin/doom sync"
    ok=1
  fi

  # On Linux/GNOME, check Emacs is in dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"emacs.desktop"* ]]; then
      molt_info "editors: Emacs not in GNOME dock favorites"
      ok=1
    fi
  fi

  return $ok
}

editors_install() {
  # Verify emacs is installed
  if ! command -v emacs &>/dev/null; then
    molt_error "emacs not found. Install it (eg apt install emacs, brew install emacs-plus@29) then re-run."
    return 1
  fi

  # Verify neovim is installed
  if ! command -v nvim &>/dev/null; then
    molt_error "neovim not found. Install it (eg apt install neovim, brew install neovim) then re-run."
    return 1
  fi

  # Install Doom Emacs
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    if [[ -d "$HOME/.config/emacs" ]]; then
      # shellcheck disable=SC2088
      molt_warn "~/.config/emacs exists but has no doom binary — skipping clone (move it aside to reinstall)"
    else
      molt_info "Installing Doom Emacs..."
      git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
    fi
  fi

  # Link Doom config from user repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  if [[ -d "$user_repo/config/doom" ]]; then
    molt_link "$user_repo/config/doom" "$HOME/.config/doom"
  fi

  # macOS: point /Applications/Emacs.app at the Homebrew keg via opt/
  if [[ "$(molt_platform)" == "macos" ]]; then
    local emacs_app
    if emacs_app="$(editors_emacs_app_source)" && [[ -e "$emacs_app" ]]; then
      molt_link "$emacs_app" "/Applications/Emacs.app"
    else
      molt_warn "No installed emacs-plus@<n> found — /Applications/Emacs.app not linked"
    fi
  fi

  # Doom manages its own packages — molt only clones and links config.
  # Run `doom install` or `doom sync` manually after first resleeve.
  if [[ -f "$HOME/.config/emacs/bin/doom" ]] && [[ ! -d "$HOME/.config/emacs/.local" ]]; then
    molt_warn "Doom Emacs cloned but not installed. Run: ~/.config/emacs/bin/doom install"
  fi

  # Install LazyVim — only if ~/.config/nvim does not exist at all
  if [[ ! -d "$HOME/.config/nvim" ]]; then
    molt_info "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
  elif [[ ! -f "$HOME/.config/nvim/init.lua" ]]; then
    # shellcheck disable=SC2088
    molt_warn "~/.config/nvim exists but has no init.lua — skipping LazyVim clone"
  fi

  # On Linux/GNOME, add Emacs to dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"emacs.desktop"* ]]; then
      local new_favorites
      new_favorites="${favorites/]/, \'emacs.desktop\']}"
      gsettings set org.gnome.shell favorite-apps "$new_favorites"
      molt_info "Added Emacs to GNOME dock favorites"
    fi
  fi

  molt_info "Liberator complete: editors"
}

editors_upgrade() {
  # Pull Doom Emacs config repo (reuse editors_repo for discovery)
  local doom_repo
  if doom_repo="$(editors_repo)"; then
    molt_info "Pulling Doom config repo..."
    if git -C "$doom_repo" pull --ff-only 2>/dev/null; then
      molt_info "Doom config updated."
    else
      molt_warn "Doom config pull skipped (not on tracking branch or already up-to-date)."
    fi
  else
    molt_debug "No Doom config repo found — skipping"
  fi

  # Sync Doom packages if doom binary exists
  if [[ -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "Running doom sync..."
    "$HOME/.config/emacs/bin/doom" sync 2>/dev/null || molt_warn "doom sync had warnings (review above)"
  fi
}

editors_maintain() {
  # Upgrade Doom Emacs framework itself (heavier than doom sync).
  # Uses --force to auto-accept prompts (doom's y-or-n-p reads from
  # Emacs's internal stdin, not the terminal, so interactive prompts
  # fail when called from a shell script).
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_debug "Doom binary not found — skipping doom upgrade"
    return 0
  fi

  molt_info "Running doom upgrade (this may take a while)..."
  "$HOME/.config/emacs/bin/doom" upgrade --force || molt_warn "doom upgrade had warnings (review above)"

  # `doom upgrade` short-circuits on "Doom is already up-to-date!" and returns
  # BEFORE the package sync. So when Doom itself is current but a previous run
  # left packages half-updated, upgrade does nothing, exits 0, and maintain
  # reports success while the orphaned packages are never retried.
  #
  # That is not hypothetical: a straight.el fetch died mid-run on kovacs
  # (package-lint renamed master->main upstream, the local clone had a
  # single-branch refspec pinned to master, so `git fetch origin` returned 128)
  # and aborted the update at 181/191. Re-running maintain reported success and
  # skipped the remaining ten every time; only a hand-run `doom sync -u`
  # recovered them.
  #
  # So always sync afterwards. It is cheap when there is nothing to do, and it
  # is the only step that actually reconciles the package set.
  molt_info "Running doom sync -u..."
  "$HOME/.config/emacs/bin/doom" sync -u || molt_warn "doom sync -u had warnings (review above)"

  _editors_warn_stale_straight_links
}

# Warn when straight.el has left dangling links in the ACTIVE build tree.
#
# straight.el adds and updates build-dir entries but does not PRUNE ones whose
# source has vanished upstream. When a package renames or drops a file, the old
# symlink survives pointing at nothing, and an autoloads file that still loads
# it breaks Emacs at boot with a bare (file-missing ...). kovacs hit exactly
# this: cider renamed cider-repl-history.el -> cider-history.el and dropped
# cider-jar.el; three links were left behind and Doom would not start.
#
# Same shape as the dangling-link bug in molt's own checks -- a step that adds
# and updates but never removes -- which is worth noting because this one is in
# somebody else's code. Build-and-link steps that never prune are common, and
# the failure is always silent until something downstream dereferences.
#
# Here rather than in _check because it costs ~60ms and _check runs on every
# resleeve, while this is only ever caused by the sync immediately above.
# The remedy is deliberately not automatic: deleting a build dir is destructive
# and the operator should choose it.
# MOLT_STRAIGHT_DIR / MOLT_EMACS_VERSION exist so this is testable without a
# real Emacs tree, and so a test never has to write into the live one.
_editors_warn_stale_straight_links() {
  local straight="${MOLT_STRAIGHT_DIR:-$HOME/.config/emacs/.local/straight}"
  [[ -d "$straight" ]] || return 0

  # Only the build dir for the running Emacs matters. Dirs for older versions
  # are orphaned and nothing loads them.
  local version build
  version="${MOLT_EMACS_VERSION:-$(emacs --batch --eval '(princ emacs-version)' 2>/dev/null)}"
  [[ -n "$version" ]] || return 0
  build="$straight/build-${version}"
  [[ -d "$build" ]] || return 0

  # find -L reports a symlink it cannot resolve as type l. Much cheaper than
  # -type l -exec test -e, which takes ~5s on a 6000-entry tree.
  local dangling
  dangling="$(find -L "$build" -type l 2>/dev/null | head -20)"
  [[ -n "$dangling" ]] || return 0

  molt_warn "editors: straight.el left dangling links in build-${version}:"
  printf '%s\n' "$dangling" | sed 's|^|          |'
  molt_warn "        A package renamed or dropped a file and straight did not prune."
  molt_warn "        Emacs will fail at boot if an autoloads file still loads one."
  molt_warn "        Fix: delete the affected package dir under ${build}/ and re-run"
  molt_warn "        'doom sync', then confirm with an actual batch boot."
}

editors_verify() {
  local errors=0

  if ! command -v emacs &>/dev/null; then
    molt_error "VERIFY FAIL: emacs not installed"
    errors=1
  fi

  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_error "VERIFY FAIL: Doom Emacs not installed"
    errors=1
  fi

  if ! molt_link_healthy "$HOME/.config/doom"; then
    molt_error "VERIFY FAIL: ~/.config/doom $(molt_link_fault "$HOME/.config/doom")"
    errors=1
  fi

  if ! command -v nvim &>/dev/null; then
    molt_error "VERIFY FAIL: neovim not installed"
    errors=1
  fi

  if [[ "$(molt_platform)" == "macos" ]] && [[ ! -e "/Applications/Emacs.app/Contents/MacOS/Emacs" ]]; then
    molt_error "VERIFY FAIL: /Applications/Emacs.app missing or dangling"
    errors=1
  fi

  if editors_doom_profile_stale; then
    molt_error "VERIFY FAIL: no Doom profile for Emacs $(editors_emacs_series) — run doom sync"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: editors liberator is fully operational"
  fi
  return $errors
}
