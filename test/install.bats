#!/usr/bin/env bats
# install.bats — the dev, opt and brew trees, and molt install (ST0008)

load "test_helper.bash"

# A dev tree in the test directory: the runtime files of this checkout's
# working tree, new and changed ones included, committed to a fresh repo, so
# the code under test is what is on disk and not what HEAD holds. DEV names it.
make_dev_tree() {
    DEV="$BATS_TEST_TMPDIR/prj/Molt"
    mkdir -p "$DEV"
    (cd "$MOLT_ROOT" && git ls-files --cached --others --exclude-standard \
        -- bin/molt lib liberators templates VERSION) > "$BATS_TEST_TMPDIR/runtime.list"
    local f
    while IFS= read -r f; do
        [[ -f "$MOLT_ROOT/$f" ]] || continue
        mkdir -p "$DEV/$(dirname "$f")"
        cp -p "$MOLT_ROOT/$f" "$DEV/$f"
    done < "$BATS_TEST_TMPDIR/runtime.list"
    # Beside the runtime set, so a publish has something to leave behind.
    mkdir -p "$DEV/test" && echo "# not published" > "$DEV/test/x.bats"
    git -C "$DEV" init -q
    git -C "$DEV" add -A
    git -C "$DEV" -c user.name=t -c user.email=t@t commit -qm dev
}

# A brew first on PATH whose --prefix is $BATS_TEST_TMPDIR/brew, and KEG the
# formula's libexec under it, where molt use brew looks. Homebrew's bin, with
# the formula's link into the keg, comes after ~/.local/bin, as "your links
# first" has it, so no ~/.local/bin/molt means brew's molt runs.
install_fake_brew() {
    mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/brew/bin"
    printf '#!/usr/bin/env bash\n[ "$1" = --prefix ] && echo "%s"\n' "$BATS_TEST_TMPDIR/brew" > "$BATS_TEST_TMPDIR/bin/brew"
    chmod +x "$BATS_TEST_TMPDIR/bin/brew"
    ln -s ../opt/molt/libexec/bin/molt "$BATS_TEST_TMPDIR/brew/bin/molt"
    export PATH="$BATS_TEST_TMPDIR/bin:$HOME/.local/bin:$BATS_TEST_TMPDIR/brew/bin:$PATH"
    KEG="$BATS_TEST_TMPDIR/brew/opt/molt/libexec"
}

# A sleeve with no user repo, so nothing declares MOLT_INSTALL_PREFIX.
no_user_repo() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    unset MOLT_PRJ_DIR MOLT_CFG_DIR MOLT_INSTALL_PREFIX MOLT_LOCAL_BIN
}

# A user repo whose instance vars.sh exports MOLT_INSTALL_PREFIX=$1.
user_repo_declaring_prefix() {
    no_user_repo
    export MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg"
    local repo="$MOLT_CFG_DIR/Molt-$(whoami)"
    create_test_repo "$repo"
    mkdir -p "$repo/instances/$(test_hostname)"
    echo "export MOLT_INSTALL_PREFIX=\"$1\"" > "$repo/instances/$(test_hostname)/vars.sh"
}

setup() {
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"
    no_user_repo
    # ~/.local/bin first, as a sleeve's PATH has it, ahead of the checkout's bin/
    # that test_helper puts there, so the switch molt use sets is what runs.
    export PATH="$HOME/.local/bin:$PATH"
    make_dev_tree
    OPT="$BATS_TEST_TMPDIR/opt/molt"
}

# --- molt install ---

# ST0008 AT001
@test "install publishes the runtime set git names and a manifest that checks" {
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_success
    [[ "${lines[${#lines[@]}-1]}" == "Zen: Installed: molt $(cat "$DEV/VERSION") (opt, $(git -C "$DEV" rev-parse --short=12 HEAD))" ]]

    (cd "$DEV" && git ls-files -- bin/molt lib liberators templates VERSION | sort) > "$BATS_TEST_TMPDIR/want"
    (cd "$OPT" && find . -type f ! -name .molt-install | sed 's,^\./,,' | sort) > "$BATS_TEST_TMPDIR/got"
    run diff "$BATS_TEST_TMPDIR/want" "$BATS_TEST_TMPDIR/got"
    assert_success
    [[ ! -e "$OPT/test" ]]
    [[ -x "$OPT/bin/molt" ]]

    grep -qx "# source_commit: $(git -C "$DEV" rev-parse HEAD)" "$OPT/.molt-install"
    grep -qx "# version: $(cat "$DEV/VERSION")" "$OPT/.molt-install"
    grep -qx "# managed_by: molt" "$OPT/.molt-install"
    grep -qx "# tool: molt" "$OPT/.molt-install"
    grep -v '^# ' "$OPT/.molt-install" | sed 's/^[0-9a-f]*  //' > "$BATS_TEST_TMPDIR/body"
    (cd "$DEV" && git ls-files -- bin/molt lib liberators templates VERSION | LC_ALL=C sort) > "$BATS_TEST_TMPDIR/want-sorted"
    run diff "$BATS_TEST_TMPDIR/want-sorted" "$BATS_TEST_TMPDIR/body"
    assert_success
    cd "$OPT"
    run bash -c "grep -E '^[0-9a-f]{64}  ' .molt-install | shasum -a 256 -c --quiet"
    assert_success
}

