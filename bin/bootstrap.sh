#!/usr/bin/env bash
# bootstrap.sh — Molt bootstrap script
# Clones molt + user repo, links molt into ~/bin, runs dry-run.
#
# Usage:
#   MOLT_PRJ_DIR=~/Devel/prj bash bootstrap.sh
#   curl -fsSL <raw-url>/bin/bootstrap.sh | MOLT_PRJ_DIR=~/Devel/prj bash

set -euo pipefail

# --- Config ---
MOLT_PRJ_DIR="${MOLT_PRJ_DIR:-}"
MOLT_REPO="matthewsinclair/molt"

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

if [[ -z "$MOLT_PRJ_DIR" ]]; then
  error "MOLT_PRJ_DIR is not set."
  error "Set it to the directory where your molt repos should live, eg:"
  error "  MOLT_PRJ_DIR=\$HOME/Devel/prj bash bootstrap.sh"
  exit 1
fi

if ! command -v git &>/dev/null; then
  error "git not found. Install git first."
  exit 1
fi

if ! command -v curl &>/dev/null; then
  error "curl not found. Install curl first."
  exit 1
fi

ok "Prerequisites: git, curl"
info "MOLT_PRJ_DIR: $MOLT_PRJ_DIR"

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
  if timeout 5 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "git@github.com:${repo}.git"
  else
    echo "https://github.com/${repo}.git"
  fi
}

# --- Clone or pull repos ---

mkdir -p "$MOLT_PRJ_DIR"

clone_or_pull() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    ok "$dest already exists — pulling latest"
    git -C "$dest" pull --ff-only 2>/dev/null || info "pull skipped (not on tracking branch)"
  elif [[ -d "$dest" ]]; then
    info "$dest exists but is not a git repo — skipping"
  else
    local url
    url="$(git_url "$repo")"
    info "Cloning $url → $dest"
    git clone "$url" "$dest"
  fi
}

# Find existing repos (case-insensitive on macOS)
find_existing_repo() {
  local name="$1"
  # Check exact name first
  if [[ -d "$MOLT_PRJ_DIR/$name" ]]; then
    echo "$MOLT_PRJ_DIR/$name"
    return 0
  fi
  # Case-insensitive search in the projects dir
  local match
  match="$(find "$MOLT_PRJ_DIR" -maxdepth 1 -iname "$name" -type d 2>/dev/null | head -1)"
  if [[ -n "$match" ]]; then
    echo "$match"
    return 0
  fi
  # Not found — return default path
  echo "$MOLT_PRJ_DIR/$name"
  return 1
}

echo ""
info "Setting up repos in $MOLT_PRJ_DIR"

molt_dir="$(find_existing_repo "molt")" || true
user_dir="$(find_existing_repo "$MOLT_USER_REPO")" || true

clone_or_pull "$MOLT_REPO" "$molt_dir"
clone_or_pull "$MOLT_USER_REPO_FULL" "$user_dir"

# --- Link molt into ~/bin ---

echo ""
info "Linking molt into ~/bin"
mkdir -p "$HOME/bin"

if [[ -L "$HOME/bin/molt" ]]; then
  ok "~/bin/molt already linked"
elif [[ -e "$HOME/bin/molt" ]]; then
  error "~/bin/molt exists but is not a symlink — skipping"
else
  ln -s "$molt_dir/bin/molt" "$HOME/bin/molt"
  ok "Linked ~/bin/molt → $molt_dir/bin/molt"
fi

# --- Dry run ---

echo ""
info "Running dry run..."
echo ""
MOLT_PRJ_DIR="$MOLT_PRJ_DIR" "$molt_dir/bin/molt" resleeve --dry-run

echo ""
read -rp "Run molt resleeve now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  MOLT_PRJ_DIR="$MOLT_PRJ_DIR" "$molt_dir/bin/molt" resleeve
else
  info "Skipped. Run 'molt resleeve' when ready."
fi
