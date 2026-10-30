#!/usr/bin/env bats
# env.bats — env liberator and lib/env.sh, Molt's one env writer (ST0008
# WP05): CLAUDE_CONFIG_DIR, each <TOOL>_INSTALL_PREFIX vars.sh exports, and a
# login shell's PATH for GUI apps, in env.sh and the GUI file. Every expected
# file is written out here by hand, never built with the writer's own helpers.

load "../test_helper.bash"

setup_env() {
    load_liberator claude
    load_liberator env

    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"
    export MOLT_AGT_DIR="$BATS_TEST_TMPDIR/agt"
    export MOLT_LOCAL_BIN="$HOME/.local/bin"
    unset UTILZ_INSTALL_PREFIX CLAUDE_CONFIG_DIR

    export TEST_USER_REPO="$BATS_TEST_TMPDIR/molt-testuser"
    VARS="$TEST_USER_REPO/instances/$(test_hostname)/vars.sh"
    mkdir -p "$(dirname "$VARS")"
    : > "$VARS"
    eval "molt_find_user_repo() { echo \"$TEST_USER_REPO\"; }"

    # A login shell, faked: it prints what its startup files might, then the
    # PATH it built, which login_path sets.
    export MOLT_LOGIN_SHELL="$BATS_TEST_TMPDIR/login-shell"
    login_path "$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin"

    # No /etc/environment unless a test writes one.
    export MOLT_ETC_ENVIRONMENT="$BATS_TEST_TMPDIR/etc-environment"

    # launchctl, faked first on PATH, so no test reaches the real launchd: it
    # logs each call's argv as one line of <word>s, and setenv and getenv keep
    # a value per name in LAUNCHD, which starts empty, as a login has not yet
    # run the plist. print shows them all in the GUI domain's environment
    # block, as launchd does; with LAUNCHD_GETENV_EMPTY set, getenv answers
    # nothing, as it did on gyges for values the domain held (issue 0072).
    export LAUNCHD="$BATS_TEST_TMPDIR/launchd" LAUNCHCTL_LOG="$BATS_TEST_TMPDIR/launchctl.log"
    mkdir -p "$LAUNCHD" "$BATS_TEST_TMPDIR/launchctl-stub"
    cat > "$BATS_TEST_TMPDIR/launchctl-stub/launchctl" <<'EOF'
#!/bin/sh
printf '<%s>' "$@" >> "$LAUNCHCTL_LOG"
echo >> "$LAUNCHCTL_LOG"
case "$1" in
  setenv) printf '%s' "$3" > "$LAUNCHD/$2" ;;
  getenv) if [ -z "${LAUNCHD_GETENV_EMPTY:-}" ] && [ -f "$LAUNCHD/$2" ]; then cat "$LAUNCHD/$2"; echo; fi ;;
  print)  printf '%s = {\n\ttype = User\n\tenvironment = {\n' "$2"
          for f in "$LAUNCHD"/*; do
            if [ -f "$f" ]; then printf '\t\t%s => %s\n' "${f##*/}" "$(cat "$f")"; fi
          done
          printf '\t}\n}\n' ;;
  *)      exit 1 ;;
esac
EOF
    chmod +x "$BATS_TEST_TMPDIR/launchctl-stub/launchctl"
    export PATH="$BATS_TEST_TMPDIR/launchctl-stub:$PATH"

    # systemctl, faked the same way for the systemd user manager on Linux:
    # `systemctl --user show-environment` prints SYSTEMD_ENV when a test sets
    # it, as GNOME's login shell uploads its environment over environment.d's
    # (issue 0076), and molt.conf's lines otherwise, as the manager read them.
    # With SYSTEMD_FAILS set it fails as a session with no user bus does.
    export SYSTEMCTL_LOG="$BATS_TEST_TMPDIR/systemctl.log"
    mkdir -p "$BATS_TEST_TMPDIR/systemctl-stub"
    cat > "$BATS_TEST_TMPDIR/systemctl-stub/systemctl" <<'EOF'
