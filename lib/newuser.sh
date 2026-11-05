#!/usr/bin/env bash
# newuser.sh — Scaffold a new molt-{user} config repo from the template skeleton,
# or from another template named with --from.
#
# Owns the "create a personal config repo" concern. The skeleton lives in
# templates/molt-user/ and uses __MOLT_*__ placeholders, deliberately distinct
# from the ${...} runtime template vars that resleeve renders via envsubst — so
# scaffolding never clobbers those.
#
# Sourced by bin/molt after lib/molt.sh (uses molt_info / molt_error / MOLT_ROOT).

# Escape a replacement string for safe use on the right-hand side of sed s|||.
# Byte-wise, as _molt_subst_text's sed is, and for the same reason.
_molt_sed_escape() {
  printf '%s' "$1" | LC_ALL=C sed -e 's/[\\&|]/\\&/g'
}

# Substitute every __MOLT_*__ token in the text on stdin, to stdout.
#   $1 user  $2 full_name  $3 email  $4 github  $5 hostname
# The one list of the tokens and the values they take: file contents and path
# names both go through it, so a token added here reaches both (issue 0097).
# sed takes each value escaped, so an & in one stays an &, where bash 5.2's
# patsub_replacement put the token back in its place in a ${name//token/value}.
# sed runs byte-wise, under the C locale: under a UTF-8 one, macOS's sed
# refuses a file that is not UTF-8, such as an image or a font, with "RE error:
# illegal byte sequence", and the scaffold stopped half built. GNU sed passes
# such a file either way (issue 0097).
_molt_subst_text() {
  local e_user e_name e_email e_github e_host
  e_user="$(_molt_sed_escape "$1")"
  e_name="$(_molt_sed_escape "$2")"
  e_email="$(_molt_sed_escape "$3")"
  e_github="$(_molt_sed_escape "$4")"
  e_host="$(_molt_sed_escape "$5")"
  LC_ALL=C sed \
    -e "s|__MOLT_USER__|${e_user}|g" \
    -e "s|__MOLT_FULL_NAME__|${e_name}|g" \
    -e "s|__MOLT_EMAIL__|${e_email}|g" \
    -e "s|__MOLT_GITHUB__|${e_github}|g" \
    -e "s|__MOLT_HOSTNAME__|${e_host}|g"
}

# Substitute every __MOLT_*__ token in the file $1, in place, with the values
# $2 on, in _molt_subst_text's order (portable: no reliance on GNU vs BSD
# `sed -i` differences). The result is written back into the file, never moved
# over it, so the file keeps its mode: a script in a --from template stays
# executable, where a moved file took a new file's mode (issue 0097).
_molt_subst_tokens() {
  local file="$1"
  shift
  local tmp="${file}.molt-subst"
  if _molt_subst_text "$@" < "$file" > "$tmp" && cat "$tmp" > "$file"; then
    rm -f "$tmp"
  else
    rm -f "$tmp"
    molt_error "Token substitution failed: $file"
    return 1
  fi
}

# Copies the template directory $1 to $2, which it makes, entry by entry, with
# no .git at any depth: a template that is a git checkout would otherwise bring
# its objects, and the token substitution would run through them (issue 0097).
_molt_copy_template() {
  local from="$1" to="$2" entry name
  mkdir -p "$to" || return 1
  for entry in "$from"/* "$from"/.[!.]* "$from"/..?*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="${entry##*/}"
    [[ "$name" != .git ]] || continue
    if [[ -d "$entry" && ! -L "$entry" ]]; then
      _molt_copy_template "$entry" "$to/$name" || return 1
    else
      cp -R "$entry" "$to/$name" || return 1
    fi
  done
}

