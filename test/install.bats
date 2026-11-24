#!/usr/bin/env bats
# install.bats — the dev, opt and brew trees Molt reads (ST0008). bin/devbin
# install publishes them and bin/devbin use switches them (issue I7892f34), so
# an opt or brew tree here is made by test/fixtures/publish-tree.

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
# formula's libexec under it, where the brew tree is. Homebrew's bin, with
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

# A sleeve with no user repo.
no_user_repo() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    unset MOLT_PRJ_DIR MOLT_CFG_DIR MOLT_LOCAL_BIN
}

# An opt tree at $1 published from DEV, or with brew as $2 a keg, as bin/devbin
# install publishes them.
publish_tree() {
    "$MOLT_TEST_DIR/fixtures/publish-tree" "$DEV" "$@"
}

# The switch pointed at the tree $1, as bin/devbin use dev or opt points it.
link_switch() {
    mkdir -p "$HOME/.local/bin"
    ln -s "$1/bin/molt" "$HOME/.local/bin/molt"
}

setup() {
    export BATS_TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/molt-test-$(date +%s)-$$-$RANDOM"
    mkdir -p "$BATS_TEST_TMPDIR"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export ORIGINAL_PWD="$(pwd)"
    cd "$BATS_TEST_TMPDIR"
    no_user_repo
    # ~/.local/bin first, as a sleeve's PATH has it, ahead of the checkout's bin/
    # that test_helper puts there, so the switch bin/devbin use sets is what runs.
    export PATH="$HOME/.local/bin:$PATH"
    make_dev_tree
    OPT="$BATS_TEST_TMPDIR/opt/molt"
}

# --- Tree identity ---

