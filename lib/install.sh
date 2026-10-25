#!/usr/bin/env bash
# install.sh — The trees Molt runs from, and the publish that makes one (ST0008).
#
# A tree is a directory holding bin/molt, lib/, liberators/, templates/ and
# VERSION. dev is the git checkout; opt is an install `molt install` published
# from a clean dev tree to a prefix the sleeve declares; brew is the same
# publish, run by the formula in its keg. bin/molt finds MOLT_ROOT from its own
# resolved path in every tree, so nothing here reads MOLT_ROOT from the
# environment. Sourced by bin/molt after lib/molt.sh, whose helpers it uses.

# The manifest a publish writes at the root of the tree it makes, in the form
# devbin's docs/dev-opt-brew.md T3 fixes for every tool: header lines of
# `# key: value` (tool, version, source_commit, managed_by), then one line per
# file in the form `shasum -a 256 -c` reads, sorted by LC_ALL=C sort, so a
# tree can be checked by hand from inside it.
MOLT_INSTALL_MANIFEST=".molt-install"

# The formula, by its tap-qualified name, that the brew tree is the keg of.
MOLT_BREW_FORMULA="matthewsinclair/molt/molt"

# The runtime set's pathspecs, one per line. What git names under these is the
# runtime set and nothing else: no test/, intent/, docs/ or board.
_molt_runtime_pathspecs() {
  printf '%s\n' bin/molt lib liberators templates VERSION
}

# The runtime set of the dev tree $1, one path per line relative to it, as git
# names it. The one list of what a publish carries: molt install copies it and
# the manifest it writes, which the doctor checks, records it.
molt_runtime_set() {
  local root="$1" specs=()
  while IFS= read -r spec; do specs+=("$spec"); done < <(_molt_runtime_pathspecs)
  git -C "$root" ls-files -- "${specs[@]}"
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

# The managed_by line of the old-form manifest in the tree $1, or nothing. Its
# one reader is the guard that lets molt install --force replace an old-form
# opt install, the remedy T3 names (vc, 24 Oct).
_molt_install_old_managed_by() {
  awk '$1 == "managed_by:" { print $2; exit }' "$1/$MOLT_INSTALL_MANIFEST" 2>/dev/null
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
        echo "$manifest is an old manifest, from before the dev/opt/brew contract; republish with molt install --force"
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
# version, molt --version, the doctor and molt use print it.
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

# Writes the manifest for the files of the runtime set $3 (one per line), as
# copied to the tree $1 from the dev tree $2, with managed_by $4.
_molt_install_write_manifest() {
  local dest="$1" src="$2" files="$3" managed_by="$4" commit version path sum body
  commit="$(git -C "$src" rev-parse HEAD)" || return 1
  version="$(cat "$src/VERSION")" || return 1
  body="$(LC_ALL=C sort <<< "$files")" || return 1
  {
    echo "# tool: molt"
    echo "# version: $version"
    echo "# source_commit: $commit"
    echo "# managed_by: $managed_by"
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      sum="$(molt_hash < "$dest/$path")" || return 1
      printf '%s  %s\n' "$sum" "$path"
    done <<< "$body"
  } > "$dest/$MOLT_INSTALL_MANIFEST"
}

# Copies the runtime set $3 (one path per line) from the dev tree $1 into the
# empty directory $2, keeping each file's mode.
_molt_install_copy() {
  local src="$1" dest="$2" files="$3" path
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    mkdir -p "$dest/$(dirname "$path")" || return 1
    cp -p "$src/$path" "$dest/$path" || return 1
  done <<< "$files"
}

# The opt tree's prefix, MOLT_INSTALL_PREFIX as this sleeve's vars.sh declares
# it, without a trailing slash; nothing when it declares none or there is no
# user repo. Fails, printing why instead, when vars.sh cannot be read.
molt_install_prefix() {
  local prefix status=0
  prefix="$(molt_instance_var MOLT_INSTALL_PREFIX)" || status=$?
  case "$status" in
    0) echo "${prefix%/}" ;;
    3) ;;
    *) echo "MOLT_INSTALL_PREFIX could not be read: $prefix"; return 1 ;;
  esac
}