# Scaffold a new config repo. All params resolved by the caller.
#   $1 user  $2 full_name  $3 email  $4 github  $5 hostname  $6 dest
#   $7 the template, Molt's own skeleton when not given (issue 0097)
# Any template goes through the same copy and the same __MOLT_*__ tokens, so
# Molt keeps one scaffolder. One that is not a directory, or holds no config/,
# by which molt_find_user_repo finds a stack, is refused before anything is
# written.
molt_new_user() {
  local user="$1" full_name="$2" email="$3" github="$4" hostname="$5" dest="$6"
  local template="${7-${MOLT_ROOT}/templates/molt-user}"

  if [[ ! -d "$template" ]]; then
    molt_error "new-user: ${template} is not a directory, so there is no template to scaffold from"
    return 1
  fi
  if [[ ! -d "$template/config" ]]; then
    molt_error "new-user: ${template} holds no config/, and molt finds a stack only by its config/"
    return 1
  fi
  if [[ -e "$dest" ]]; then
    molt_error "Destination already exists: $dest (refusing to overwrite)"
    return 1
  fi

  molt_info "Scaffolding Molt-${user} -> ${dest}"

  mkdir -p "$(dirname "$dest")"
  if ! _molt_copy_template "$template" "$dest"; then
    molt_error "Failed to copy the template $template to $dest"
    return 1
  fi

  # Rename path placeholders, deepest first, each entry by its own name alone:
  # its parent is renamed after it, so a token in the parent's name stays in
  # the path until then. Substituting along the whole path moved a tokened
  # entry inside a tokened directory to a parent that did not exist yet, which
  # a template from --from can hold, though the skeleton does not (issue 0097).
  # A name takes its tokens through _molt_subst_text, as the contents do.
  local values=("$user" "$full_name" "$email" "$github" "$hostname")
  local path renamed name
  while IFS= read -r path; do
    if ! name="$(printf '%s\n' "${path##*/}" | _molt_subst_text "${values[@]}")"; then
      molt_error "Token substitution failed in the name of $path"
      return 1
    fi
    renamed="${path%/*}/${name}"
    if [[ "$renamed" != "$path" ]]; then
      if ! mv "$path" "$renamed"; then
        molt_error "Failed to rename $path"
        return 1
      fi
    fi
  done < <(find "$dest" -depth -name '*__MOLT_*__*')

  # Substitute tokens inside every file.
  local file
  while IFS= read -r file; do
    _molt_subst_tokens "$file" "${values[@]}" || return 1
  done < <(find "$dest" -type f)

  molt_info "Created Molt-${user} at ${dest}"
  return 0
}

# Thin coordinator: parse args, prompt for any missing required value, delegate.
cmd_new_user() {
  local user="" full_name="" email="" github="" hostname="" dest=""
  local from="" from_given=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)     full_name="${2:-}"; shift 2 ;;
      --email)    email="${2:-}"; shift 2 ;;
      --github)   github="${2:-}"; shift 2 ;;
      --hostname) hostname="${2:-}"; shift 2 ;;
      --dest)     dest="${2:-}"; shift 2 ;;
      # Given, even empty, it names the template, so an empty one is refused
      # as no directory rather than read as the skeleton (issue 0097).
      --from)     from="${2:-}"; from_given=1; shift 2 ;;
      -*)         molt_error "Unknown flag: $1"; return 1 ;;
      *)
        if [[ -z "$user" ]]; then
          user="$1"; shift
        else
          molt_error "Unexpected argument: $1"; return 1
        fi
        ;;
    esac
  done

  [[ -z "$user" ]]      && read -rp "Short username (eg flynn): " user
  if [[ -z "$user" ]]; then molt_error "username is required"; return 1; fi
  [[ -z "$full_name" ]] && read -rp "Full name [${user}]: " full_name
  full_name="${full_name:-$user}"
  [[ -z "$email" ]]     && read -rp "Email: " email
  if [[ -z "$email" ]]; then molt_error "email is required"; return 1; fi
  [[ -z "$github" ]]    && read -rp "GitHub handle [${user}]: " github
  github="${github:-$user}"
  [[ -z "$hostname" ]]  && read -rp "First machine hostname: " hostname
  if [[ -z "$hostname" ]]; then molt_error "hostname is required"; return 1; fi

  # Directory name is Capitalised (Molt-matts, Molt-flynn), matching every
  # project under MOLT_PRJ_DIR and the order constants.sh searches. The
  # GITHUB repo stays lowercase (matthewsinclair/molt-matts) -- the two
  # conventions differ on purpose, so do not "fix" the remote URL below.
  # It goes in MOLT_CFG_DIR, the first place constants.sh searches.
  if [[ -z "$dest" ]]; then
    local dirname="Molt-${user}"
    if [[ -n "${MOLT_CFG_DIR:-}" ]]; then
      dest="${MOLT_CFG_DIR}/${dirname}"
    else
      dest="$(pwd)/${dirname}"
    fi
  fi

  local args=("$user" "$full_name" "$email" "$github" "$hostname" "$dest")
  if [[ $from_given -eq 1 ]]; then
    args+=("$from")
  fi
  molt_new_user "${args[@]}" || return 1

  # The resleeve comes first: until it runs, git has no name or email for the
  # commit, and ssh no github.com-<github> host for the push (issue 0085). The
  # GitHub lines are the skeleton's: a template from --from names its own git
  # host, if it names one (issue 0097).
  cat <<EOF

Next steps:
  cd "${dest}"
  MOLT_CFG_DIR="$(dirname "$dest")" molt resleeve --dry-run
  MOLT_CFG_DIR="$(dirname "$dest")" molt resleeve
EOF
  if [[ $from_given -eq 0 ]]; then
    cat <<EOF
  # The resleeve links ~/.gitconfig, which gives git your name and email, and
  # renders ~/.ssh/config, whose github.com-${github} host the push uses; with
  # no key in ~/.ssh it makes ~/.ssh/id_ed25519: add its .pub to GitHub.
EOF
  fi
  echo "  git init -b main && git add -A && git commit -m \"Initial molt-${user} config\""
  if [[ $from_given -eq 0 ]]; then
    cat <<EOF
  # create the GitHub repo ${github}/molt-${user}, then:
  git remote add origin git@github.com-${github}:${github}/molt-${user}.git
  git push -u origin main
EOF
  fi
}