@test "install takes the prefix from this sleeve's vars.sh" {
    user_repo_declaring_prefix "$OPT"
    run "$DEV/bin/molt" install
    assert_success
    [[ -f "$OPT/.molt-install" ]]
}

# ST0008 AT001
@test "install with no prefix is refused by name, writing nothing" {
    run "$DEV/bin/molt" install
    assert_failure
    assert_output_contains "MOLT_INSTALL_PREFIX"
    [[ ! -e "$BATS_TEST_TMPDIR/opt" ]]
}

# ST0008 AT001
@test "install from a changed, staged or untracked runtime file is refused" {
    echo "# changed" >> "$DEV/lib/molt.sh"
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_failure
    assert_output_contains "lib/molt.sh"
    git -C "$DEV" add lib/molt.sh
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    git -C "$DEV" reset -q --hard
    touch "$DEV/liberators/stray.sh"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "liberators/stray.sh"
    [[ ! -e "$OPT" ]]
}

@test "a change outside the runtime set does not block a publish" {
    echo "# board view" >> "$DEV/test/x.bats"
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_success
}

# ST0008 AT001
@test "install is refused from an opt tree and from a brew tree" {
    "$DEV/bin/molt" install --prefix "$OPT"
    run "$OPT/bin/molt" install --prefix "$BATS_TEST_TMPDIR/again"
    assert_failure
    assert_output_contains "dev tree"
    "$DEV/bin/molt" install --prefix "$BATS_TEST_TMPDIR/keg" --managed-by brew
    run "$BATS_TEST_TMPDIR/keg/bin/molt" install --prefix "$BATS_TEST_TMPDIR/again"
    assert_failure
    assert_output_contains "brew upgrade"
    [[ ! -e "$BATS_TEST_TMPDIR/again" ]]
}

@test "an existing install is replaced only with --force, leaving no staging behind" {
    "$DEV/bin/molt" install --prefix "$OPT"
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_failure
    assert_output_contains "--force"
    echo "# next" >> "$DEV/lib/molt.sh"
    git -C "$DEV" -c user.name=t -c user.email=t@t commit -qam next
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_success
    grep -qx "# source_commit: $(git -C "$DEV" rev-parse HEAD)" "$OPT/.molt-install"
    cmp -s "$DEV/lib/molt.sh" "$OPT/lib/molt.sh"
    run bash -c "ls -A '$(dirname "$OPT")'"
    [[ "$output" == "molt" ]]
    run ls -ld "$OPT"
    [[ "$output" == drwxr-xr-x* ]]
}

@test "a prefix holding files Molt did not write is refused, --force or not" {
    mkdir -p "$OPT" && echo "mine" > "$OPT/notes.txt"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "notes.txt"
    [[ "$(cat "$OPT/notes.txt")" == "mine" ]]
}

@test "--force is refused over a manifest that names no Molt or Homebrew install" {
    mkdir -p "$OPT" && echo "mine" > "$OPT/notes.txt"
    echo "source_commit: abc" > "$OPT/.molt-install"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "names no managed_by"
    echo "managed_by: someone" >> "$OPT/.molt-install"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "says managed_by: someone"
    [[ "$(cat "$OPT/notes.txt")" == "mine" ]]
}

@test "the prefix / and a prefix that lands inside the dev tree are refused" {
    run "$DEV/bin/molt" install --prefix /
    assert_failure
    assert_output_contains "cannot be /"
    ln -s "$DEV/lib" "$BATS_TEST_TMPDIR/into-dev"
    run "$DEV/bin/molt" install --prefix "$BATS_TEST_TMPDIR/into-dev/opt"
    assert_failure
    assert_output_contains "inside the dev tree"
    [[ ! -e "$DEV/lib/opt" ]]
}

@test "an empty prefix directory takes a publish" {
    mkdir -p "$OPT"
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_success
}

@test "a publish over Homebrew's install is refused, --force or not" {
    "$DEV/bin/molt" install --prefix "$OPT" --managed-by brew
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "brew upgrade"
    grep -qx "# managed_by: brew" "$OPT/.molt-install"
}

# --- Tree identity ---

