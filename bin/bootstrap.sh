#!/usr/bin/env bash
# bootstrap.sh — Molt bootstrap script
# Clones molt + user repo, links molt into ~/bin, runs dry-run.
# Usage: curl -fsSL <raw-url>/bin/bootstrap.sh | bash

set -euo pipefail

# --- Config ---
MOLT_REPO="matthewsinclair/molt"
DEV_DIR="$HOME/Devel/prj"

# Detect current user for user repo name
MOLT_USER_REPO="molt-$(whoami)"
MOLT_USER_REPO_FULL="matthewsinclair/${MOLT_USER_REPO}"

# --- Helpers ---

info()  { echo "  → $*"; }
error() { echo "  ✗ $*" >&2; }
ok()    { echo "  ✓ $*"; }

# --- Prerequisites ---

echo "MOLT Bootstrap"
echo ""

if ! command -v git &>/dev/null; then
  error "git not found. Install git first."
  exit 1
fi

if ! command -v curl &>/dev/null; then
  error "curl not found. Install curl first."
  exit 1
fi

ok "Prerequisites: git, curl"

# --- Detect platform ---

platform="unknown"
case "$(uname -s)" in
  Linux*)  platform="linux" ;;
  Darwin*) platform="macos" ;;
esac
info "Platform: $platform"

# --- Determine git URL scheme ---

git_url() {
  local repo="$1"
  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "git@github.com:${repo}.git"
  else
    echo "https://github.com/${repo}.git"
  fi
}

# --- Clone or pull repos ---

mkdir -p "$DEV_DIR"

clone_or_pull() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    ok "$dest already exists — pulling latest"
    git -C "$dest" pull --ff-only 2>/dev/null || info "pull skipped (not on tracking branch)"
  else
    local url
    url="$(git_url "$repo")"
    info "Cloning $url → $dest"
    git clone "$url" "$dest"
  fi
}

echo ""
info "Setting up repos in $DEV_DIR"
clone_or_pull "$MOLT_REPO" "$DEV_DIR/molt"
clone_or_pull "$MOLT_USER_REPO_FULL" "$DEV_DIR/${MOLT_USER_REPO}"

# --- Link molt into ~/bin ---

echo ""
info "Linking molt into ~/bin"
mkdir -p "$HOME/bin"

if [[ -L "$HOME/bin/molt" ]]; then
  ok "~/bin/molt already linked"
elif [[ -e "$HOME/bin/molt" ]]; then
  error "~/bin/molt exists but is not a symlink — skipping"
else
  ln -s "$DEV_DIR/molt/bin/molt" "$HOME/bin/molt"
  ok "Linked ~/bin/molt → $DEV_DIR/molt/bin/molt"
fi

# --- Dry run ---

echo ""
info "Running dry run..."
echo ""
"$DEV_DIR/molt/bin/molt" resleeve --dry-run

echo ""
read -rp "Run molt resleeve now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  "$DEV_DIR/molt/bin/molt" resleeve
else
  info "Skipped. Run 'molt resleeve' when ready."
fi