# The names of the first few entries in the directory $1, one per line, dot
# files included; nothing when it is empty.
_molt_dir_entries() {
  find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | awk 'NR <= 5 { sub(/.*\//, ""); print }'
}

# Names why the prefix $1 cannot take a publish managed by $2 (molt or brew)
# with force $3, and prints nothing when it can. A missing or empty directory is
# fresh; one whose manifest says Molt manages it is replaced only with --force,
# and one Homebrew manages only by Homebrew; anything else is refused, --force
# or not, since a replace removes what was there.
_molt_install_prefix_fault() {
  local prefix="$1" managed_by="$2" force="$3" held
  if [[ -e "$prefix" && ! -d "$prefix" ]]; then
    echo "$(molt_tilde "$prefix") is not a directory"
    return 0
  fi
  [[ -d "$prefix" ]] || return 0
  if [[ -f "$prefix/$MOLT_INSTALL_MANIFEST" ]]; then
    local tool=molt
    case "$(molt_install_form "$prefix")" in
      current)
        held="$(molt_install_field "$prefix" managed_by)"
        tool="$(molt_install_field "$prefix" tool)" ;;
      *) held="$(_molt_install_old_managed_by "$prefix")" ;;
    esac
    if [[ "$tool" != molt ]]; then
      echo "$(molt_tilde "$prefix/$MOLT_INSTALL_MANIFEST") says tool: ${tool:-nothing}, not molt, so $(molt_tilde "$prefix") is left as it is"
      return 0
    fi
    case "$held" in
      molt|brew)
        if [[ "$held" == brew && "$managed_by" != brew ]] || _molt_in_keg "$prefix"; then
          echo "$(molt_tilde "$prefix") is Homebrew's install of molt; upgrade it with brew upgrade $MOLT_BREW_FORMULA"
        elif ! $force; then
          echo "$(molt_tilde "$prefix") already holds an install of molt; pass --force to replace it"
        fi ;;
      "") echo "$(molt_tilde "$prefix/$MOLT_INSTALL_MANIFEST") names no managed_by, so $(molt_tilde "$prefix") is no install Molt can replace, and it is left as it is" ;;
      *) echo "$(molt_tilde "$prefix/$MOLT_INSTALL_MANIFEST") says managed_by: $held, which is neither molt nor brew, so $(molt_tilde "$prefix") is left as it is" ;;
    esac
    return 0
  fi
  held="$(_molt_dir_entries "$prefix" | tr "\n" " ")"
  [[ -z "$held" ]] || echo "$(molt_tilde "$prefix") holds files Molt did not write (${held% }), so it is left as it is"
}