#!/bin/sh
printf '<%s>' "$@" >> "$SYSTEMCTL_LOG"
echo >> "$SYSTEMCTL_LOG"
[ "$*" = "--user show-environment" ] || exit 1
if [ -n "${SYSTEMD_FAILS:-}" ]; then echo "Failed to connect to bus: No medium found" >&2; exit 1; fi
if [ -n "${SYSTEMD_ENV:-}" ]; then cat "$SYSTEMD_ENV"; exit 0; fi
if [ -f "$HOME/.config/environment.d/molt.conf" ]; then grep -v '^#' "$HOME/.config/environment.d/molt.conf"; fi
exit 0
EOF
    chmod +x "$BATS_TEST_TMPDIR/systemctl-stub/systemctl"
    export PATH="$BATS_TEST_TMPDIR/systemctl-stub:$PATH"
}

# The sh script the plist $1 runs at login, read from its ProgramArguments by
# hand: the string after -c, its XML escapes undone.
plist_script() {
    sed -n '/<string>-c<\/string>/{n;p;}' "$1" \
        | sed -e 's/^    <string>//' -e 's/<\/string>$//' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/\&/g'
}

# A login, faked: runs the plist's script with the stub launchctl.
log_in() {
    sh -c "$(plist_script "$HOME/Library/LaunchAgents/com.molt.env.plist")"
}

# The fake login shell prints $1 as its PATH.
login_path() {
    printf '#!/bin/sh\necho "a banner a zshrc printed"\necho "molt-path:%s"\n' "$1" > "$MOLT_LOGIN_SHELL"
    chmod +x "$MOLT_LOGIN_SHELL"
}

# A sleeve whose Claude Code state is already in its declared config dir.
declare_moved() {
    CONFIG="$HOME/.config/claude"
    mkdir -p "$CONFIG"
    printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" >> "$VARS"
}

on_macos() { eval 'molt_platform() { echo macos; }'; }
on_linux() { eval 'molt_platform() { echo linux; }'; }

