#!/usr/bin/env bash
# install.sh — The trees Molt runs from, read (ST0008; issue I7892f34).
#
# A tree is a directory holding bin/molt, lib/, liberators/, templates/ and
# VERSION. dev is the git checkout; opt is what bin/devbin install publishes
# from a clean dev tree to install.prefix in bin/.devbin/config.yaml; brew is
# the same publish, run by the formula in its keg (devbin#0326). Molt publishes
# and switches nothing itself: bin/devbin install and bin/devbin use do, in the
# checkout. What stays here reads a tree, its manifest and the switch link, on
# a sleeve that has no bin/devbin. bin/molt finds MOLT_ROOT from its own
# resolved path in every tree, so nothing here reads MOLT_ROOT from the
# environment. Sourced by bin/molt after lib/molt.sh, whose helpers it uses.

# The manifest devbin's publish writes at the root of the tree it makes, in the form
# devbin's docs/dev-opt-brew.md T3 fixes for every tool: header lines of
# `# key: value` (tool, version, source_commit, managed_by), then one line per
# file in the form `shasum -a 256 -c` reads, sorted by LC_ALL=C sort, so a
# tree can be checked by hand from inside it.
MOLT_INSTALL_MANIFEST=".molt-install"

# The formula, by its tap-qualified name, that the brew tree is the keg of.
MOLT_BREW_FORMULA="matthewsinclair/molt/molt"

# The runtime set's pathspecs, one per line. What git names under these is the
# runtime set and nothing else: no test/, intent/, docs/ or board. They are the
# places bin/.devbin/config.yaml's install: block publishes, read here only to
# mark a dev tree +dirty and to name a published file the manifest lacks.
_molt_runtime_pathspecs() {
  printf '%s\n' bin/molt lib liberators templates VERSION
}

# Prints the runtime set's changes in the dev tree $1, as git status --porcelain
# shows them (staged, unstaged and untracked-but-not-ignored alike), and fails
# when there are none. An untracked file counts: git does not name it, so it
# would not publish, yet it runs in dev. Fails with status 2, printing why,
# when git cannot say. git's stderr is kept out of the changes, so a warning
# git prints is never read as a changed file.
molt_runtime_set_dirty() {
  local root="$1" specs=() out
  while IFS= read -r spec; do specs+=("$spec"); done < <(_molt_runtime_pathspecs)
  if ! out="$(git -C "$root" status --porcelain --untracked-files=all -- "${specs[@]}" 2>/dev/null)"; then
    out="$(git -C "$root" status --porcelain --untracked-files=all -- "${specs[@]}" 2>&1 >/dev/null)"
    echo "git status failed in $root: $out"
    return 2
  fi
  [[ -n "$out" ]] || return 1
  printf '%s\n' "$out"
}

# The value of the header key $2 in the manifest of the tree $1, read from its
# `# key: value` line, or nothing.
molt_install_field() {
  local manifest="$1/$MOLT_INSTALL_MANIFEST"
  [[ -f "$manifest" ]] || return 0
  awk -v k="# $2:" 'index($0, k) == 1 { v = substr($0, length(k) + 1); sub(/^[[:space:]]+/, "", v); print v; exit }' "$manifest"
}

# The form of the tree $1's manifest: current when it carries the `# tool:`
# header, old when it is a manifest from before the contract, with bare
# `key: value` headers, and none when there is no manifest. The old form is
# not read as a second format (T3): it is named, with its remedy.
molt_install_form() {
  local manifest="$1/$MOLT_INSTALL_MANIFEST"
  if [[ ! -f "$manifest" ]]; then
    echo none
  elif grep -q '^# tool:' "$manifest" 2>/dev/null; then
    echo current
  else
    echo old
  fi
}