# ST0008 AT002
@test "molt_tree names dev, opt, brew and unknown" {
    "$DEV/bin/molt" install --prefix "$OPT"
    "$DEV/bin/molt" install --prefix "$BATS_TEST_TMPDIR/keg" --managed-by brew
    mkdir -p "$BATS_TEST_TMPDIR/bare"
    load_molt_libs
    source "$MOLT_LIB_DIR/install.sh"
    [[ "$(molt_tree "$DEV")" == dev ]]
    [[ "$(molt_tree "$OPT")" == opt ]]
    [[ "$(molt_tree "$BATS_TEST_TMPDIR/keg")" == brew ]]
    [[ "$(molt_tree "$BATS_TEST_TMPDIR/bare")" == unknown ]]
}

# ST0008 AT002
@test "the version line names the tree and its commit, +dirty for a changed dev tree" {
    "$DEV/bin/molt" install --prefix "$OPT"
    load_molt_libs
    source "$MOLT_LIB_DIR/install.sh"
    local short version
    short="$(git -C "$DEV" rev-parse --short=12 HEAD)"
    version="$(cat "$DEV/VERSION")"
    [[ "$(molt_version_line "$OPT")" == "molt $version (opt, $short)" ]]
    [[ "$(molt_version_line "$DEV")" == "molt $version (dev, $short)" ]]
    touch "$DEV/lib/stray.sh"
    [[ "$(molt_version_line "$DEV")" == "molt $version (dev, ${short}+dirty)" ]]
}

# Issue 0063 (contract A3): the line names no path, and Molt, a script tool,
# appends no provenance word, so every place that prints it ends there.
@test "the version line ends at its closing parenthesis wherever molt prints it" {
    install_fake_brew
    install_brew_keg 0.3.0
    "$DEV/bin/molt" install --prefix "$OPT"
    local root out
    for root in "$DEV" "$OPT" "$KEG"; do
        out="$("$root/bin/molt" version)"
        [[ "$out" == "molt "*")" && "$out" != *") "* ]] || fail "$root: $out"
        out="$("$root/bin/molt" --version)"
        [[ "$out" == "molt "*")" && "$out" != *") "* ]] || fail "$root --version: $out"
        out="$("$root/bin/molt" doctor 2>&1 | sed -n 2p)" || true
        [[ "$out" == "molt "*")" ]] || fail "$root doctor: $out"
    done
}

@test "a dev tree git cannot read shows unknown for its commit, and doctor fails saying why" {
    echo junk > "$DEV/.git/index"
    run "$DEV/bin/molt" version
    [[ "$output" == "molt $(cat "$DEV/VERSION") (dev, unknown)" ]]
    run "$DEV/bin/molt" doctor
    assert_output_contains "Checking tree... ✗ dev, its commit cannot be read: git status failed in $DEV"
}

@test "a brew tree's line names brew and its commit, and neither its opt link nor its keg" {
    install_fake_brew
    install_brew_keg 0.3.0
    run "$KEG/bin/molt" version
    assert_success
    [[ "$output" == "molt $(cat "$DEV/VERSION") (brew, $(git -C "$DEV" rev-parse --short=12 HEAD))" ]]
}

@test "an old-form opt manifest is unknown, fails doctor naming install --force, which replaces it" {
    "$DEV/bin/molt" install --prefix "$OPT"
    # The manifest form before the contract: bare headers and no tool.
    sed -e '/^# tool:/d' -e 's/^# //' "$OPT/.molt-install" > "$BATS_TEST_TMPDIR/old" && mv "$BATS_TEST_TMPDIR/old" "$OPT/.molt-install"
    run "$OPT/bin/molt" version
    assert_output_contains "(unknown, unknown)"
    run "$OPT/bin/molt" doctor
    assert_output_contains "Checking tree... ✗ $OPT/.molt-install is an old manifest, from before the dev/opt/brew contract; republish with molt install --force"
    run "$DEV/bin/molt" install --prefix "$OPT"
    assert_failure
    assert_output_contains "--force"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_success
    grep -qx "# tool: molt" "$OPT/.molt-install"
}

@test "an old-form or manifest-less brew keg is still brew, and doctor only notes it" {
    install_fake_brew
    install_brew_keg 0.3.0
    sed -e '/^# tool:/d' -e 's/^# //' "$KEG/.molt-install" > "$BATS_TEST_TMPDIR/old" && mv "$BATS_TEST_TMPDIR/old" "$KEG/.molt-install"
    run "$KEG/bin/molt" version
    [[ "$output" == "molt $(cat "$DEV/VERSION") (brew, unknown)" ]]
    run "$KEG/bin/molt" doctor
    assert_output_contains "Checking tree... ✓ brew; note: "
    assert_output_contains "is an old manifest, from before the dev/opt/brew contract; brew upgrade matthewsinclair/molt/molt writes a current one"
    rm "$KEG/.molt-install"
    run "$KEG/bin/molt" version
    assert_output_contains "(brew, unknown)"
    run "$KEG/bin/molt" doctor
    assert_output_contains "is Homebrew's keg with no manifest; brew upgrade matthewsinclair/molt/molt writes one"
}

