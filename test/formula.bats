#!/usr/bin/env bats
# formula.bats — tools/formula render and publish (ST0008 D6)

load "test_helper.bash"

# A repo in the test directory holding this checkout's tools/formula and its
# template, with the template's url pointed at the repo itself, so publish
# asks a repository the test made. SRC names it, with an annotated v0.1.0 and
# v0.10.0 and a lightweight v0.2.0, and TAP a bare tap with a Formula/ dir.
make_formula_repos() {
    SRC="$BATS_TEST_TMPDIR/src"
    TAP="$BATS_TEST_TMPDIR/tap.git"
    mkdir -p "$SRC/tools" "$SRC/packaging/homebrew"
    cp -p "$MOLT_ROOT/tools/formula" "$SRC/tools/formula"
    sed "s|https://github.com/matthewsinclair/molt.git|file://$SRC|" \
        "$MOLT_ROOT/packaging/homebrew/molt.rb" > "$SRC/packaging/homebrew/molt.rb"
    git -C "$SRC" init -q
    git -C "$SRC" add -A
    git -C "$SRC" -c user.name=t -c user.email=t@t commit -qm src
    git -C "$SRC" -c user.name=t -c user.email=t@t tag -a v0.1.0 -m v0.1.0
    git -C "$SRC" -c user.name=t -c user.email=t@t tag -a v0.10.0 -m v0.10.0
    git -C "$SRC" tag v0.2.0
    git init -q --bare "$TAP"
    git clone -q "$TAP" "$BATS_TEST_TMPDIR/tapw" 2>/dev/null
    mkdir -p "$BATS_TEST_TMPDIR/tapw/Formula" && touch "$BATS_TEST_TMPDIR/tapw/Formula/.keep"
    git -C "$BATS_TEST_TMPDIR/tapw" add -A
    git -C "$BATS_TEST_TMPDIR/tapw" -c user.name=t -c user.email=t@t commit -qm init
    git -C "$BATS_TEST_TMPDIR/tapw" push -q origin HEAD 2>/dev/null
}

setup() {
    molt_test_setup
    # git reads none of the user's or the machine's config: a signing key, a
    # hook path or a url rewrite there would change what publish does here.
    export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
    : > "$GIT_CONFIG_GLOBAL"
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    make_formula_repos
}

# ST0008 AT006
@test "render writes the tag and the tag's commit, read from git, into the formula" {
    run "$SRC/tools/formula" render v0.1.0 "$BATS_TEST_TMPDIR/out/molt.rb"
    assert_success
    local commit
    commit="$(git -C "$SRC" rev-list -n 1 v0.1.0)"
    grep -qE '^ +tag: +"v0\.1\.0",$' "$BATS_TEST_TMPDIR/out/molt.rb"
    grep -qE "^ +revision: +\"$commit\"\$" "$BATS_TEST_TMPDIR/out/molt.rb"
    run grep -c '@@' "$BATS_TEST_TMPDIR/out/molt.rb"
    [[ "$output" == 0 ]]
}

# ST0008 AT006
@test "render refuses a missing tag, a lightweight tag and a name that is no tag" {
    run "$SRC/tools/formula" render v9.9.9 "$BATS_TEST_TMPDIR/a.rb"
    assert_failure
    assert_output_contains "no tag 'v9.9.9'"
    run "$SRC/tools/formula" render v0.2.0 "$BATS_TEST_TMPDIR/a.rb"
    assert_failure
    assert_output_contains "lightweight"
    run "$SRC/tools/formula" render 'v1/x' "$BATS_TEST_TMPDIR/a.rb"
    assert_failure
    [[ ! -e "$BATS_TEST_TMPDIR/a.rb" ]]
}

# ST0008 AT006
@test "render refuses a template without exactly one tag and one revision placeholder" {
    echo '# @@TAG@@' >> "$SRC/packaging/homebrew/molt.rb"
    run "$SRC/tools/formula" render v0.1.0 "$BATS_TEST_TMPDIR/a.rb"
    assert_failure
    assert_output_contains "exactly one of each"
}

@test "publish pushes the newest release's formula to the tap, once" {
    MOLT_TAP_URL="$TAP" run "$SRC/tools/formula" publish
    assert_success
    assert_output_contains "published v0.10.0"
    git -C "$TAP" show HEAD:Formula/molt.rb | grep -qE '^ +tag: +"v0\.10\.0",$'
    local head
    head="$(git -C "$TAP" rev-parse HEAD)"
    MOLT_TAP_URL="$TAP" run "$SRC/tools/formula" publish
    assert_success
    assert_output_contains "nothing to publish"
    [[ "$(git -C "$TAP" rev-parse HEAD)" == "$head" ]]
}

@test "publish refuses a template with changes no commit holds" {
    echo '# local' >> "$SRC/packaging/homebrew/molt.rb"
    MOLT_TAP_URL="$TAP" run "$SRC/tools/formula" publish
    assert_failure
    assert_output_contains "no commit holds"
}

@test "publish refuses a tag the formula's repository does not have" {
    sed -i.bak "s|file://$SRC|file://$BATS_TEST_TMPDIR/elsewhere|" "$SRC/packaging/homebrew/molt.rb"
    rm "$SRC/packaging/homebrew/molt.rb.bak"
    git init -q --bare "$BATS_TEST_TMPDIR/elsewhere"
    git -C "$SRC" commit -qam elsewhere
    MOLT_TAP_URL="$TAP" run "$SRC/tools/formula" publish
    assert_failure
    assert_output_contains "has no tag v0.10.0"
}
