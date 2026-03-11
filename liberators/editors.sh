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

  # Doom Emacs installed?
  if [[ ! -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "editors: Doom Emacs not installed"
    ok=1
  fi

  # Doom config linked?
  if [[ ! -L "$HOME/.config/doom" ]]; then
    molt_info "editors: ~/.config/doom is not a symlink"
    ok=1
  fi

  # LazyVim installed?
  if [[ ! -f "$HOME/.config/nvim/init.lua" ]]; then
    molt_info "editors: LazyVim not installed"
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
    molt_warn "~/.config/nvim exists but has no init.lua — skipping LazyVim clone"
  fi

  # On Linux/GNOME, add Emacs to dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"emacs.desktop"* ]]; then
      local new_favorites
      new_favorites="$(echo "$favorites" | sed "s/]/, 'emacs.desktop']/")"
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
  # Upgrade Doom Emacs framework itself (heavier than doom sync)
  if [[ -f "$HOME/.config/emacs/bin/doom" ]]; then
    molt_info "Running doom upgrade (this may take a while)..."
    "$HOME/.config/emacs/bin/doom" upgrade || molt_warn "doom upgrade had warnings (review above)"
  else
    molt_debug "Doom binary not found — skipping doom upgrade"
  fi
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

  if [[ ! -L "$HOME/.config/doom" ]]; then
    molt_error "VERIFY FAIL: ~/.config/doom not symlinked"
    errors=1
  fi

  if ! command -v nvim &>/dev/null; then
    molt_error "VERIFY FAIL: neovim not installed"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: editors liberator is fully operational"
  fi
  return $errors
}