@test "--force is refused over a current manifest whose tool is not molt" {
    mkdir -p "$OPT" && echo "mine" > "$OPT/notes.txt"
    printf '# tool: other\n# managed_by: molt\n' > "$OPT/.molt-install"
    run "$DEV/bin/molt" install --prefix "$OPT" --force
    assert_failure
    assert_output_contains "says tool: other, not molt"
    [[ "$(cat "$OPT/notes.txt")" == "mine" ]]
}

@test "molt_install_drift names a changed, a missing and an unlisted file" {
    "$DEV/bin/molt" install --prefix "$OPT"
    load_molt_libs
    source "$MOLT_LIB_DIR/install.sh"
    run molt_install_drift "$OPT"
    assert_success
    [[ -z "$output" ]]
    echo "# drift" >> "$OPT/lib/molt.sh"
    rm "$OPT/liberators/git.sh"
    touch "$OPT/liberators/extra.sh" "$OPT/bin/extra"
    run molt_install_drift "$OPT"
    assert_output_contains "lib/molt.sh has changed"
    assert_output_contains "liberators/git.sh is missing"
    assert_output_contains "liberators/extra.sh is not in the manifest"
    assert_output_contains "bin/extra is not in the manifest"
}

# --- molt use ---

# ST0008 AT004
@test "use dev points ~/.local/bin/molt at the checkout under MOLT_PRJ_DIR and prints its version line" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    run "$DEV/bin/molt" use dev
    assert_success
    assert_output_contains "(dev, "
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$DEV/bin/molt" ]]
}

# ST0008 AT004
@test "use dev with no MOLT_PRJ_DIR is refused by name" {
    run "$DEV/bin/molt" use dev
    assert_failure
    assert_output_contains "MOLT_PRJ_DIR is not set"
    [[ ! -e "$HOME/.local/bin/molt" && ! -L "$HOME/.local/bin/molt" ]]
}

# ST0008 AT004
@test "use opt refuses a prefix with no install, naming molt install, then links one" {
    user_repo_declaring_prefix "$OPT"
    run "$DEV/bin/molt" use opt
    assert_failure
    assert_output_contains "molt install"
    [[ ! -L "$HOME/.local/bin/molt" ]]
    "$DEV/bin/molt" install
    run "$DEV/bin/molt" use opt
    assert_success
    assert_output_contains "(opt, "
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$OPT/bin/molt" ]]
}

# ST0008 AT004
@test "use opt with no MOLT_INSTALL_PREFIX is refused by name" {
    run "$DEV/bin/molt" use opt
    assert_failure
    assert_output_contains "MOLT_INSTALL_PREFIX"
}

# ST0008 AT004
@test "use opt over a prefix holding the brew tree is refused" {
    user_repo_declaring_prefix "$OPT"
    "$DEV/bin/molt" install --managed-by brew
    run "$DEV/bin/molt" use opt
    assert_failure
    assert_output_contains "is the brew tree, not the opt tree"
}

# ST0008 AT004
@test "use brew refuses a missing keg, naming brew install, then removes the link" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    install_fake_brew
    "$DEV/bin/molt" use dev
    run "$DEV/bin/molt" use brew
    assert_failure
    assert_output_contains "brew install matthewsinclair/molt/molt"
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$DEV/bin/molt" ]]
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    run "$DEV/bin/molt" use brew
    assert_success
    assert_output_contains "(brew, "
    [[ ! -e "$HOME/.local/bin/molt" && ! -L "$HOME/.local/bin/molt" ]]
    run "$DEV/bin/molt" use
    assert_success
    grep -qxF -- "There is no ~/.local/bin/molt, so brew serves molt $(cat "$DEV/VERSION") (brew, $(git -C "$DEV" rev-parse --short=12 HEAD))" <<< "$output"
    run "$DEV/bin/molt" use brew
    assert_success
}

# ST0008 AT004
@test "use brew refuses a file or a link to no tree at ~/.local/bin/molt, and leaves it" {
    install_fake_brew
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    mkdir -p "$HOME/.local/bin" && echo mine > "$HOME/.local/bin/molt"
    run "$DEV/bin/molt" use brew
    assert_failure
    assert_output_contains "is not a symlink; it is left as it is"
    [[ "$(cat "$HOME/.local/bin/molt")" == mine ]]
    rm "$HOME/.local/bin/molt" && ln -s /etc/hosts "$HOME/.local/bin/molt"
    run "$DEV/bin/molt" use brew
    assert_failure
    [[ "$(readlink "$HOME/.local/bin/molt")" == /etc/hosts ]]
}