# molt install [--prefix <dir>] [--force] [--managed-by molt|brew]: publishes
# the runtime set of this dev tree, and a manifest, to the prefix. Refused from
# opt or brew, from a dirty runtime set, with no prefix, and over a prefix Molt
# did not write.
cmd_install() {
  local prefix="" force=false managed_by=molt
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix)
        [[ $# -ge 2 && -n "$2" ]] || { molt_error "--prefix needs a directory"; return 1; }
        prefix="$2"; shift 2 ;;
      --force) force=true; shift ;;
      --managed-by)
        case "${2:-}" in
          molt|brew) managed_by="$2"; shift 2 ;;
          *) molt_error "--managed-by takes molt or brew"; return 1 ;;
        esac ;;
      *) molt_error "Unknown option: $1"; return 1 ;;
    esac
  done

  local tree
  tree="$(molt_tree "$MOLT_ROOT")"
  case "$tree" in
    dev) ;;
    brew)
      molt_error "molt install runs in a dev tree, and this is Homebrew's install at $(molt_tilde "$MOLT_ROOT"); upgrade it with brew upgrade $MOLT_BREW_FORMULA"
      return 1 ;;
    *)
      molt_error "molt install runs in a dev tree, and this is the $tree tree at $(molt_tilde "$MOLT_ROOT"); run it from the checkout"
      return 1 ;;
  esac

  if [[ -z "$prefix" ]] && ! prefix="$(molt_install_prefix)"; then
    molt_error "molt install: $prefix"
    return 1
  fi
  if [[ -z "$prefix" ]]; then
    molt_error "molt install needs a prefix: pass --prefix <dir>, or set MOLT_INSTALL_PREFIX in this sleeve's vars.sh"
    return 1
  fi
  if [[ "$prefix" != /* ]]; then
    molt_error "molt install: the prefix must be an absolute path, not $prefix"
    return 1
  fi
  if [[ "$prefix" =~ ^/+$ ]]; then
    molt_error "molt install: the prefix cannot be /"
    return 1
  fi
  prefix="${prefix%/}"
  # Compared where each lands on disk, so a prefix reached through a symlink
  # into the dev tree is caught as well as one spelled inside it.
  local landed_prefix landed_root
  if ! landed_prefix="$(molt_disk_path -P "$prefix")" || ! landed_root="$(molt_disk_path -P "$MOLT_ROOT")"; then
    molt_error "molt install: where $(molt_tilde "$prefix") lands on disk could not be read"
    return 1
  fi
  case "${landed_prefix%/}/" in
    "${landed_root%/}"/*)
      molt_error "molt install: the prefix $(molt_tilde "$prefix") is inside the dev tree it would publish"
      return 1 ;;
  esac

  local changes dirty_status=0
  changes="$(molt_runtime_set_dirty "$MOLT_ROOT")" || dirty_status=$?
  case "$dirty_status" in
    0)
      molt_error "molt install publishes only a clean runtime set, and $(molt_tilde "$MOLT_ROOT") has changes:"
      printf '%s\n' "$changes" | sed 's/^/    /' >&2
      return 1 ;;
    1) ;;
    *) molt_error "molt install: $changes"; return 1 ;;
  esac

  local fault
  fault="$(_molt_install_prefix_fault "$prefix" "$managed_by" "$force")"
  if [[ -n "$fault" ]]; then
    molt_error "molt install: $fault"
    return 1
  fi

  local files
  if ! files="$(molt_runtime_set "$MOLT_ROOT")" || [[ -z "$files" ]]; then
    molt_error "molt install: git names no runtime set in $(molt_tilde "$MOLT_ROOT")"
    return 1
  fi

  # Staged beside the prefix, so the rename into place stays on one filesystem.
  local parent stage old=""
  parent="$(dirname "$prefix")"
  if ! mkdir -p "$parent"; then
    molt_error "molt install: $(molt_tilde "$parent") could not be made"
    return 1
  fi
  if ! stage="$(mktemp -d "$parent/.molt-install.XXXXXX")"; then
    molt_error "molt install: no staging directory could be made in $(molt_tilde "$parent")"
    return 1
  fi
  # mktemp -d makes the stage 0700, and it becomes the prefix as it is.
  if ! chmod 755 "$stage" \
      || ! _molt_install_copy "$MOLT_ROOT" "$stage" "$files" \
      || ! _molt_install_write_manifest "$stage" "$MOLT_ROOT" "$files" "$managed_by"; then
    rm -rf "$stage"
    molt_error "molt install: the runtime set could not be copied to $(molt_tilde "$stage"); $(molt_tilde "$prefix") is unchanged"
    return 1
  fi

  # The old install is moved aside, and removed only once the new one is in.
  if [[ -d "$prefix" ]]; then
    if [[ -z "$(_molt_dir_entries "$prefix")" ]]; then
      rmdir "$prefix" || { rm -rf "$stage"; molt_error "molt install: $(molt_tilde "$prefix") could not be replaced"; return 1; }
    else
      old="$stage.old"
      if ! mv "$prefix" "$old"; then
        rm -rf "$stage"
        molt_error "molt install: $(molt_tilde "$prefix") could not be moved aside, so it is unchanged"
        return 1
      fi
    fi
  fi
  if ! mv "$stage" "$prefix"; then
    rm -rf "$stage"
    if [[ -n "$old" ]] && ! mv "$old" "$prefix"; then
      molt_error "molt install: the new install could not be moved to $(molt_tilde "$prefix"), nor the old one back; it is at $(molt_tilde "$old")"
      return 1
    fi
    molt_error "molt install: the new install could not be moved to $(molt_tilde "$prefix")${old:+; the old one is back in place}"
    return 1
  fi
  [[ -z "$old" ]] || rm -rf "$old"

  molt_info "Installed: $(molt_version_line "$prefix")"
}

# --- molt use ---

# The per-user link molt use sets, the whole of Molt's link set (T5): one
# link, named here once. Every reader of the switch asks this.
molt_switch_link() {
  echo "$MOLT_LOCAL_BIN/molt"
}

# The root this sleeve declares for the tree $1 (dev, opt or brew), whether or
# not anything is there: the checkout under MOLT_PRJ_DIR, the prefix in
# vars.sh, or the formula's opt link. Fails, printing why instead, when the
# sleeve declares none.
_molt_use_root() {
  local root
  case "$1" in
    dev)
      if [[ -z "${MOLT_PRJ_DIR:-}" ]]; then
        echo "MOLT_PRJ_DIR is not set, so this sleeve has no dev tree"
        return 1
      fi
      echo "$MOLT_PRJ_DIR/Molt" ;;
    opt)
      root="$(molt_install_prefix)" || { echo "$root"; return 1; }
      if [[ -z "$root" ]]; then
        echo "this sleeve's vars.sh sets no MOLT_INSTALL_PREFIX, so it has no opt tree"
        return 1
      fi
      echo "$root" ;;
    brew)
      if ! root="$(HOMEBREW_NO_AUTO_UPDATE=1 brew --prefix 2>/dev/null)" || [[ -z "$root" ]]; then
        echo "brew is not on PATH, so this sleeve has no brew tree"
        return 1
      fi
      echo "$root/opt/molt/libexec" ;;
  esac
}

# The step that makes the tree $1 (dev, opt or brew) at $2.
_molt_use_make_step() {
  case "$1" in
    dev) echo "clone it with git clone https://github.com/matthewsinclair/molt.git $(molt_tilde "$2")" ;;
    opt) echo "publish it with molt install from the dev tree" ;;
    brew) echo "install it with brew install $MOLT_BREW_FORMULA" ;;
  esac
}

# The root of the tree the switch link serves. Fails, printing why instead,
# when there is no link, it is broken, or it leads to a bin/molt that is no
# dev, opt or brew tree's. molt use and the local-bin liberator ask this.
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
    echo "there is no $(molt_tilde "$(molt_switch_link)") and no molt on PATH; install it with brew install $MOLT_BREW_FORMULA, or run molt use dev or opt"
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

# molt use [dev|opt|brew]: with no argument, reports the tree that serves molt
# and changes nothing; with dev or opt, points the switch link at that tree's
# bin/molt, refusing a tree that is not there; with brew, removes the link, so
# Homebrew's own bin/molt answers. No link means brew (T5). Each switch prints
# the new version line. The link is the only record of the choice.
#
# It runs from any tree, brew included, unlike utilz use, which refuses inside
# its install: it writes only the link, never into a tree, so it is how a
# sleeve whose everyday molt is brew gets back to dev.
cmd_use() {
  local want="${1:-}" root tree link
  link="$(molt_switch_link)"
  if [[ $# -gt 1 ]]; then
    molt_error "molt use takes one of dev, opt or brew"
    return 1
  fi
  case "$want" in
    "")
      if [[ -e "$link" || -L "$link" ]]; then
        if ! root="$(molt_served_tree)"; then
          molt_error "molt use: $root"
          return 1
        fi
        echo "$(molt_tilde "$link") serves $(molt_version_line "$root")"
      else
        if ! root="$(molt_brew_on_path)"; then
          molt_error "molt use: $root"
          return 1
        fi
        echo "There is no $(molt_tilde "$link"), so brew serves $(molt_version_line "$root")"
      fi
      _molt_use_shadow_fault
      return ;;
    dev|opt|brew) ;;
    *) molt_error "molt use takes dev, opt or brew, not $want"; return 1 ;;
  esac

  if ! root="$(_molt_use_root "$want")"; then
    molt_error "molt use $want: $root"
    return 1
  fi
  if [[ ! -x "$root/bin/molt" ]]; then
    molt_error "molt use $want: there is no $want tree at $(molt_tilde "$root"); $(_molt_use_make_step "$want" "$root")"
    return 1
  fi
  tree="$(molt_tree "$root")"
  if [[ "$tree" != "$want" ]]; then
    molt_error "molt use $want: $(molt_tilde "$root") is the $tree tree, not the $want tree"
    return 1
  fi
  if [[ "$want" == brew ]]; then
    _molt_use_remove_link || return 1
  else
    molt_link "$root/bin/molt" "$link" || return 1
  fi
  molt_version_line "$root"
  _molt_use_shadow_fault
}

# Removes the switch link for molt use brew when it is a link into one of
# Molt's trees, or a broken link to a bin/molt, and nothing else: a file, or a
# link to anything else, is refused by name and left as it is (T5).
_molt_use_remove_link() {
  local link fault
  link="$(molt_switch_link)"
  [[ -e "$link" || -L "$link" ]] || return 0
  if ! fault="$(molt_served_tree)"; then
    if [[ ! -L "$link" || -e "$link" || "$(readlink "$link")" != */bin/molt ]]; then
      molt_error "molt use brew: $fault; it is left as it is, so move it aside, then run molt use brew again"
      return 1
    fi
  fi
  rm "$link" || { molt_error "molt use brew: $(molt_tilde "$link") could not be removed"; return 1; }
  molt_info "Removed $(molt_tilde "$link"), so brew serves molt"
}