# ST0008 AT002
@test "molt_tree names dev, opt, brew and unknown" {
    publish_tree "$OPT"
    publish_tree "$BATS_TEST_TMPDIR/keg" brew
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
    publish_tree "$OPT"
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
    publish_tree "$OPT"
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

@test "an old-form opt manifest is unknown, and fails doctor naming bin/devbin install --force" {
    publish_tree "$OPT"
    # The manifest form before the contract: bare headers and no tool.
    sed -e '/^# tool:/d' -e 's/^# //' "$OPT/.molt-install" > "$BATS_TEST_TMPDIR/old" && mv "$BATS_TEST_TMPDIR/old" "$OPT/.molt-install"
    run "$OPT/bin/molt" version
    assert_output_contains "(unknown, unknown)"
    run "$OPT/bin/molt" doctor
    assert_output_contains "Checking tree... ✗ $OPT/.molt-install is an old manifest, from before the dev/opt/brew contract; republish with bin/devbin install --force in the dev tree"
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

# doctor needs envsubst on every sleeve, and bats only where molt runs from a
# dev tree, the one tree molt test runs in, so an opt or brew sleeve, as a
# participant's laptop is, does not fail for want of bats. The line names what
# it checked (issue 0095).
@test "doctor from an opt tree checks envsubst alone, and passes without bats (issue 0095)" {
    publish_tree "$OPT"
    local path
    path="$(path_without bats)"
    PATH="$path" command -v bats && fail "bats is still on PATH"
    PATH="$path" run "$OPT/bin/molt" doctor
    grep -qxF "Checking external dependencies... ✓ envsubst" <<< "$output" \
        || fail "Expected the line 'Checking external dependencies... ✓ envsubst'\nActual output:\n$output"
}

@test "doctor from a dev tree checks bats and envsubst both (issue 0095)" {
    local path
    path="$(path_without bats)"
    PATH="$path" run "$DEV/bin/molt" doctor
    grep -qxF "Checking external dependencies... ⚠ missing: bats" <<< "$output" \
        || fail "Expected the line 'Checking external dependencies... ⚠ missing: bats'\nActual output:\n$output"
    run "$DEV/bin/molt" doctor
    grep -qxF "Checking external dependencies... ✓ bats envsubst" <<< "$output" \
        || fail "Expected the line 'Checking external dependencies... ✓ bats envsubst'\nActual output:\n$output"
}

@test "molt_install_drift names a changed, a missing and an unlisted file" {
    publish_tree "$OPT"
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

# ST0008 AT004
@test "with no link, doctor fails when PATH's first molt is not brew's" {
    install_fake_brew
    publish_tree "$KEG" brew
    mkdir -p "$BATS_TEST_TMPDIR/stray"
    ln -s "$DEV/bin/molt" "$BATS_TEST_TMPDIR/stray/molt"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ⚠ there is no ~/.local/bin/molt, so brew should serve molt, but PATH runs $BATS_TEST_TMPDIR/stray/molt, which is no brew tree's"
    run "$DEV/bin/molt" doctor
    # Run from the test's dev tree, which is not this sleeve's: issue 0067's note.
    grep -qxF -- "Checking molt on PATH... ✓ brew's; no link of molt's; this doctor runs from a dev tree that is not this sleeve's, so nothing switches the sleeve to it; bin/devbin use in the checkout says which tree serves molt" <<< "$output"
}

# ST0008 AT004
@test "a link that Homebrew's molt shadows is named as Homebrew's bin ahead of ~/.local/bin" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    install_fake_brew
    publish_tree "$KEG" brew
    link_switch "$DEV"
    PATH="$BATS_TEST_TMPDIR/brew/bin:$PATH" run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ⚠ PATH runs Homebrew's $BATS_TEST_TMPDIR/brew/bin/molt ahead of ~/.local/bin/molt"
}

# --- The local-bin liberator stops choosing ---

@test "local-bin in a brew run creates no link, and no link passes as brew" {
    install_fake_brew
    publish_tree "$KEG" brew
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

@test "local-bin keeps a link into the brew tree, and check names bin/devbin use brew to remove it" {
    install_fake_brew
    publish_tree "$KEG" brew
    mkdir -p "$HOME/.local/bin" && ln -s "$KEG/bin/molt" "$HOME/.local/bin/molt"
    load_liberator local-bin
    MOLT_ROOT="$KEG"
    run local-bin_check
    assert_failure
    assert_output_contains "leads into the brew tree; run bin/devbin use brew in Molt's checkout"
    run local-bin_install
    assert_success
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$KEG/bin/molt" ]]
}

# Issue 0067: on a sleeve brew serves, with no link, molt run from a dev tree
# read local-bin as not installed, and a resleeve would have linked the sleeve
# to that tree. No link while Homebrew's molt is what PATH runs is brew.
@test "local-bin passes, and its install links nothing, from a dev tree on a sleeve brew serves" {
    install_fake_brew
    publish_tree "$KEG" brew
    mkdir -p "$HOME/.local/bin"
    load_liberator local-bin
    MOLT_ROOT="$DEV"
    run local-bin_check
    assert_success
    run local-bin_install
    assert_success
    assert_output_contains "so brew serves molt, not this dev tree"
    [[ ! -e "$HOME/.local/bin/molt" && ! -L "$HOME/.local/bin/molt" ]]
}

@test "doctor from the sleeve's own dev tree on a sleeve brew serves names bin/devbin use dev, never a resleeve" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    install_fake_brew
    publish_tree "$KEG" brew
    run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ✓ brew's; no link of molt's; this doctor runs from the dev tree, which does not serve molt, and bin/devbin use dev in the checkout switches the sleeve to it"
    refute_output_contains "local-bin"
    refute_output_contains "resleeve"
}

@test "doctor from a dev clone that is not the sleeve's says nothing switches the sleeve to it" {
    install_fake_brew
    publish_tree "$KEG" brew
    run "$DEV/bin/molt" doctor
    assert_output_contains "this doctor runs from a dev tree that is not this sleeve's, so nothing switches the sleeve to it; bin/devbin use in the checkout says which tree serves molt"
    refute_output_contains "local-bin"
    refute_output_contains "resleeve"
}

# ST0008 AT004
@test "local-bin keeps a healthy link to another tree when run from the checkout" {
    publish_tree "$OPT"
    link_switch "$OPT"
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

# Issue I7892f34: bin/devbin use is the switch's one writer (devbin T5), so
# local-bin names it and links nothing, where it once linked the running tree.
@test "local-bin makes no link when there is none, or it is broken, and names bin/devbin use" {
    mkdir -p "$HOME/.local/bin"
    load_liberator local-bin
    MOLT_ROOT="$DEV"
    run local-bin_check
    assert_failure
    assert_output_contains "run bin/devbin use dev or opt in Molt's checkout, which makes it"
    run local-bin_install
    assert_failure
    assert_output_contains "run bin/devbin use dev in Molt's checkout, which makes it"
    [[ ! -e "$HOME/.local/bin/molt" && ! -L "$HOME/.local/bin/molt" ]]
    ln -s "$BATS_TEST_TMPDIR/gone/bin/molt" "$HOME/.local/bin/molt"
    run local-bin_check
    assert_failure
    run local-bin_install
    assert_failure
    assert_output_contains "it is left as it is, so move it aside, then run bin/devbin use dev, opt or brew in Molt's checkout"
    [[ "$(readlink "$HOME/.local/bin/molt")" == "$BATS_TEST_TMPDIR/gone/bin/molt" ]]
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
    publish_tree "$OPT"
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
    publish_tree "$OPT"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    run "$OPT/bin/molt" test
    assert_failure
    assert_output_contains "molt test runs in a dev tree"
    assert_output_contains "run it in $DEV"
}

# ST0008 AT003
@test "doctor checks an opt tree against its manifest, not for test/" {
    publish_tree "$OPT"
    run "$OPT/bin/molt" doctor
    assert_output_contains "molt $(cat "$DEV/VERSION") (opt, "
    assert_output_contains "Checking tree... ✓ opt: every file matches its manifest"
    echo "# drift" >> "$OPT/lib/molt.sh"
    run "$OPT/bin/molt" doctor
    assert_output_contains "Checking tree... ⚠ opt, not what its manifest says"
    assert_output_contains "lib/molt.sh has changed"
}

@test "doctor in a dev tree passes, naming no path" {
    run "$DEV/bin/molt" doctor
    grep -qxF -- "Checking tree... ✓ dev" <<< "$output"
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
    publish_tree "$brew/Cellar/molt/$1/libexec" brew >/dev/null
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
    "$MOLT_TEST_DIR/fixtures/publish-tree" "$DEV" "$BATS_TEST_TMPDIR/brew/Cellar/molt/\$FAKE_BREW_NEW_KEG/libexec" brew >/dev/null || exit 1
    ln -sfn "../Cellar/molt/\$FAKE_BREW_NEW_KEG" "$BATS_TEST_TMPDIR/brew/opt/molt"
    rm -rf "$BATS_TEST_TMPDIR/brew/opt/\$old" ;;
esac
FAKE
    chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

# ST0008 AT005
@test "upgrade in opt pulls no framework, names bin/devbin install --force and the dev tree's newer commit" {
    upgrade_user_repo
    publish_tree "$OPT"
    echo "# next" >> "$DEV/lib/molt.sh"
    git -C "$DEV" -c user.name=t -c user.email=t@t commit -qam next
    echo "# a board view" >> "$DEV/test/x.bats"
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    run "$OPT/bin/molt" upgrade --self
    assert_success
    refute_output_contains "Checking framework repo"
    assert_output_contains "is not pulled; upgrade it from the dev tree with bin/devbin install --force"
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

@test "doctor passes the switch link as what PATH runs, and names what shadows it" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    link_switch "$DEV"
    run "$DEV/bin/molt" doctor
    grep -qxF -- "Checking molt on PATH... ✓ the switch link" <<< "$output"
    mkdir -p "$BATS_TEST_TMPDIR/stray"
    ln -s "$DEV/bin/molt" "$BATS_TEST_TMPDIR/stray/molt"
    PATH="$BATS_TEST_TMPDIR/stray:$PATH" run "$DEV/bin/molt" doctor
    assert_output_contains "Checking molt on PATH... ⚠ PATH runs $BATS_TEST_TMPDIR/stray/molt ahead of ~/.local/bin/molt, so bin/devbin use does not change what runs"
}

# rhadamanth's ~/bin is a link to ~/.local/bin: the link seen through it is
# still the link, not another molt ahead of it.
@test "a PATH entry that is ~/.local/bin by another name runs the switch link, and is no shadow" {
    export MOLT_PRJ_DIR="$BATS_TEST_TMPDIR/prj"
    link_switch "$DEV"
    ln -s "$HOME/.local/bin" "$BATS_TEST_TMPDIR/bin-by-another-name"
    PATH="$BATS_TEST_TMPDIR/bin-by-another-name:$PATH" run "$DEV/bin/molt" doctor
    grep -qxF -- "Checking molt on PATH... ✓ the switch link" <<< "$output"
}

# Issue I7892f34: the removed verbs are named, with what replaced them.
@test "molt install and molt use are refused, naming bin/devbin" {
    local verb
    for verb in install use; do
        run "$DEV/bin/molt" "$verb"
        assert_failure
        assert_output_contains "molt $verb is gone: run bin/devbin $verb in Molt's checkout"
    done
}
