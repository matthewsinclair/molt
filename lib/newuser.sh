#!/usr/bin/env bash
# newuser.sh — Scaffold a new molt-{user} config repo from the template skeleton.
#
# Owns the "create a personal config repo" concern. The skeleton lives in
# templates/molt-user/ and uses __MOLT_*__ placeholders, deliberately distinct
# from the ${...} runtime template vars that resleeve renders via envsubst — so
# scaffolding never clobbers those.
#
# Sourced by bin/molt after lib/molt.sh (uses molt_info / molt_error / MOLT_ROOT).

# Escape a replacement string for safe use on the right-hand side of sed s|||.
_molt_sed_escape() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# Substitute every __MOLT_*__ token in a single file, in place (portable: no
# reliance on GNU vs BSD `sed -i` differences).
_molt_subst_tokens() {
  local file="$1" user="$2" full_name="$3" email="$4" github="$5" hostname="$6"
  local e_user e_name e_email e_github e_host
  e_user="$(_molt_sed_escape "$user")"
  e_name="$(_molt_sed_escape "$full_name")"
  e_email="$(_molt_sed_escape "$email")"
  e_github="$(_molt_sed_escape "$github")"
  e_host="$(_molt_sed_escape "$hostname")"

  local tmp="${file}.molt-subst"
  if sed \
    -e "s|__MOLT_USER__|${e_user}|g" \
    -e "s|__MOLT_FULL_NAME__|${e_name}|g" \
    -e "s|__MOLT_EMAIL__|${e_email}|g" \
    -e "s|__MOLT_GITHUB__|${e_github}|g" \
    -e "s|__MOLT_HOSTNAME__|${e_host}|g" \
    "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    molt_error "Token substitution failed: $file"
    return 1
  fi
}

# Scaffold a new config repo. All params resolved by the caller.
#   $1 user  $2 full_name  $3 email  $4 github  $5 hostname  $6 dest
molt_new_user() {
  local user="$1" full_name="$2" email="$3" github="$4" hostname="$5" dest="$6"
  local skeleton="${MOLT_ROOT}/templates/molt-user"

  if [[ ! -d "$skeleton" ]]; then
    molt_error "Skeleton not found: $skeleton"
    return 1
  fi
  if [[ -e "$dest" ]]; then
    molt_error "Destination already exists: $dest (refusing to overwrite)"
    return 1
  fi

  molt_info "Scaffolding molt-${user} -> ${dest}"

  mkdir -p "$(dirname "$dest")"
  if ! cp -R "$skeleton" "$dest"; then
    molt_error "Failed to copy skeleton to $dest"
    return 1
  fi

  # Rename path placeholders (deepest-first so parent renames don't invalidate
  # child paths). Only entries whose own name carries a token are touched.
  local path renamed
  while IFS= read -r path; do
    renamed="${path//__MOLT_HOSTNAME__/$hostname}"
    renamed="${renamed//__MOLT_GITHUB__/$github}"
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
    _molt_subst_tokens "$file" "$user" "$full_name" "$email" "$github" "$hostname" || return 1
  done < <(find "$dest" -type f)

  molt_info "Created molt-${user} at ${dest}"
  return 0
}

# Thin coordinator: parse args, prompt for any missing required value, delegate.
cmd_new_user() {
  local user="" full_name="" email="" github="" hostname="" dest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)     full_name="${2:-}"; shift 2 ;;
      --email)    email="${2:-}"; shift 2 ;;
      --github)   github="${2:-}"; shift 2 ;;
      --hostname) hostname="${2:-}"; shift 2 ;;
      --dest)     dest="${2:-}"; shift 2 ;;
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

  if [[ -z "$dest" ]]; then
    if [[ -n "${MOLT_PRJ_DIR:-}" ]]; then
      dest="${MOLT_PRJ_DIR}/molt-${user}"
    else
      dest="$(pwd)/molt-${user}"
    fi
  fi

  molt_new_user "$user" "$full_name" "$email" "$github" "$hostname" "$dest" || return 1

  cat <<EOF

Next steps:
  cd "${dest}"
  git init && git add -A && git commit -m "Initial molt-${user} config"
  # create the GitHub repo ${github}/molt-${user}, then:
  git remote add origin git@github.com-${github}:${github}/molt-${user}.git
  git push -u origin main
  MOLT_PRJ_DIR="$(dirname "$dest")" molt resleeve --dry-run
EOF
}