# Fails, saying what shadows it, when the switch molt use reports or has just
# set is not what PATH runs for molt.
_molt_use_shadow_fault() {
  local shadow
  shadow="$(molt_path_shadow)"
  [[ -z "$shadow" ]] || { molt_error "molt use: $shadow"; return 1; }
}

# Refuses, naming the dev tree to run it in, the verb $1 anywhere but a dev
# tree: molt test and its lint have no test/ to run in opt or brew.
molt_require_dev_tree() {
  local tree dev
  tree="$(molt_tree)"
  [[ "$tree" != dev ]] || return 0
  if dev="$(_molt_use_root dev)"; then
    molt_error "$1 runs in a dev tree, and this is the $tree tree at $(molt_tilde "$MOLT_ROOT"); run it in $(molt_tilde "$dev")"
  else
    molt_error "$1 runs in a dev tree, and this is the $tree tree at $(molt_tilde "$MOLT_ROOT"); $dev"
  fi
  return 1
}

# Names what runs for molt instead of the switch, and prints nothing when the
# switch answers (T5). With a link, it must be the first molt on PATH: any other
# molt ahead of it, a brew link included, takes molt use's choice away (on
# rhadamanth a ~/.local/bin/molt from March once ran instead). With no link,
# brew serves molt, so the first molt on PATH must resolve into the brew tree.
# Directories are compared where they resolve, never as strings, since
# rhadamanth's ~/bin is a link to ~/.local/bin. molt use and the doctor ask
# this. Molt's link set is one link, so it cannot be split across trees.
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
      echo "PATH runs Homebrew's $(molt_tilde "$first") ahead of $(molt_tilde "$link"); put $(molt_tilde "$MOLT_LOCAL_BIN") ahead of Homebrew's bin on PATH, or run molt use brew"
    else
      echo "PATH runs $(molt_tilde "$first") ahead of $(molt_tilde "$link"), so molt use does not change what runs"
    fi
  fi
}
