#!/usr/bin/env bash
# zsh.sh — Liberator: shell + prompt
# Frees you from the default shell.

zsh_check() {
  local ok=0

  # Is zsh installed?
  if ! command -v zsh &>/dev/null; then
    molt_info "zsh: not installed"
    return 1
  fi

  # Is zsh the default shell?
  local current_shell
  current_shell="$(dscl . -read /Users/"$(whoami)" UserShell 2>/dev/null | awk '{print $2}' || getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
  if [[ "$current_shell" != *"zsh"* ]]; then
    molt_info "zsh: installed but not default shell (current: $current_shell)"
    ok=1
  fi

  # Is Starship installed?
  if ! command -v starship &>/dev/null; then
    molt_info "zsh: Starship prompt not installed"
    ok=1
  fi

  # Are config files linked?
  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    if [[ ! -L "$HOME/.zshrc" ]]; then
      molt_info "zsh: ~/.zshrc is not a symlink"
      ok=1
    fi
  fi

  return $ok
}

zsh_install() {
  # Verify zsh is installed
  if ! command -v zsh &>/dev/null; then
    molt_error "zsh not found. Install it (eg apt install zsh, brew install zsh) then re-run."
    return 1
  fi

  # Set as default shell
  local zsh_path
  zsh_path="$(which zsh)"
  local current_shell
  current_shell="$(dscl . -read /Users/"$(whoami)" UserShell 2>/dev/null | awk '{print $2}' || getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
  if [[ "$current_shell" != *"zsh"* ]]; then
    molt_info "Setting zsh as default shell..."
    chsh -s "$zsh_path"
  fi

  # Verify Starship is installed
  if ! command -v starship &>/dev/null; then
    molt_error "Starship not found. Install it (https://starship.rs) then re-run."
    return 1
  fi

  # Link config from user repo
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  molt_link "$user_repo/config/zsh/zshrc" "$HOME/.zshrc"
  molt_link "$user_repo/config/zsh/zshenv" "$HOME/.zshenv"
  molt_link "$user_repo/config/zsh/zprofile" "$HOME/.zprofile"

  if [[ -f "$user_repo/config/starship/starship.toml" ]]; then
    molt_link "$user_repo/config/starship/starship.toml" "$HOME/.config/starship.toml"
  fi

  molt_info "Liberator complete: zsh"
}

zsh_verify() {
  local errors=0

  if ! command -v zsh &>/dev/null; then
    molt_error "VERIFY FAIL: zsh not installed"
    errors=1
  fi

  if ! command -v starship &>/dev/null; then
    molt_error "VERIFY FAIL: Starship not installed"
    errors=1
  fi

  if [[ ! -L "$HOME/.zshrc" ]]; then
    molt_error "VERIFY FAIL: ~/.zshrc not symlinked"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: zsh liberator is fully operational"
  fi
  return $errors
}
