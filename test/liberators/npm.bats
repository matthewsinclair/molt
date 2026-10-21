#!/usr/bin/env bats
# npm.bats — the npm liberator renders ~/.npmrc so npm's cache, which npx fills
# at every status-line refresh, is under XDG and not in ~/.npm (issue 0031).

load "../test_helper.bash"

_npm_env() {
    load_liberator npm
    local root="$BATS_TEST_TMPDIR" host
    host="$(test_hostname)"
    export HOME="$root/home"
    mkdir -p "$HOME" "$root/repo/config" "$root/repo/instances/$host" "$root/stub"
    echo 'export MOLT_TEST_VAR=1' > "$root/repo/instances/$host/vars.sh"
    MOLT_USER_REPO_SEARCH_PATHS=("$root/repo")
    unset XDG_CACHE_HOME
    # A stub npm whose `npm config list` gives NPM_STUB_CACHE as the user
    # config's cache, over a project's that an env var overrides.
    cat > "$root/stub/npm" <<'STUB'
#!/bin/sh
[ "$1 $2" = "config list" ] || exit 1
printf '; "project" config from /p/.npmrc\n\n; cache = "/p/cache" ; overridden by env\n\n'
printf '; "user" config from %s/.npmrc\n\ncache = "%s"\n' "$HOME" "$NPM_STUB_CACHE"
STUB
    chmod +x "$root/stub/npm"
    export PATH="$root/stub:$PATH"
    NPM_ROOT="$root"
}

# A directory for PATH with no npm in it: only the commands the liberator runs
# without one.
_npm_absent() {
    local bin="$NPM_ROOT/nonpm" c
    mkdir -p "$bin"
    for c in grep sed awk cat mkdir rm mv chmod date dirname find tr wc ls; do
        ln -sf "$(command -v "$c")" "$bin/$c"
    done
    echo "$bin"
}

_npm_backups() {
    find "$HOME" -maxdepth 1 -name '.npmrc.molt-backup.*' | wc -l | tr -d ' '
}

@test "npm_install renders cache under XDG_CACHE_HOME when it is set and under ~/.cache when it is not, mode 600" {
    _npm_env
    export XDG_CACHE_HOME="$NPM_ROOT/xdg"
    run npm_install
    assert_success
    grep -qx "cache=$NPM_ROOT/xdg/npm" "$HOME/.npmrc"
    [ "$(test_file_mode "$HOME/.npmrc")" = 600 ]

    unset XDG_CACHE_HOME
    run npm_check
    assert_failure
    run npm_install
    assert_success
    grep -qx "cache=$NPM_ROOT/home/.cache/npm" "$HOME/.npmrc"
    [ "$(grep -c '^cache=' "$HOME/.npmrc")" = 1 ]
}

@test "an existing ~/.npmrc keeps its hand line above the marker, with the cache below it, backed up once" {
    _npm_env
    printf 'allow-scripts=@scope/pkg\ncache=/old/cache\n' > "$HOME/.npmrc"
    run npm_install
    assert_success
    [ "$(wc -l < "$HOME/.npmrc" | tr -d ' ')" = 3 ]
    grep -qx 'cache=/old/cache' "$HOME"/.npmrc.molt-backup.*
    [ "$(sed -n 1p "$HOME/.npmrc")" = "allow-scripts=@scope/pkg" ]
    grep -q '@@MOLT:BEGIN@@' <(sed -n 2p "$HOME/.npmrc")
    [ "$(sed -n 3p "$HOME/.npmrc")" = "cache=$NPM_ROOT/home/.cache/npm" ]
    [ "$(_npm_backups)" = 1 ]
}

@test "a ~/.npmrc that is a link has its lines kept above the marker, read through the link" {
    _npm_env
    echo 'allow-scripts=@scope/pkg' > "$NPM_ROOT/linked-npmrc"
    ln -s "$NPM_ROOT/linked-npmrc" "$HOME/.npmrc"
    run npm_install
    assert_success
    [ ! -L "$HOME/.npmrc" ]
    [ "$(sed -n 1p "$HOME/.npmrc")" = "allow-scripts=@scope/pkg" ]
    [ "$(sed -n 3p "$HOME/.npmrc")" = "cache=$NPM_ROOT/home/.cache/npm" ]
}

@test "a second npm_install over molt's own render writes nothing and backs nothing up" {
    _npm_env
    echo 'allow-scripts=@scope/pkg' > "$HOME/.npmrc"
    npm_install >/dev/null
    cp "$HOME/.npmrc" "$NPM_ROOT/before"
    run npm_install
    assert_success
    refute_output_contains "backing up"
    cmp "$NPM_ROOT/before" "$HOME/.npmrc"
    [ "$(_npm_backups)" = 1 ]
}

@test "npm_check fails over a missing or stale ~/.npmrc and passes over a current one, naming ~/.npm as the old cache" {
    _npm_env
    run npm_check
    assert_failure
    npm_install >/dev/null
    run npm_check
    assert_success
    refute_output_contains "old cache"

    sed -i.bak 's/^cache=.*/cache=elsewhere/' "$HOME/.npmrc"
    run npm_check
    assert_failure
    npm_install >/dev/null
    echo 'export MOLT_TEST_VAR=2' > "$NPM_ROOT/repo/instances/$(test_hostname)/vars.sh"
    run npm_check
    assert_failure

    npm_install >/dev/null
    chmod 644 "$HOME/.npmrc"
    run npm_check
    assert_failure
    npm_install >/dev/null
    [ "$(test_file_mode "$HOME/.npmrc")" = 600 ]
    mkdir -p "$HOME/.npm"
    run npm_check
    assert_success
    assert_output_contains "~/.npm is npm's old cache, left for you to remove"
    [ -d "$HOME/.npm" ]
    run npm_install
    [ -d "$HOME/.npm" ]
}

@test "npm_verify passes when npm answers the rendered cache and fails when it answers another" {
    _npm_env
    npm_install >/dev/null
    export NPM_STUB_CACHE="$NPM_ROOT/home/.cache/npm"
    run npm_verify
    assert_success
    export NPM_STUB_CACHE="$NPM_ROOT/home/.npm"
    run npm_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: npm's cache is $NPM_ROOT/home/.npm"
}

@test "with no npm on PATH, check and verify pass, saying so, and install writes no file" {
    _npm_env
    local nonpm; nonpm="$(_npm_absent)"
    PATH="$nonpm" run npm_check
    assert_success
    assert_output_contains "npm is not installed, so there is nothing to configure"
    PATH="$nonpm" run npm_install
    assert_success
    [ ! -e "$HOME/.npmrc" ]
    PATH="$nonpm" run npm_verify
    assert_success
    assert_output_contains "nothing was checked"
}
