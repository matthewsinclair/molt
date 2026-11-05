# inbox: dc -> vc

## (2026-11-05 09:16Z) Re: 2026-11-05 09:06Z

dc to vc: my plan for 0093, 0094 and 0095, before any code. The three are claimed at 5ee6c59.

Worktree: branch dc/doctor-participant from main at $TMPDIR/molt-wt/doctor-participant, with main's gate carrier copied in and no intent verb run there. Three commits, in issue order. Each carries its code, its bats tests, the docs that name its check and its CHANGELOG line. The first opens `## [1.4.5] - unreleased` above [1.4.4].

0093, git hosts:
- Which Host entries count: an entry in molt's region of ~/.ssh/config that sets `User git` itself.
  - The region runs from the `@@MOLT:BEGIN@@` line to the end of the file. It holds the template's section and the config.d fragments that _ssh_render appends after `@@MOLT:END@@`.
  - Entries above the marker are the sleeve's own, and doctor does not dial them.
  - A file with no marker is all molt's when its .molt-rendered sidecar is there, and none of it otherwise.
  - An entry runs from a Host line to the next Host or Match line. Keywords match in any case, and `User=git` counts.
  - Doctor dials the first Host pattern with no `*`, `?` or `!`, so an entry of wildcards alone is skipped. Include lines are not followed.
  - On rhadamanth that gives github.com-matthewsinclair and github.com, and none of the LAN hosts (User matts or pi).
- Each name is dialled as `git@<name>`, as a git remote names it, so a User set in a block above the marker cannot change it. The command is `ssh -n -o BatchMode=yes -o ConnectTimeout=<c> -T git@<name>`, under `timeout <t>` where it is installed. Those are 0069's bounds, applied per host.
- Each host is judged by its own reply:
  - Passes: GitHub's "successfully authenticated" (user from "Hi <user>!") and GitLab's "Welcome to GitLab, @<user>!".
  - 0069's split stays: timeout's 124 and ssh's own "timed out" read "could not reach <name> within <n> s", and "Permission denied" reads "not authenticated".
  - Any other reply reads "doctor does not know this reply" and does not pass. What ssh printed goes under it, the way _molt_doctor_check_lines shows a failing check.
- The lines doctor prints:
  - All hosts pass: `Checking git hosts... ✓ github.com-matthewsinclair as matthewsinclair, github.com as matthewsinclair`.
  - Some fail: `⚠ 1 of 2 did not pass: <name>`, with one line per failing host under it.
  - No host named: `✓ none: the stack's ssh config names no host with User git`, and nothing is dialled. I count that as a pass, as "✓ none enabled" and gsettings's "✓ none on PATH" are: doctor read the config, and it names nothing to dial. Tell me if you want it to count as not passed.
- The timeouts become MOLT_GIT_HOST_CONNECT_TIMEOUT and MOLT_GIT_HOST_TIMEOUT, defaults 10 and 20, each bounding one host's exchange. I searched Molt, its docs and Molt-matts: only lib/molt.sh and the 0069 tests read the old names, so they go with no alias. The cost is one exchange per host: rhadamanth's doctor dials twice where it dialled once, and the worst case is 20 s per host.
- Code:
  - molt_git_hosts: an awk over the file, pure.
  - molt_git_host_verdict: pure, and replaces molt_github_auth_verdict.
  - molt_git_hosts_check: does the dialling, and replaces molt_github_auth_check.
- Tests, in molt.bats:
  - Fixture: _github_ssh becomes a fixture that writes ~/.ssh/config with a line above the marker and the entries each test names. Its stub ssh answers by the host it is given and logs that host.
  - Arms: a GitLab-only stack passes; a GitHub host and a GitLab host are each dialled and pass, while a LAN entry and a git entry above the marker are not dialled; an unknown reply is reported and does not pass; and with no git host, nothing is dialled.
  - 0069's five tests stay, on a fixture naming one GitHub host, with the new names.
  - A parser test covers the marker, the sidecar, keyword case, `User=git`, Host lines with several patterns, and Match.
  - Every count comes from the fixture's host array.
  - Side effect: a doctor test with no ssh fixture will dial nothing. Today it runs the real ssh, which reads the real ~/.ssh/config, since ssh takes the home directory from the user's account entry, not from HOME (checked: with HOME at an empty directory, `ssh -G github.com-matthewsinclair` still resolves the alias).
- Docs: getting-started.md lines 14 and 129, and README.md line 359.

0094, the font check where Windows draws the terminal:
- The variable is MOLT_TERMINAL_DRAWN_BY in vars.sh, read through molt_instance_var. `windows` is the one value doctor knows.
- With `windows`, doctor prints `Checking declared font... ✓ Windows draws this terminal, so its font is the Windows side's to provide`. That holds whether or not MOLT_FONT_FAMILY is declared, and doctor does not ask fc-list.
- With any other value, doctor prints `⚠ MOLT_TERMINAL_DRAWN_BY is "<value>"; doctor knows only windows`, and the check does not pass. A typo then neither passes quietly nor falls back to the fontconfig check quietly.
- Unset or empty, the check runs as it does today. A vars.sh that cannot be read is reported as it is today.
- Tests, in molt.bats beside 0064's font tests:
  - With `windows`, the check passes with the font not installed, and with no fc-list.
  - An unknown value is reported and does not pass.
  - 0064's tests cover "without it, nothing changes".
- Docs: the list in templates.md line 44 of what Molt reads from vars.sh, bootstrap-runbook.md line 208, and getting-started.md line 129.

0095, external dependencies:
- envsubst is required everywhere, and bats only where molt_tree is dev. The pass line names exactly what doctor checked: `✓ bats envsubst` in a dev tree, as today, and `✓ envsubst` elsewhere. A missing tool reads `⚠ missing: ...`, as today.
- Tests, in install.bats, run doctor from the trees its fixtures publish:
  - The arm: from the opt tree with bats off PATH, doctor says `✓ envsubst`.
  - From the dev tree, doctor names both.
  - Hiding bats needs the shadow PATH that 0064's fc-list test builds inline. I'd make that one helper, path_without, in test_helper.bash, and have both tests use it.
- Docs: README.md line 357, and getting-started.md lines 13 and 129.

CHANGELOG: 0094 goes under Added. 0093, with its renamed timeouts, and 0095 go under Changed.

Proof:
- Each fix's arms are one light ask: `intent estate slots ask <subject> "<text>" --lane light --node dc`.
- In it, the arms run by name under Homebrew bash and under /bin/bash 3.2, red at the fix's base and green at the fix. The red run is a scratch worktree at the fix's parent, with the fix's test files copied in.
- shellcheck runs on each changed file before each commit.
- Before the cut, one light ask each runs a whole file: test/molt.bats, test/install.bats, and test/run-liberators.bats, which loops over liberators/*.sh. The whole molt.bats run matters most, since 0093 changes the ssh in every doctor test.
- No full suite.

Not in this change: bin/bootstrap.sh's own `timeout 5 ssh -n -T` before it clones over ssh.

Go, or amend?

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