@test "env publishes CLAUDE_CONFIG_DIR and each declared prefix in env.sh and the plist, and the login PATH in the plist alone" {
    setup_env
    on_macos
    declare_moved
    echo 'export UTILZ_INSTALL_PREFIX="$HOME/Devel/opt/utilz"' >> "$VARS"
    run env_install
    assert_success
    assert_output_contains "takes effect for apps launched after the next login"
    [ "$(cat "$HOME/.config/molt/env.sh")" = "# env.sh -- GENERATED by molt (lib/env.sh); do not edit.
# Sourced by ~/.zshenv. Every variable molt publishes to shells is here, and
# molt reads each back from its export line, in exactly this form.
export CLAUDE_CONFIG_DIR=\"$HOME/.config/claude\"
export UTILZ_INSTALL_PREFIX=\"$HOME/Devel/opt/utilz\"" ]
    local plist="$HOME/Library/LaunchAgents/com.molt.env.plist"
    grep -qF "<string>com.molt.env</string>" "$plist"
    [ "$(sed -n '/<key>ProgramArguments<\/key>/,/<\/array>/p' "$plist")" = "  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>launchctl setenv 'CLAUDE_CONFIG_DIR' '$HOME/.config/claude'; launchctl setenv 'UTILZ_INSTALL_PREFIX' '$HOME/Devel/opt/utilz'; launchctl setenv 'PATH' '$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin'</string>
  </array>" ]
    if command -v plutil >/dev/null; then
        plutil -lint "$plist"
    fi
    log_in
    run env_check
    assert_success
    run env_verify
    assert_success
    assert_output_contains "CLAUDE_CONFIG_DIR, UTILZ_INSTALL_PREFIX in ~/.config/molt/env.sh and ~/Library/LaunchAgents/com.molt.env.plist"
    assert_output_contains "PATH in ~/Library/LaunchAgents/com.molt.env.plist"
}

@test "on Linux the GUI file is environment.d/molt.conf with every pair" {
    setup_env
    on_linux
    declare_moved
    run env_install
    assert_success
    [ "$(grep -v '^#' "$HOME/.config/environment.d/molt.conf")" = "CLAUDE_CONFIG_DIR=$HOME/.config/claude
PATH=$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin" ]
    [ ! -e "$HOME/Library" ]
}

@test "a prefix comes from vars.sh alone: one inherited from the shell is not published, nor a MOLT_ one, and a brew-only sleeve gets none" {
    setup_env
    on_linux
    export UTILZ_INSTALL_PREFIX="/somewhere/inherited"
    echo 'export MOLT_INSTALL_PREFIX="$HOME/Devel/opt/molt"' >> "$VARS"
    run env_install
    assert_success
    run grep -c 'INSTALL_PREFIX' "$HOME/.config/molt/env.sh" "$HOME/.config/environment.d/molt.conf"
    [ "$output" = "$HOME/.config/molt/env.sh:0
$HOME/.config/environment.d/molt.conf:0" ]
}

@test "a value a file would read as syntax is refused by name, and left out" {
    setup_env
    on_linux
    echo "export UTILZ_INSTALL_PREFIX='/opt/ut\"ilz'" >> "$VARS"
    run env_install
    assert_failure
    assert_output_contains "UTILZ_INSTALL_PREFIX holds a character env.sh, a plist or environment.d would read as syntax"
    run grep -c UTILZ "$HOME/.config/molt/env.sh"
    [ "$output" = 0 ]
}

@test "a login PATH that does not start with ~/.local/bin, a failed shell or no PATH printed is refused, and PATH is left out of the plist" {
    setup_env
    on_macos
    login_path "/opt/homebrew/bin:$HOME/.local/bin:/usr/bin"
    run env_install
    assert_failure
    assert_output_contains "a login shell's PATH starts with /opt/homebrew/bin, not ~/.local/bin"
    printf '#!/bin/sh\nexit 3\n' > "$MOLT_LOGIN_SHELL"
    run env_install
    assert_failure
    assert_output_contains "failed, so its PATH was not read"
    printf '#!/bin/sh\necho hello\n' > "$MOLT_LOGIN_SHELL"
    run env_install
    assert_failure
    assert_output_contains "printed no PATH"
    run grep -c "setenv 'PATH'" "$HOME/Library/LaunchAgents/com.molt.env.plist"
    [ "$output" = 0 ]
}

@test "the login shell starts with nothing of molt's environment" {
    setup_env
    on_linux
    export MOLT_ENV_LEAK=yes
    printf '#!/bin/sh\necho "molt-path:%s:/leak-${MOLT_ENV_LEAK:-none}:/home-$HOME"\n' "$MOLT_LOCAL_BIN" > "$MOLT_LOGIN_SHELL"
    run env_install
    assert_success
    grep -qxF "PATH=$HOME/.local/bin:/leak-none:/home-$HOME" "$HOME/.config/environment.d/molt.conf"
}

# The fake login shell puts ~/.local/bin ahead of the PATH it was started
# with, as a zshrc does, and alone when it was started with none: a shell's
# own default PATH is not in its environment.
login_path_from_env() {
    printf '#!/bin/sh\np="$(/usr/bin/env | sed -n "s/^PATH=//p")"\necho "molt-path:%s${p:+:$p}"\n' "$MOLT_LOCAL_BIN" > "$MOLT_LOGIN_SHELL"
    chmod +x "$MOLT_LOGIN_SHELL"
}

# Ubuntu's /etc/environment, with a comment and another variable around it.
ETC_ENVIRONMENT='# set by the installer
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
LANG=en_GB.UTF-8
'

@test "on Linux the login shell starts from /etc/environment's PATH (issue 0056)" {
    setup_env
    on_linux
    login_path_from_env
    printf '%s' "$ETC_ENVIRONMENT" > "$MOLT_ETC_ENVIRONMENT"
    run env_install
    assert_success
    [ "$(sed -n 's/^PATH=//p' "$HOME/.config/environment.d/molt.conf")" = "$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin" ]
    run grep -c /usr/ucb "$HOME/.config/environment.d/molt.conf"
    [ "$output" = 0 ]
    printf "PATH='/usr/bin:/bin'\n" > "$MOLT_ETC_ENVIRONMENT"
    run env_install
    assert_success
    grep -qxF "PATH=$HOME/.local/bin:/usr/bin:/bin" "$HOME/.config/environment.d/molt.conf"
}

@test "with no /etc/environment, or no PATH line in it, or on macOS, the login shell gets no PATH" {
    setup_env
    login_path_from_env
    local want="$HOME/.local/bin"
    on_linux
    run env_install
    assert_success
    grep -qxF "PATH=$want" "$HOME/.config/environment.d/molt.conf"
    printf 'LANG=en_GB.UTF-8\n' > "$MOLT_ETC_ENVIRONMENT"
    run env_install
    assert_success
    grep -qxF "PATH=$want" "$HOME/.config/environment.d/molt.conf"
    on_macos
    printf '%s' "$ETC_ENVIRONMENT" > "$MOLT_ETC_ENVIRONMENT"
    run molt_env_login_path
    assert_success
    [ "$output" = "$want" ]
}

@test "the login shell never starts from molt's own PATH" {
    setup_env
    on_linux
    login_path_from_env
    PATH="/molt-caller:$PATH" run env_install
    assert_success
    run grep -c /molt-caller "$HOME/.config/environment.d/molt.conf"
    [ "$output" = 0 ]
}

@test "CLAUDE_CONFIG_DIR is not published ahead of the move, and one already published is kept while a move is pending" {
    setup_env
    on_linux
    CONFIG="$HOME/.config/claude"
    printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$CONFIG" >> "$VARS"
    mkdir -p "$HOME/.claude/projects"
    run env_install
    assert_success
    run grep -c CLAUDE_CONFIG_DIR "$HOME/.config/molt/env.sh"
    [ "$output" = 0 ]
    # Moved, published; then a new dir is declared, and its move is pending.
    mkdir -p "$CONFIG" && mv "$HOME/.claude/projects" "$CONFIG/" && rm -rf "$HOME/.claude"
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$HOME/.local/claude" > "$VARS"
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
}

@test "check and verify name a file missing or not what molt would publish; install puts it back" {
    setup_env
    on_macos
    declare_moved
    env_install >/dev/null
    local plist="$HOME/Library/LaunchAgents/com.molt.env.plist"
    echo "<!-- an edit -->" >> "$plist"
    run env_check
    assert_failure
    assert_output_contains "env: ~/Library/LaunchAgents/com.molt.env.plist is not what molt would publish"
    login_path "$HOME/.local/bin:/usr/bin"
    run env_install
    assert_success
    log_in
    run env_check
    assert_success
    rm "$HOME/.config/molt/env.sh"
    run env_verify
    assert_failure
    assert_output_contains "VERIFY FAIL: env: ~/.config/molt/env.sh is missing"
    echo 'export UTILZ_INSTALL_PREFIX="/opt/utilz"' >> "$VARS"
    run env_install
    assert_success
    log_in
    run env_check
    assert_success
}

@test "the claude liberator's old plist is removed when it is what molt rendered, and refused by name when it is not" {
    setup_env
    on_macos
    declare_moved
    local old="$HOME/Library/LaunchAgents/com.molt.claude-config-dir.plist"
    mkdir -p "$(dirname "$old")"
    cat > "$old" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- GENERATED by molt from templates/claude; do not edit. At login it sets
     CLAUDE_CONFIG_DIR for every app launchd starts, so a Claude Code started
     from the Dock, an editor or the desktop app finds its state where a
     shell's does (Molt ST0006). -->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.molt.claude-config-dir</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/launchctl</string>
    <string>setenv</string>
    <string>CLAUDE_CONFIG_DIR</string>
    <string>$HOME/.config/claude</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF
    cp "$old" "$BATS_TEST_TMPDIR/old.plist"
    echo "<!-- mine -->" >> "$old"
    run env_check
    assert_failure
    assert_output_contains "env: ~/Library/LaunchAgents/com.molt.claude-config-dir.plist is retired but is not what molt rendered"
    run env_install
    assert_failure
    assert_output_contains "is retired but is not what molt rendered, so nothing was published"
    [ ! -e "$HOME/Library/LaunchAgents/com.molt.env.plist" ]
    [ -e "$old" ]
    cp "$BATS_TEST_TMPDIR/old.plist" "$old"
    run env_check
    assert_failure
    assert_output_contains "env: ~/Library/LaunchAgents/com.molt.claude-config-dir.plist is retired, and molt resleeve removes it"
    run env_install
    assert_success
    [ ! -e "$old" ]
    [ -e "$HOME/Library/LaunchAgents/com.molt.env.plist" ]
    log_in
    run env_check
    assert_success
}

@test "the claude liberator's old claude.conf is removed on Linux when it is what molt rendered" {
    setup_env
    on_linux
    declare_moved
    local old="$HOME/.config/environment.d/claude.conf"
    mkdir -p "$(dirname "$old")"
    printf '%s\n' "# claude.conf -- GENERATED by molt from templates/claude; do not edit." \
        "# systemd reads environment.d at login, so every GUI and terminal child of the" \
        "# session finds Claude Code's state where a shell does (Molt ST0006)." \
        "CLAUDE_CONFIG_DIR=$HOME/.config/claude" > "$old"
    run env_install
    assert_success
    [ ! -e "$old" ]
    grep -qxF "CLAUDE_CONFIG_DIR=$HOME/.config/claude" "$HOME/.config/environment.d/molt.conf"
}

# ac, 24 Oct (finding 7): moved to A, then B declared, existing and empty. The
# claude liberator refuses the switch, and env must not publish B behind it.
@test "a newly declared, empty config dir is not handed over while env.sh publishes another that exists" {
    setup_env
    on_linux
    declare_moved
    run env_install
    assert_success
    local old="$CONFIG"
    mkdir -p "$HOME/.local/claude"
    printf 'export MOLT_CLAUDE_CONFIG_DIR=%q\n' "$HOME/.local/claude" > "$VARS"
    run env_install
    assert_success
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$old\"" "$HOME/.config/molt/env.sh"
    grep -qxF "CLAUDE_CONFIG_DIR=$old" "$HOME/.config/environment.d/molt.conf"
}

# vc, 24 Oct: each pair stands alone, so a refused PATH leaves the rest
# published and the run still fails, naming it.
@test "a refused PATH is left out, every other pair is published, and the run fails naming it" {
    setup_env
    on_macos
    declare_moved
    echo 'export UTILZ_INSTALL_PREFIX="/opt/utilz"' >> "$VARS"
    login_path "/opt/homebrew/bin:/usr/bin"
    run env_install
    assert_failure
    assert_output_contains "env: a login shell's PATH starts with /opt/homebrew/bin, not ~/.local/bin"
    grep -qxF "export CLAUDE_CONFIG_DIR=\"$CONFIG\"" "$HOME/.config/molt/env.sh"
    grep -qxF 'export UTILZ_INSTALL_PREFIX="/opt/utilz"' "$HOME/.config/molt/env.sh"
    local plist="$HOME/Library/LaunchAgents/com.molt.env.plist"
    grep -qF "launchctl setenv 'CLAUDE_CONFIG_DIR' '$CONFIG'" "$plist"
    run grep -c "setenv 'PATH'" "$plist"
    [ "$output" = 0 ]
    run env_check
    assert_failure
    assert_output_contains "env: a login shell's PATH starts with /opt/homebrew/bin"
    refute_output_contains "is not what molt would publish"
    run grep -c '^export PATH' "$HOME/.config/molt/env.sh"
    [ "$output" = 0 ]
}

@test "a refused prefix is left out alone, and with nothing for the GUI file the plist runs true" {
    setup_env
    on_macos
    echo "export UTILZ_INSTALL_PREFIX='relative/utilz'" >> "$VARS"
    echo 'export INTENT_INSTALL_PREFIX="/opt/intent"' >> "$VARS"
    printf '#!/bin/sh\nexit 1\n' > "$MOLT_LOGIN_SHELL"
    run env_install
    assert_failure
    assert_output_contains "env: UTILZ_INSTALL_PREFIX is not an absolute path: relative/utilz"
    assert_output_contains "env: PATH was not published"
    grep -qxF 'export INTENT_INSTALL_PREFIX="/opt/intent"' "$HOME/.config/molt/env.sh"
    run grep -c UTILZ "$HOME/.config/molt/env.sh"
    [ "$output" = 0 ]
    sed -i.bak '/INTENT_INSTALL_PREFIX/d' "$VARS" && rm "$VARS.bak"
    sed -i.bak '/UTILZ_INSTALL_PREFIX/d' "$VARS" && rm "$VARS.bak"
    run env_install
    assert_failure
    grep -qxF '    <string>/usr/bin/true</string>' "$HOME/Library/LaunchAgents/com.molt.env.plist"
    if command -v plutil >/dev/null; then
        plutil -lint "$HOME/Library/LaunchAgents/com.molt.env.plist"
    fi
}

@test "the plist's script runs one launchctl setenv per pair, each value byte for byte, spaces, quotes and \$ included (issue 0059)" {
    # rhadamanth, 25 Oct 2026: the plist ran ONE launchctl setenv with every
    # pair, and launchd held only CLAUDE_CONFIG_DIR.
    setup_env
    local plist="$BATS_TEST_TMPDIR/env.plist" q="'" dq='"'
    printf '%s\t%s\t%s\n' \
        CLAUDE_CONFIG_DIR all "/Users/a b/.config/claude" \
        ODD all "it${q}s \$HOME ${dq}quoted${dq} & <b>" \
        PATH gui "/x/bin:/usr/bin" | _molt_env_plist_text > "$plist"
    if command -v plutil >/dev/null; then
        plutil -lint "$plist"
    fi
    sh -c "$(plist_script "$plist")"
    [ "$(cat "$LAUNCHCTL_LOG")" = "<setenv><CLAUDE_CONFIG_DIR></Users/a b/.config/claude>
<setenv><ODD><it${q}s \$HOME ${dq}quoted${dq} & <b>>
<setenv><PATH></x/bin:/usr/bin>" ]
}

@test "on macOS check names each pair launchd does not hold as published, and passes once a login has run the plist; it only reads (issue 0059)" {
    setup_env
    on_macos
    declare_moved
    echo 'export UTILZ_INSTALL_PREFIX="/opt/utilz"' >> "$VARS"
    env_install >/dev/null
    printf '%s' "$CONFIG" > "$LAUNCHD/CLAUDE_CONFIG_DIR"
    printf '%s' "/old/utilz" > "$LAUNCHD/UTILZ_INSTALL_PREFIX"
    run env_check
    assert_failure
    assert_output_contains "env: launchd holds another UTILZ_INSTALL_PREFIX, so GUI apps get /old/utilz"
    assert_output_contains "env: launchd does not hold PATH, so GUI apps do not get it"
    refute_output_contains "launchd does not hold CLAUDE_CONFIG_DIR"
    assert_output_contains "takes effect at the next login, or now with: launchctl bootout gui/$(id -u)/com.molt.env; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.molt.env.plist"
    run grep -c '^<setenv>' "$LAUNCHCTL_LOG"
    [ "$output" = 0 ]
    log_in
    run env_check
    assert_success
    on_linux
    env_install >/dev/null
    : > "$LAUNCHCTL_LOG"
    run env_check
    assert_success
    [ ! -s "$LAUNCHCTL_LOG" ]
}

# gyges, 28 Oct: launchctl getenv answered nothing for both pairs while
# `launchctl print gui/501` held them, so check failed a loaded agent (issue
# 0072). It reads the GUI domain itself.
@test "on macOS check reads launchd's GUI domain, so it passes where launchctl getenv answers nothing (issue 0072)" {
    setup_env
    on_macos
    declare_moved
    env_install >/dev/null
    log_in
    export LAUNCHD_GETENV_EMPTY=1
    run env_check
    assert_success
    refute_output_contains "launchd does not hold"
    grep -qxF "<print><gui/$(id -u)>" "$LAUNCHCTL_LOG"
}

# kovacs, 30 Oct: GNOME's login shell uploads its environment into the systemd
# user manager over environment.d's, so the manager held a PATH molt.conf does
# not (issue 0076). check names each pair the manager holds otherwise.
@test "on Linux check names each pair the systemd user manager holds otherwise, and says to log out and back in (issue 0076)" {
    setup_env
    on_linux
    declare_moved
    echo 'export UTILZ_INSTALL_PREFIX="/opt/utilz"' >> "$VARS"
    env_install >/dev/null
    export SYSTEMD_ENV="$BATS_TEST_TMPDIR/uploaded"
    printf '%s\n' "CLAUDE_CONFIG_DIR=$CONFIG" "PATH=/usr/bin:/bin:/snap/bin:/snap/bin" > "$SYSTEMD_ENV"
    run env_check
    assert_failure
    assert_output_contains "env: the systemd user manager holds another PATH, so GUI apps and user services get /usr/bin:/bin:/snap/bin:/snap/bin"
    assert_output_contains "env: the systemd user manager does not hold UTILZ_INSTALL_PREFIX, so GUI apps and user services do not get it"
    refute_output_contains "CLAUDE_CONFIG_DIR, so"
    assert_output_contains "env: the desktop session set the manager's environment at login, so log out and back in after molt upgrade"
    refute_output_contains "set-environment"
}

@test "on Linux check reads the systemd user manager, and passes when it holds every pair as published (issue 0076)" {
    setup_env
    on_linux
    declare_moved
    env_install >/dev/null
    run env_check
    assert_success
    grep -qxF "<--user><show-environment>" "$SYSTEMCTL_LOG"
}

@test "on Linux check reports a systemd user manager it cannot read, and fails (issue 0076)" {
    setup_env
    on_linux
    declare_moved
    env_install >/dev/null
    export SYSTEMD_FAILS=1
    run env_check
    assert_failure
    assert_output_contains "env: systemctl --user show-environment failed: Failed to connect to bus: No medium found, so what GUI apps get is unknown"
}

# systemctl prints a value with whitespace or a character a shell reads as
# syntax in it as NAME=$'value' (systemctl(1)), so check reads the value back
# from that, and a prefix with a space in it is not taken for another.
@test "on Linux check reads back a value systemctl prints quoted, so a pair with a space in it passes (issue 0076)" {
    setup_env
    on_linux
    declare_moved
    echo 'export UTILZ_INSTALL_PREFIX="/opt/my tools (arm64)/utilz"' >> "$VARS"
    env_install >/dev/null
    grep -qxF "UTILZ_INSTALL_PREFIX=/opt/my tools (arm64)/utilz" "$HOME/.config/environment.d/molt.conf"
    export SYSTEMD_ENV="$BATS_TEST_TMPDIR/quoted"
    grep -v -e '^#' -e '^UTILZ_INSTALL_PREFIX=' "$HOME/.config/environment.d/molt.conf" > "$SYSTEMD_ENV"
    echo "UTILZ_INSTALL_PREFIX=\$'/opt/my tools (arm64)/utilz'" >> "$SYSTEMD_ENV"
    run env_check
    assert_success
    refute_output_contains "holds another"
}