# ST0008 AT004
@test "with no link, use and doctor fail when PATH's first molt is not brew's" {
    install_fake_brew
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    mkdir -p "$BATS_TEST_TMPDIR/stray"
    ln -s "$DEV/bin/molt" "$BATS_TEST_TMPDIR/stray/molt"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" use
    assert_failure
    assert_output_contains "so brew should serve molt, but PATH runs $BATS_TEST_TMPDIR/stray/molt, which is no brew tree's"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ⚠ there is no ~/.local/bin/molt, so brew should serve molt"
    run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ✓ brew's, with no ~/.local/bin/molt"
}

# ST0008 AT004
@test "a link that Homebrew's molt shadows is named as Homebrew's bin ahead of ~/.local/bin" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    install_fake_brew
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    "$DEV/bin/molt" use dev
    PATH="$BATS_TEST_TMPDIR/brew/bin:$PATH" run "$DEV/bin/molt" use
    assert_failure
    assert_output_contains "PATH runs Homebrew's $BATS_TEST_TMPDIR/brew/bin/molt ahead of ~/.local/bin/molt"
}

# ST0008 AT004
@test "use with no argument reports the tree ~/.local/bin/molt serves, and changes nothing" {
    run "$DEV/bin/molt" use
    assert_failure
    "$DEV/bin/molt" install --prefix "$OPT"
    mkdir -p "$HOME/.local/bin" && ln -s "$OPT/bin/molt" "$HOME/.local/bin/molt"
    run "$DEV/bin/molt" use
    assert_success
    grep -qxF -- "~/.local/bin/molt serves molt $(cat "$DEV/VERSION") (opt, $(git -C "$DEV" rev-parse --short=12 HEAD))" <<< "$output"
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$OPT/bin/molt" ]]
}

# ST0008 AT004
@test "use takes only dev, opt or brew" {
    run "$DEV/bin/molt" use beta
    assert_failure
    assert_output_contains "dev, opt or brew"
}

# --- The local-bin liberator stops choosing ---

@test "local-bin in a brew run creates no link, and no link passes as brew" {
    install_fake_brew
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    mkdir -p "$HOME/.local/bin"
    load_liberator local-bin
    MOLT_ROOT="$KEG"
    run local-bin_check
    assert_success
    run local-bin_install
    assert_success
    [[ ! -e "$HOME/.local/bin/molt" && ! -L "$HOME/.local/bin/molt" ]]
    run local-bin_verify
    assert_success
    assert_output_contains "there is no ~/.local/bin/molt, so brew serves molt $(cat "$DEV/VERSION") (brew, "
}

@test "local-bin keeps a link into the brew tree, and check names molt use brew to remove it" {
    install_fake_brew
    "$DEV/bin/molt" install --prefix "$KEG" --managed-by brew
    mkdir -p "$HOME/.local/bin" && ln -s "$KEG/bin/molt" "$HOME/.local/bin/molt"
    load_liberator local-bin
    MOLT_ROOT="$KEG"
    run local-bin_check
    assert_failure
    assert_output_contains "leads into the brew tree; run molt use brew"
    run local-bin_install
    assert_success
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$KEG/bin/molt" ]]
}

# ST0008 AT004
@test "local-bin keeps a healthy link to another tree when run from the checkout" {
    "$DEV/bin/molt" install --prefix "$OPT"
    mkdir -p "$HOME/.local/bin" && ln -s "$OPT/bin/molt" "$HOME/.local/bin/molt"
    load_liberator local-bin
    MOLT_ROOT="$DEV"
    run local-bin_check
    assert_success
    run local-bin_install
    assert_success
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$OPT/bin/molt" ]]
    run local-bin_verify
    assert_success
    assert_output_contains "serves molt $(cat "$DEV/VERSION") (opt, "
}

@test "local-bin links the running tree when there is no link, or it is broken" {
    load_liberator local-bin
    MOLT_ROOT="$DEV"
    run local-bin_check
    assert_failure
    local-bin_install
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$DEV/bin/molt" ]]
    rm "$HOME/.local/bin/molt" && ln -s "$BATS_TEST_TMPDIR/gone/bin/molt" "$HOME/.local/bin/molt"
    run local-bin_check
    assert_failure
    local-bin_install
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$DEV/bin/molt" ]]
}

