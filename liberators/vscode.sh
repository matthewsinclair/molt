#!/usr/bin/env bash
# vscode.sh — Liberator: Visual Studio Code
# Frees you from unconfigured editors with a consistent cross-platform setup.

_vscode_settings_dir() {
  case "$(molt_platform)" in
    linux) echo "$HOME/.config/Code/User" ;;
    macos) echo "$HOME/Library/Application Support/Code/User" ;;
  esac
}

vscode_check() {
  local ok=0

  if ! command -v code &>/dev/null; then
    molt_info "vscode: not installed"
    ok=1
    return $ok
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/vscode/settings.json" ]]; then
    local settings_dir
    settings_dir="$(_vscode_settings_dir)"
    if [[ ! -L "$settings_dir/settings.json" ]]; then
      molt_info "vscode: settings.json not symlinked"
      ok=1
    fi
  fi

  # On Linux/GNOME, check VSCode is in dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"code.desktop"* ]]; then
      molt_info "vscode: not in GNOME dock favorites"
      ok=1
    fi
  fi

  return $ok
}

vscode_install() {
  if ! command -v code &>/dev/null; then
    molt_error "VS Code not found. Install it first:"
    molt_error "  Linux: https://code.visualstudio.com/docs/setup/linux"
    molt_error "  macOS: brew install --cask visual-studio-code"
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  # Symlink settings.json
  if [[ -f "$user_repo/config/vscode/settings.json" ]]; then
    local settings_dir
    settings_dir="$(_vscode_settings_dir)"
    mkdir -p "$settings_dir"
    molt_link "$user_repo/config/vscode/settings.json" "$settings_dir/settings.json"
  fi

  # Symlink keybindings.json if present
  if [[ -f "$user_repo/config/vscode/keybindings.json" ]]; then
    local settings_dir
    settings_dir="$(_vscode_settings_dir)"
    molt_link "$user_repo/config/vscode/keybindings.json" "$settings_dir/keybindings.json"
  fi

  # On Linux/GNOME, add to dock favorites
  if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
    local favorites
    favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
    if [[ -n "$favorites" ]] && [[ "$favorites" != *"code.desktop"* ]]; then
      local new_favorites
      new_favorites="$(echo "$favorites" | sed "s/]/, 'code.desktop']/")"
      gsettings set org.gnome.shell favorite-apps "$new_favorites"
      molt_info "Added VS Code to GNOME dock favorites"
    fi
  fi

  molt_info "Liberator complete: vscode"
}

vscode_verify() {
  local errors=0

  if ! command -v code &>/dev/null; then
    molt_error "VERIFY FAIL: VS Code not installed"
    errors=1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/vscode/settings.json" ]]; then
    local settings_dir
    settings_dir="$(_vscode_settings_dir)"
    if [[ ! -L "$settings_dir/settings.json" ]]; then
      molt_error "VERIFY FAIL: VS Code settings.json not symlinked"
      errors=1
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: vscode liberator is fully operational"
  fi
  return $errors
}