# True when the tree $1 lands in a Homebrew keg of molt, Cellar/molt/<ver>/libexec,
# which makes it the brew tree whatever its manifest says (T3 as amended by
# decision 58: an old-form or manifest-less keg still answers brew).
_molt_in_keg() {
  [[ "$(_molt_realpath "$1")" == */Cellar/molt/*/libexec ]]
}

# Names what an old-form or missing manifest means in the tree $1, and its
# remedy, or prints nothing when its manifest is current or it is a dev tree.
# In brew it is a note, in opt a fault (T3, decision 58); the doctor says which.
molt_install_form_fault() {
  local root="$1" manifest
  manifest="$(molt_tilde "$1/$MOLT_INSTALL_MANIFEST")"
  case "$(molt_install_form "$root")" in
    current) ;;
    old)
      if [[ "$(molt_tree "$root")" == brew ]]; then
        echo "$manifest is an old manifest, from before the dev/opt/brew contract; brew upgrade $MOLT_BREW_FORMULA writes a current one"
      else
        echo "$manifest is an old manifest, from before the dev/opt/brew contract; republish with bin/devbin install --force in the dev tree"
      fi ;;
    none)
      [[ "$(molt_tree "$root")" != brew ]] \
        || echo "$(molt_tilde "$root") is Homebrew's keg with no manifest; brew upgrade $MOLT_BREW_FORMULA writes one" ;;
  esac
}

# True when $1 is the top of a git work tree.
_molt_is_work_tree_top() {
  local top
  top="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 1
  molt_same_file "$top" "$1"
}

# Names the tree $1 (MOLT_ROOT by default), in T4's order: brew when its
# manifest says managed_by: brew, opt when its manifest's tool is molt, dev when
# it is a git work tree with no manifest, and unknown otherwise. A Homebrew keg
# of molt is brew whatever its manifest, old or missing (decision 58); an
# old-form manifest anywhere else is unknown, and molt_install_form_fault names
# its remedy. Every caller that needs to know which tree is running asks this.
molt_tree() {
  local root="${1:-$MOLT_ROOT}"
  case "$(molt_install_form "$root")" in
    current)
      if [[ "$(molt_install_field "$root" managed_by)" == brew ]]; then
        echo brew
      elif [[ "$(molt_install_field "$root" tool)" == molt ]]; then
        echo opt
      else
        echo unknown
      fi ;;
    *)
      if _molt_in_keg "$root"; then
        echo brew
      elif [[ "$(molt_install_form "$root")" == none ]] && _molt_is_work_tree_top "$root"; then
        echo dev
      else
        echo unknown
      fi ;;
  esac
}

# The commit the tree $1 was made from, in full: HEAD in dev, and the
# manifest's source commit in opt and brew. Fails, printing nothing, when it
# cannot be read. Every reader of a tree's commit asks this.
molt_tree_source_commit() {
  local root="$1" commit=""
  case "$(molt_tree "$root")" in
    dev) commit="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || commit="" ;;
    opt|brew) commit="$(molt_install_field "$root" source_commit)" ;;
  esac
  [[ -n "$commit" ]] || return 1
  echo "$commit"
}

# The commit the tree $1 runs, as T4's version line shows it: twelve digits,
# with +dirty when it is a dev tree whose runtime set has changes. Prints
# unknown when it cannot be read, a dev tree's git refusing it included; the
# doctor says why.
molt_tree_commit() {
  local root="$1" commit dirty_status=1
  commit="$(molt_tree_source_commit "$root")" || commit=""
  if [[ -n "$commit" && "$(molt_tree "$root")" == dev ]]; then
    dirty_status=0
    molt_runtime_set_dirty "$root" >/dev/null || dirty_status=$?
  fi
  if [[ -z "$commit" ]]; then
    echo unknown
    return 0
  fi
  case "$dirty_status" in
    0) echo "${commit:0:12}+dirty" ;;
    1) echo "${commit:0:12}" ;;
    *) echo unknown ;;
  esac
}

# Why a dev tree's commit reads unknown, or nothing when it reads: what git
# said when it could not read HEAD or the runtime set's status.
molt_tree_commit_fault() {
  local root="$1" out
  [[ "$(molt_tree "$root")" == dev ]] || return 0
  if ! out="$(git -C "$root" rev-parse HEAD 2>&1 >/dev/null)"; then
    echo "git cannot read HEAD in $root: $out"
    return 0
  fi
  out="$(molt_runtime_set_dirty "$root")" && return 0
  [[ $? -eq 1 ]] || echo "$out"
}

# The version line for the tree $1 (MOLT_ROOT by default), in T4's one shape
# as A3 amends it, eg `molt 0.3.0 (opt, 905305c1a2b3)`, or `molt 0.3.0 (dev,
# unknown)`. It names no path: `command -v molt` says where the running copy
# lives, and a check that fails about a path names that path itself. Molt is
# a script tool, so nothing follows the parenthesis (issue 0063). molt
# version, molt --version and the doctor print it.
molt_version_line() {
  local root="${1:-$MOLT_ROOT}" version
  version="$(cat "$root/VERSION" 2>/dev/null)" || version="unknown version"
  echo "molt ${version} ($(molt_tree "$root"), $(molt_tree_commit "$root"))"
}

# Names each file in the opt or brew tree $1 that differs from its manifest:
# changed, missing, or under a directory the runtime set's pathspecs start in
# without being listed. Prints nothing when the tree is what the manifest says.
# Fails, printing why, when the manifest cannot be read.
molt_install_drift() {
  local root="$1" manifest="$1/$MOLT_INSTALL_MANIFEST" sum path actual
  if [[ ! -r "$manifest" ]]; then
    echo "$(molt_tilde "$manifest") cannot be read"
    return 1
  fi
  local listed=""
  while IFS= read -r line; do
    [[ "$line" =~ ^([0-9a-f]{64})\ \ (.+)$ ]] || continue
    sum="${BASH_REMATCH[1]}" path="${BASH_REMATCH[2]}"
    listed+="$path"$'\n'
    if [[ ! -f "$root/$path" ]]; then
      echo "$path is missing"
    elif ! actual="$(molt_hash < "$root/$path")"; then
      echo "$path cannot be hashed"
    elif [[ "$actual" != "$sum" ]]; then
      echo "$path has changed"
    fi
  done < "$manifest"
  # Each pathspec's first directory, once: bin/molt scans all of bin/.
  local spec dir f scanned=$'\n'
  while IFS= read -r spec; do
    dir="${spec%%/*}"
    [[ "$scanned" != *$'\n'"$dir"$'\n'* && -d "$root/$dir" ]] || continue
    scanned+="$dir"$'\n'
    while IFS= read -r f; do
      f="${f#"$root"/}"
      [[ $'\n'"$listed" == *$'\n'"$f"$'\n'* ]] || echo "$f is not in the manifest"
    done < <(find "$root/$dir" -type f -o -type l)
  done < <(_molt_runtime_pathspecs)
}

# --- the switch ---

# The per-user link bin/devbin use sets, from install.links in
# bin/.devbin/config.yaml, the whole of Molt's link set (T5): one link, named
# here once. Every reader of the switch asks this.
molt_switch_link() {
  echo "$MOLT_LOCAL_BIN/molt"
}

# The root this sleeve declares for the tree $1 (dev or brew), whether or not
# anything is there: the checkout under MOLT_PRJ_DIR, or the formula's opt link.
# Fails, printing why instead, when the sleeve declares none. opt has no root
# a sleeve declares: devbin reads it from the checkout's config.
molt_tree_root() {
  local root
  case "$1" in
    dev)
      if [[ -z "${MOLT_PRJ_DIR:-}" ]]; then
        echo "MOLT_PRJ_DIR is not set, so this sleeve has no dev tree"
        return 1
      fi
      echo "$MOLT_PRJ_DIR/Molt" ;;
    brew)
      if ! root="$(HOMEBREW_NO_AUTO_UPDATE=1 brew --prefix 2>/dev/null)" || [[ -z "$root" ]]; then
        echo "brew is not on PATH, so this sleeve has no brew tree"
        return 1
      fi
      echo "$root/opt/molt/libexec" ;;
  esac
}

# The root of the tree the switch link serves. Fails, printing why instead,
# when there is no link, it is broken, or it leads to a bin/molt that is no
# dev, opt or brew tree's. The doctor and the local-bin liberator ask this.
molt_served_tree() {
  local link target root
  link="$(molt_switch_link)"
  if ! molt_link_healthy "$link"; then
    echo "$(molt_tilde "$link") $(molt_link_fault "$link")"
    return 1
  fi
  target="$(_molt_realpath "$link")"
  root="${target%/bin/molt}"
  if [[ "$root" == "$target" ]] || [[ "$(molt_tree "$root")" == unknown ]]; then
    echo "$(molt_tilde "$link") leads to $(molt_tilde "$target"), which is no dev, opt or brew tree's bin/molt"
    return 1
  fi
  echo "$root"
}

# The root of the brew tree the first molt on PATH resolves into, when there
# is no switch link: no link means brew (T5). Fails, printing why instead,
# when PATH runs no molt, or one that is no brew tree's.
molt_brew_on_path() {
  local first target root
  first="$(type -ap molt 2>/dev/null | head -n 1)" || first=""
  if [[ -z "$first" ]]; then
    echo "there is no $(molt_tilde "$(molt_switch_link)") and no molt on PATH; install it with brew install $MOLT_BREW_FORMULA, or run bin/devbin use dev or opt in the checkout"
    return 1
  fi
  target="$(_molt_realpath "$first")"
  root="${target%/bin/molt}"
  if [[ "$root" == "$target" ]] || [[ "$(molt_tree "$root")" != brew ]]; then
    echo "there is no $(molt_tilde "$(molt_switch_link)"), so brew should serve molt, but PATH runs $(molt_tilde "$first"), which is no brew tree's"
    return 1
  fi
  echo "$root"
}

# Refuses, naming the dev tree to run it in, the verb $1 anywhere but a dev
# tree: molt test and its lint have no test/ to run in opt or brew.
molt_require_dev_tree() {
  local tree dev
  tree="$(molt_tree)"
  [[ "$tree" != dev ]] || return 0
  if dev="$(molt_tree_root dev)"; then
    molt_error "$1 runs in a dev tree, and this is the $tree tree at $(molt_tilde "$MOLT_ROOT"); run it in $(molt_tilde "$dev")"
  else
    molt_error "$1 runs in a dev tree, and this is the $tree tree at $(molt_tilde "$MOLT_ROOT"); $dev"
  fi
  return 1
}

# Names what runs for molt instead of the switch, and prints nothing when the
# switch answers (T5). With a link, it must be the first molt on PATH: any other
# molt ahead of it, a brew link included, takes bin/devbin use's choice away (on
# rhadamanth a ~/.local/bin/molt from March once ran instead). With no link,
# brew serves molt, so the first molt on PATH must resolve into the brew tree.
# Directories are compared where they resolve, never as strings, since
# rhadamanth's ~/bin is a link to ~/.local/bin. The doctor asks this. Molt's link set is one link, so it cannot be split across trees.
molt_path_shadow() {
  local link first
  link="$(molt_switch_link)"
  if [[ ! -e "$link" && ! -L "$link" ]]; then
    local brew_fault
    brew_fault="$(molt_brew_on_path)" || echo "$brew_fault"
    return 0
  fi
  first="$(type -ap molt 2>/dev/null | head -n 1)" || first=""
  if [[ -z "$first" ]]; then
    echo "no molt is on PATH, so $(molt_tilde "$link") does not run; put $(molt_tilde "$MOLT_LOCAL_BIN") on PATH"
  elif ! molt_same_file "$(dirname "$first")" "$MOLT_LOCAL_BIN"; then
    if [[ "$(molt_tree "$(dirname "$(dirname "$(_molt_realpath "$first")")")")" == brew ]]; then
      echo "PATH runs Homebrew's $(molt_tilde "$first") ahead of $(molt_tilde "$link"); put $(molt_tilde "$MOLT_LOCAL_BIN") ahead of Homebrew's bin on PATH, or run bin/devbin use brew in the checkout"
    else
      echo "PATH runs $(molt_tilde "$first") ahead of $(molt_tilde "$link"), so bin/devbin use does not change what runs"
    fi
  fi
}