@test "local-bin fails a link that leads to no tree's bin/molt, and leaves it" {
    mkdir -p "$HOME/.local/bin" "$BATS_TEST_TMPDIR/elsewhere/bin"
    echo '#!/bin/sh' > "$BATS_TEST_TMPDIR/elsewhere/bin/molt"
    ln -s "$BATS_TEST_TMPDIR/elsewhere/bin/molt" "$HOME/.local/bin/molt"
    load_liberator local-bin
    run local-bin_check
    assert_failure
    assert_output_contains "no dev, opt or brew tree's bin/molt"
    MOLT_ROOT="$DEV"
    run local-bin_install
    assert_failure
    assert_output_contains "no dev, opt or brew tree's bin/molt; it is left as it is"
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$BATS_TEST_TMPDIR/elsewhere/bin/molt" ]]
}

@test "local-bin refuses a file at ~/.local/bin/molt that is not a link, and leaves it" {
    mkdir -p "$HOME/.local/bin" && echo "mine" > "$HOME/.local/bin/molt"
    load_liberator local-bin
    MOLT_ROOT="$DEV"
    run local-bin_install
    assert_failure
    assert_output_contains "is not a symlink; it is left as it is"
    [[ ! -L "$HOME/.local/bin/molt" && "$(cat "$HOME/.local/bin/molt")" == mine ]]
    run bash -c "ls \"$HOME\"/.local/bin"
    [[ "$output" == molt ]]
}

# --- molt version, doctor and test by tree ---

@test "molt version and --version name the opt tree and its commit" {
    "$DEV/bin/molt" install --prefix "$OPT"
    local want
    want="molt $(cat "$DEV/VERSION") (opt, $(git -C "$DEV" rev-parse --short=12 HEAD))"
    run "$OPT/bin/molt" version
    assert_success
    [[ "$output" == "$want" ]]
    run "$OPT/bin/molt" --version
    [[ "$output" == "$want" ]]
}

# ST0008 AT003
@test "molt test is refused in opt, naming the dev tree" {
    "$DEV/bin/molt" install --prefix "$OPT"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    run "$OPT/bin/molt" test
    assert_failure
    assert_output_contains "molt test runs in a dev tree"
    assert_output_contains "run it in $DEV"
}

# ST0008 AT003
@test "doctor checks an opt tree against its manifest, not for test/" {
    "$DEV/bin/molt" install --prefix "$OPT"
    run "$OPT/bin/molt" doctor
    assert_output_contains "molt $(cat "$DEV/VERSION") (opt, "
    assert_output_contains "Checking tree... ✓ opt: every file matches its manifest"
    echo "# drift" >> "$OPT/lib/molt.sh"
    run "$OPT/bin/molt" doctor
    assert_output_contains "Checking tree... ⚠ opt, not what its manifest says"
    assert_output_contains "lib/molt.sh has changed"
}

@test "doctor in a dev tree checks for test/" {
    run "$DEV/bin/molt" doctor
    assert_output_contains "Checking tree... ✓ dev: lib/ liberators/ test/"
}

# --- molt upgrade by tree ---

# A user repo with no upstream, which molt upgrade warns about and skips, so a
# run pulls nothing from outside the test directory.
upgrade_user_repo() {
    export MOLT_CFG_DIR="$BATS_TEST_TMPDIR/cfg"
    local repo="$MOLT_CFG_DIR/Molt-$(whoami)"
    create_test_repo "$repo"
    git -C "$repo" init -q
    git -C "$repo" add -A
    git -C "$repo" -c user.name=t -c user.email=t@t commit -qm cfg
}

# The dev tree with its liberators replaced by one, zzz, whose upgrade hook
# says which commit's code ran it, so an upgrade runs no real liberator.
dev_tree_with_one_liberator() {
    git -C "$DEV" rm -q -r liberators
    mkdir -p "$DEV/liberators"
    printf 'zzz_check() { return 0; }\nzzz_upgrade() { echo "zzz on %s"; }\n' "$1" > "$DEV/liberators/zzz.sh"
    git -C "$DEV" add -A
    git -C "$DEV" -c user.name=t -c user.email=t@t commit -qm "$1"
}

# The dev tree's HEAD published as the keg of version $1, laid out as Homebrew
# lays a formula out: the keg under Cellar/molt/$1, and opt/molt a link to it,
# so KEG, the formula's libexec, resolves into it.
install_brew_keg() {
    local brew="$BATS_TEST_TMPDIR/brew"
    "$DEV/bin/molt" install --prefix "$brew/Cellar/molt/$1/libexec" --managed-by brew >/dev/null
    mkdir -p "$brew/opt"
    ln -sfn "../Cellar/molt/$1" "$brew/opt/molt"
}

