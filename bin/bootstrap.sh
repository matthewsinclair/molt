#!/usr/bin/env bash
# bootstrap.sh — Molt bootstrap script
# Clones molt + user repo, links molt into ~/.local/bin, runs dry-run.
#
# Usage:
#   MOLT_PRJ_DIR=~/Devel/prj bash bootstrap.sh
#   curl -fsSL <raw-url>/bin/bootstrap.sh | MOLT_PRJ_DIR=~/Devel/prj bash

set -euo pipefail

# --- Config ---
MOLT_PRJ_DIR="${MOLT_PRJ_DIR:-}"
# Where the user config repo goes. Same derivation as lib/constants.sh, restated
# because this script runs before the framework is cloned and cannot source it.
MOLT_CFG_DIR="${MOLT_CFG_DIR:-${MOLT_PRJ_DIR:+$(dirname "$MOLT_PRJ_DIR")/cfg}}"
# GitHub owner/repo of the framework. Override to bootstrap from your own fork.
MOLT_REPO="${MOLT_REPO:-matthewsinclair/molt}"
# Where the closing question is asked. Not stdin: piped from curl, stdin is the
# rest of this script (issue 0050).
MOLT_BOOTSTRAP_TTY="${MOLT_BOOTSTRAP_TTY:-/dev/tty}"

# Detect current user for user repo name. The GitHub repo is lowercase; the
# local directory is Capitalised, which is what molt doctor checks for.
MOLT_USER_REPO="molt-$(whoami)"
MOLT_USER_DIR="Molt-$(whoami)"
# GitHub owner of YOUR personal config repo. Defaults to your local username;
# override when your GitHub handle differs, eg:
#   MOLT_USER_GH=flynn-sinclair bash bootstrap.sh
MOLT_USER_GH="${MOLT_USER_GH:-$(whoami)}"
MOLT_USER_REPO_FULL="${MOLT_USER_GH}/${MOLT_USER_REPO}"

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
info "MOLT_CFG_DIR: $MOLT_CFG_DIR"

# --- Detect platform ---

platform="unknown"
case "$(uname -s)" in
  Linux*)  platform="linux" ;;
  Darwin*) platform="macos" ;;
esac
info "Platform: $platform"

# --- Determine git URL scheme ---

git_url() {
  local repo="$1" ssh_out
  # Capture, then match: a pipeline into `grep -q` can lose under pipefail
  # (issue 0008). ssh -T exits 1 even when it authenticates, hence || true.
  # -n: piped from curl, stdin is the rest of this script (issue 0050).
  ssh_out="$(timeout 5 ssh -n -T git@github.com 2>&1 || true)"
  if [[ "$ssh_out" == *"successfully authenticated"* ]]; then
    echo "git@github.com:${repo}.git"
  else
    echo "https://github.com/${repo}.git"
  fi
}

# --- Clone or pull repos ---

mkdir -p "$MOLT_PRJ_DIR" "$MOLT_CFG_DIR"

clone_or_pull() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    ok "$dest already exists — pulling latest"
    # Only a branch with no upstream skips; any other failed pull stops the
    # bootstrap, with git's own words above it (issue 0037).
    local branch
    if ! branch="$(git -C "$dest" symbolic-ref -q --short HEAD)" \
      || ! git -C "$dest" config "branch.${branch}.merge" >/dev/null; then
      info "pull skipped: $dest has no upstream branch"
    elif ! git -C "$dest" pull --ff-only; then
      error "pull failed in $dest: git's reason is above"
      exit 1
    fi
  elif [[ -d "$dest" ]]; then
    info "$dest exists but is not a git repo — skipping"
  else
    local url
    url="$(git_url "$repo")"
    info "Cloning $url → $dest"
    git clone "$url" "$dest"
  fi
}

# Find an existing repo (case-insensitive on macOS) in each directory in turn.
# Usage: find_existing_repo <name> <dir> [<dir> ...]
# Prints the match, or <first dir>/<name> and returns 1 when there is none.
find_existing_repo() {
  local name="$1"
  shift
  local dir match
  for dir in "$@"; do
    # Check exact name first
    if [[ -d "$dir/$name" ]]; then
      echo "$dir/$name"
      return 0
    fi
    # Case-insensitive search in this dir
    match="$(find "$dir" -maxdepth 1 -iname "$name" -type d 2>/dev/null | head -1)"
    if [[ -n "$match" ]]; then
      echo "$match"
      return 0
    fi
  done
  # Not found — return default path
  echo "$1/$name"
  return 1
}

echo ""
info "Setting up molt in $MOLT_PRJ_DIR and your config repo in $MOLT_CFG_DIR"

# Exact-case Molt, where molt use dev looks for the dev tree (issue 0049).
molt_dir="$(find_existing_repo "Molt" "$MOLT_PRJ_DIR")" || true
# A user repo cloned before MOLT_CFG_DIR existed lives in MOLT_PRJ_DIR; use it
# where it is rather than cloning a second copy.
user_dir="$(find_existing_repo "$MOLT_USER_DIR" "$MOLT_CFG_DIR" "$MOLT_PRJ_DIR")" || true

clone_or_pull "$MOLT_REPO" "$molt_dir"
clone_or_pull "$MOLT_USER_REPO_FULL" "$user_dir"

# --- Link molt into ~/.local/bin ---

# The switch molt use sets (devbin docs/dev-opt-brew.md T5): a bootstrap is
# a dev tree, so it links the checkout.
echo ""
info "Linking molt into ~/.local/bin"
mkdir -p "$HOME/.local/bin"

if [[ -L "$HOME/.local/bin/molt" ]]; then
  # shellcheck disable=SC2088 # a message naming the path as a person writes it
  ok "~/.local/bin/molt already linked"
elif [[ -e "$HOME/.local/bin/molt" ]]; then
  # shellcheck disable=SC2088 # a message naming the path as a person writes it
  error "~/.local/bin/molt exists but is not a symlink — skipping"
else
  ln -s "$molt_dir/bin/molt" "$HOME/.local/bin/molt"
  ok "Linked ~/.local/bin/molt → $molt_dir/bin/molt"
fi

# --- Dry run ---

echo ""
info "Running dry run..."
echo ""
MOLT_PRJ_DIR="$MOLT_PRJ_DIR" MOLT_CFG_DIR="$MOLT_CFG_DIR" "$molt_dir/bin/molt" resleeve --dry-run

echo ""
if ! { exec 3<"$MOLT_BOOTSTRAP_TTY"; } 2>/dev/null; then
  error "no terminal ($MOLT_BOOTSTRAP_TTY) to ask whether to run molt resleeve; run 'molt resleeve' when ready"
  exit 1
fi
read -rp "Run molt resleeve now? [y/N] " answer <&3
exec 3<&-
if [[ "$answer" =~ ^[Yy]$ ]]; then
  MOLT_PRJ_DIR="$MOLT_PRJ_DIR" MOLT_CFG_DIR="$MOLT_CFG_DIR" "$molt_dir/bin/molt" resleeve
else
  info "Skipped. Run 'molt resleeve' when ready."
fi