# A brew first on PATH: --prefix answers $BATS_TEST_TMPDIR/brew; any other call
# made without HOMEBREW_NO_AUTO_UPDATE logs "auto-update on"; update fails with
# FAKE_BREW_UPDATE_STATUS; outdated answers as FAKE_BREW_OUTDATED says
# (current, outdated or broken); upgrade publishes the
# dev tree's HEAD as the keg of version FAKE_BREW_NEW_KEG, points opt/molt at
# it and removes the old keg, as brew cleanup can, or fails with
# FAKE_BREW_UPGRADE_STATUS. Each call is logged to brew.log.
install_brew_with_upgrade() {
    install_fake_brew
    cat > "$BATS_TEST_TMPDIR/bin/brew" <<FAKE
#!/usr/bin/env bash
echo "brew \$*" >> "$BATS_TEST_TMPDIR/brew.log"
case "\$1" in
  --prefix) echo "$BATS_TEST_TMPDIR/brew"; exit 0 ;;
esac
[ -n "\${HOMEBREW_NO_AUTO_UPDATE:-}" ] || echo "auto-update on: \$*" >> "$BATS_TEST_TMPDIR/brew.log"
case "\$1" in
  update) exit "\${FAKE_BREW_UPDATE_STATUS:-0}" ;;
  outdated)
    echo "Warning: something brew says aside" >&2
    case "\${FAKE_BREW_OUTDATED:-current}" in
      current) exit 0 ;;
      outdated) echo molt; exit 1 ;;
      *) echo "Error: something broke" >&2; exit 1 ;;
    esac ;;
  upgrade)
    [ "\${FAKE_BREW_UPGRADE_STATUS:-0}" -eq 0 ] || exit "\$FAKE_BREW_UPGRADE_STATUS"
    old="\$(readlink "$BATS_TEST_TMPDIR/brew/opt/molt")"
    "$DEV/bin/molt" install --prefix "$BATS_TEST_TMPDIR/brew/Cellar/molt/\$FAKE_BREW_NEW_KEG/libexec" --managed-by brew >/dev/null || exit 1
    ln -sfn "../Cellar/molt/\$FAKE_BREW_NEW_KEG" "$BATS_TEST_TMPDIR/brew/opt/molt"
    rm -rf "$BATS_TEST_TMPDIR/brew/opt/\$old" ;;
esac
FAKE
    chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

# ST0008 AT005
@test "upgrade in opt pulls no framework, names molt install --force and the dev tree's newer commit" {
    upgrade_user_repo
    "$DEV/bin/molt" install --prefix "$OPT"
    echo "# next" >> "$DEV/lib/molt.sh"
    git -C "$DEV" -c user.name=t -c user.email=t@t commit -qam next
    echo "# a board view" >> "$DEV/test/x.bats"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    run "$OPT/bin/molt" upgrade --self
    assert_success
    refute_output_contains "Checking framework repo"
    assert_output_contains "is not pulled; upgrade it from the dev tree with molt install --force"
    assert_output_contains "is at $(git -C "$DEV" rev-parse --short=12 HEAD), ahead of this install's"
    assert_output_contains "Checking user config repo"
}

# ST0008 AT005
@test "upgrade in brew upgrades nothing when brew outdated says the formula is current" {
    upgrade_user_repo
    install_brew_with_upgrade
    install_brew_keg 0.3.0
    run "$KEG/bin/molt" upgrade --self
    assert_success
    assert_output_contains "matthewsinclair/molt/molt is current"
    run grep -c "brew upgrade" "$BATS_TEST_TMPDIR/brew.log"
    [[ "$output" == 0 ]]
}

# ST0008 AT005
@test "upgrade in brew runs brew upgrade for an outdated formula and restarts on the new keg" {
    upgrade_user_repo
    install_brew_with_upgrade
    dev_tree_with_one_liberator old
    install_brew_keg 0.3.0
    dev_tree_with_one_liberator new
    FAKE_BREW_OUTDATED=outdated FAKE_BREW_NEW_KEG=0.4.0 run "$KEG/bin/molt" upgrade --no-resleeve
    assert_success
    grep -qx "brew upgrade matthewsinclair/molt/molt" "$BATS_TEST_TMPDIR/brew.log"
    assert_output_contains "Framework updated (0.3.0 -> 0.4.0); restarting on the new code"
    assert_output_contains "zzz on new"
    refute_output_contains "zzz on old"
    [[ "$(grep -v -- --prefix "$BATS_TEST_TMPDIR/brew.log" | head -n 2)" == "brew update"$'\n'"brew outdated --quiet matthewsinclair/molt/molt" ]]
    run grep -c "auto-update on" "$BATS_TEST_TMPDIR/brew.log"
    [[ "$output" == 0 ]]
}

# ST0008 AT005
@test "a brew update that fails is counted in the verdict, and nothing is upgraded" {
    upgrade_user_repo
    install_brew_with_upgrade
    dev_tree_with_one_liberator old
    install_brew_keg 0.3.0
    FAKE_BREW_UPDATE_STATUS=1 FAKE_BREW_OUTDATED=outdated run "$KEG/bin/molt" upgrade --no-resleeve
    assert_failure
    assert_output_contains "brew update failed"
    assert_output_contains "Upgrade incomplete: the pull failed for brew update"
    run grep -c "brew outdated\\|brew upgrade" "$BATS_TEST_TMPDIR/brew.log"
    [[ "$output" == 0 ]]
}

@test "a revision bump, a new keg of the same commit, restarts on the new keg" {
    upgrade_user_repo
    install_brew_with_upgrade
    dev_tree_with_one_liberator old
    install_brew_keg 0.3.0
    FAKE_BREW_OUTDATED=outdated FAKE_BREW_NEW_KEG=0.3.0_1 run "$KEG/bin/molt" upgrade --no-resleeve
    assert_success
    [[ ! -e "$BATS_TEST_TMPDIR/brew/Cellar/molt/0.3.0" ]]
    assert_output_contains "Framework updated (0.3.0 -> 0.3.0_1); restarting on the new code"
    assert_output_contains "zzz on old"
}

@test "a brew upgrade that fails is counted in the verdict as a failed pull" {
    upgrade_user_repo
    install_brew_with_upgrade
    dev_tree_with_one_liberator old
    install_brew_keg 0.3.0
    FAKE_BREW_OUTDATED=outdated FAKE_BREW_UPGRADE_STATUS=1 run "$KEG/bin/molt" upgrade --no-resleeve
    assert_failure
    assert_output_contains "brew upgrade matthewsinclair/molt/molt failed"
    assert_output_contains "Upgrade incomplete: the pull failed for the brew upgrade of matthewsinclair/molt/molt"
    assert_output_contains "zzz on old"
}

@test "a brew outdated that cannot say fails the upgrade, naming what brew said" {
    upgrade_user_repo
    install_brew_with_upgrade
    dev_tree_with_one_liberator old
    install_brew_keg 0.3.0
    FAKE_BREW_OUTDATED=broken run "$KEG/bin/molt" upgrade --no-resleeve
    assert_failure
    assert_output_contains "brew outdated could not say whether matthewsinclair/molt/molt is current (exit 1)"
    assert_output_contains "Error: something broke"
    run grep -c "brew upgrade" "$BATS_TEST_TMPDIR/brew.log"
    [[ "$output" == 0 ]]
}

@test "a dry run in brew says it would upgrade an outdated formula, and does not" {
    upgrade_user_repo
    install_brew_with_upgrade
    install_brew_keg 0.3.0
    FAKE_BREW_OUTDATED=outdated run "$KEG/bin/molt" upgrade --self --dry-run
    assert_success
    assert_output_contains "Dry run: skipping brew update"
    assert_output_contains "WOULD BREW UPGRADE matthewsinclair/molt/molt"
    run grep -c "auto-update on\\|brew update\\|brew upgrade" "$BATS_TEST_TMPDIR/brew.log"
    [[ "$output" == 0 ]]
}

# --- What PATH runs for molt ---

# ST0008 AT004
@test "use fails, naming it, when another molt is ahead of ~/.local/bin/molt on PATH" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    mkdir -p "$BATS_TEST_TMPDIR/stray"
    ln -s "$DEV/bin/molt" "$BATS_TEST_TMPDIR/stray/molt"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" use dev
    assert_failure
    assert_output_contains "(dev, "
    assert_output_contains "PATH runs $BATS_TEST_TMPDIR/stray/molt ahead of"
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$DEV/bin/molt" ]]
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" use
    assert_failure
    assert_output_contains "serves molt"
    assert_output_contains "so molt use does not change what runs"
    run "$DEV/bin/molt" use
    assert_success
}

@test "doctor passes ~/.local/bin/molt as what PATH runs, and names what shadows it" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    "$DEV/bin/molt" use dev
    run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ✓"
    mkdir -p "$BATS_TEST_TMPDIR/stray"
    ln -s "$DEV/bin/molt" "$BATS_TEST_TMPDIR/stray/molt"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ⚠ PATH runs $BATS_TEST_TMPDIR/stray/molt ahead of"
}

@test "a PATH entry that is ~/bin by another name runs ~/.local/bin/molt, and is no shadow" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    "$DEV/bin/molt" use dev
    ln -s "$HOME/.local/bin" "$BATS_TEST_TMPDIR/bin-by-another-name"
    PATH="$BATS_TEST_TMPDIR/bin-by-another-name:$PATH" run "$DEV/bin/molt" use
    assert_success
    refute_output_contains "ahead of"
}
