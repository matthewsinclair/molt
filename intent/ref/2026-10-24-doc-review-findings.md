# Doc review against the as-built code, 24 Oct 2026

hv asked ac on 24 Oct 2026 to review Molt's as-written docs against the as-built and planned code. ac read the docs in four read-only slices and checked every HIGH finding against the code itself. ac also spot-checked a sample of the MED and LOW findings, and each one held (A3, A5, C3, D12, D17). vc routes the findings to their owners (vc, 24 Oct). This file is the long form; the whiteboard carries a pointer to it. It records what was true at one commit, and it is not kept current.

## How to read it

- Code is cited at 370db34, with ST0008 WP05 (f4fdebc) as-built. cc's fix forward of WP05 landed after this was written, the code at 0ac702c and the docs at 52c73dd:
  - it settles (1), (2), (4) and (7), B2 and C1, and C2's rows now hold;
  - D16's all-or-nothing point is gone, and the rest of D16 stands, with C9-C12 and C14.
- "held" marks text in 9c418e2, the brew-first install docs that 282e3a6 holds back until the tap is published. Fix it before that text returns. For the runbook, line numbers are as at 9c418e2; on main, every line after the held "Molt itself" section sits lower by that section's length.
- Severity: HIGH means following the doc fails, misleads into a wrong or harmful step, or names something that does not exist. MED means wrong but harmless, or a missing behaviour. LOW is wording or a house rule.
- Findings sent to vc before this report, numbered as vc routed them:
  - (1) claude moves the state before refusing a missing env.
  - (2) env's all-or-nothing publish. vc ruled that each pair stands alone.
  - (3) the bootstrap cloned lowercase molt, fixed as issue 0049.
  - (4) agent.sh calls the removed molt_claude_env_file.
  - (5) the bootstrap's read under curl | bash, fixed as issue 0050.
  - (6) molt.toml.example's missing terminal liberator, fixed as issue 0051.
  - (7) env publishes a changed config dir that claude refused.

## README.md

- A1 HIGH (checked) :175: says the claude liberator writes env.sh and the GUI env (environment.d/claude.conf). Since f4fdebc the env liberator writes them, as com.molt.env.plist or environment.d/molt.conf, and needs env after claude. It needs ~/.local/bin first on a login PATH too, or that pair is refused.
- A2 HIGH (checked) :50 and :56 clone into "$MOLT_PRJ_DIR/molt" and put its bin on PATH. The dev tree is $MOLT_PRJ_DIR/Molt (issue 0049 fixed the bootstrap). getting-started on main has the same clone at :30 and the same PATH at :41.
- A3 MED (checked) :91, :163 and :196 say ~/bin. The bootstrap links ~/.local/bin/molt, and MOLT_LOCAL_BIN defaults to ~/.local/bin (lib/constants.sh:85). getting-started on main says the same at :88.
- A4 MED :193-219: the liberator table has no env row.
- A5 MED (checked) :311-315: calls bats "optional, for molt test" and leaves out envsubst. Doctor requires both in every tree (lib/molt.sh:1922-1934). getting-started's prerequisites (:8-14) leave out bats. Or make bats required in a dev tree only, which is a code change.
- A6 MED: no prerequisite gives `timeout`. Doctor's GitHub check (lib/molt.sh:1963) and the bootstrap (:76) run `timeout 5 ssh -T`. Stock macOS has no timeout, so doctor reports "not authenticated".
- A7 MED :55-56: with the checkout's bin first on PATH, doctor's shadow check of ~/.local/bin/molt fails. Put ~/.local/bin first and run the checkout's molt by path once.
- A8 MED :88-91: the bootstrap clones MOLT_REPO (default matthewsinclair/molt) and $MOLT_USER_GH/molt-$(whoami), so say so. new-user's flynn example (GitHub flynn-sinclair) fails without MOLT_USER_GH.
- A9 MED, at the cut :34-91: install is clone or bootstrap. After the release it is brew first, as the held getting-started says.
- A10 LOW :112-113: upgrade's "Pull latest framework" holds only in dev. opt names molt install --force, and brew runs update, outdated and upgrade.
- A11 LOW :109-135: the CLI list has no molt install or molt use, and molt test runs in dev only.
- A12 LOW :231-233: the example's [sleeve] hostname and projects_dir are read by nothing. Only doctor reads [stack] user_repo.
- A19 LOW :187: the install exceptions leave out editors' Doom Emacs and LazyVim clones.
- A20 LOW :299-307: the structure has no tools/, packaging/ or docs/blog/.
- A21 LOW :330: the sleeves in use leave out farcaster and pihole.
- A22 LOW, count, borderline :19: "Two-repo model" is a named concept with a linked anchor.
- B27 LOW: :5-6, :10-11 and :26-27 are wrapped by hand.

## getting-started.md

- A5, A6, A2, A3 and A7 apply on main, as above.
- A23 LOW: the step headings are numbered ("## 1. Set MOLT_PRJ_DIR" onwards on main). The held text's :153 links #1-install-molt.
- A24 LOW :5-6: the blockquote is wrapped by hand, on main and held.
- Held only, before 9c418e2 returns:
  - A13: :23 eg `molt 0.3.0 (brew, 905305c1a2b3)` names a version hv has not named and a sha that is no commit. Use placeholders.
  - A14: :176 should say resleeve also replaces a broken link.
  - A15: :176 says doctor "fails"; doctor marks the check not passed and exits 0.
  - A16: :125 says doctor checks the directory structure; that holds in dev only, and opt and brew check the manifest.
  - A22: :155 "three trees" is a count.

## new-user.md

- A17 LOW :49: the tree root is molt-flynn/, but the code makes Molt-flynn.
- A18 LOW :18: --dest is never prompted for.
- A22 LOW: :68 "Two kinds of placeholder" and :70 "two distinct delimiter styles" are counts.

## bootstrap-runbook.md

- B3 MED, held :52: "cloned by bin/bootstrap.sh, which still sets one up". Issue 0049 now makes the bootstrap clone Molt, so name $MOLT_PRJ_DIR/Molt.
- B8 MED :22-29: the two liberator lists leave out env.
- B9 MED :5 and :31-32 call it "the specification for what the liberators automate". The system, zsh, git, alacritty and dev-tools liberators check for packages and name the install; they install none.
- B10 MED :252, :274 and :276-279:
  - keys copies the keyd config through sudo and reloads keyd;
  - desktop sets each gsettings key and reads it back, sets the dock, and links gtk.css into gtk-3.0 and gtk-4.0.
- B11 MED :115 and the table at :367-381: alacritty and starship render from a .tmpl. Rows are missing for gitignore_global, gitconfig_<name>, gtk.css, and claude's CLAUDE.md and AGENTS.md.
- B12 MED :352-363: the claude section leaves out the CLAUDE.md and AGENTS.md links, and the config-dir move, repoint, guard and hook. env publishes after claude.
- B13 MED :307-313 says "keys are not managed", but ssh generates a passphrase-less ~/.ssh/id_ed25519 when there is none.
- B17 LOW, held :38-44: the brew block alone fails without MOLT_PRJ_DIR and a config repo.
- B18 LOW, held :46: names 0.3.0 and a sha that is no commit.
- B20 LOW: :15 says "Current as at 2026-09-08". :223 and :397 cite 6e99b17, which is in neither repo; the change is Molt-matts 25713b0.
- B21 LOW: the runbook writes molt-{user} throughout; the directory is Molt-{user}.
- B22 LOW: :123-124, :188 and :344 hold stale Molt-matts enumerations (the functions list, "through 150-corfu", "Intent added to PATH").
- B26 LOW, count and position: "the two lists", "step 1.2", and the numbered headings.
- B27 LOW: hand-wrapped paragraphs throughout.

## templates.md

- B14 MED :139-148: the instance table has no row for instances/<host>/agents/<role>.md (the overlay) or for instance.toml [terminal] colours (zsh builds iterm2-ssh-colors.sh).
- B15 MED :148: gsettings skips only lines starting with #; a later # is part of the value.
- B16 MED :87 and :132-137: an existing symlink target is removed, never backed up, and 600 applies only where the parent is 700.
- B19 LOW :30-61 and :95-99: the font values are wrong, the tmux example links rather than renders, and the ssh examples leave out the fragments ssh passes in.
- B24 LOW :42: vars.sh is also read for MOLT_INSTALL_PREFIX, MOLT_CLAUDE_CONFIG_DIR and MOLT_FONT_FAMILY, and env publishes every \*\_INSTALL_PREFIX.

## templates/: the new-user skeleton and the example

- B2 MED: the skeleton's molt.toml has no env entry. cc's fix forward touches this file.
- B4 MED, molt-user README.md:14-20:
  - git refuses without git-lfs, which the skeleton's gitconfig requires;
  - ssh renders only with envsubst;
  - ssh makes a passphrase-less key when there is none;
  - the repo is found only as Molt-$(whoami).
- B5 MED, molt.toml.example:4-5 says "everything is listed, toggle". A manifest runs only what it lists. One that enables nothing for the platform runs every liberator, keys' sudo build of keyd on Linux included, which is a code question too.
- B6 MED, molt.toml.example:
  - :10 user_repo is lowercase, so doctor warns;
  - :12-15 the [sleeve] keys are read by nothing;
  - :80-81 says utilz links "into ~/bin".
- B7 MED, the skeleton molt.toml:14-16 and :38, and the README:22, group liberators by "need no extra config". What stops one is a missing tool, not missing config.
- B23 LOW, the skeleton instance.toml:9-12: the zsh liberator builds the ssh-colour wrapper, and the skeleton ships zsh disabled.
- B24 LOW, the skeleton vars.sh:2-3 "Sourced by molt_render": as for templates.md.
- B25 LOW, molt-user README.md:10-11 "dotfiles linked": ssh renders its config.

## sleeve-agents.md

C1, C2 and C4 are with cc already, as (1), (2), (4) and (7).

- C1 HIGH (checked), doc :304, :308 and :312: until cc's fix lands, say that a missing or refused env leaves the state moved and unpublished, and to fix the cause and resleeve before starting any Claude.
- C2 HIGH (checked), doc :270 and :278: the changed-dir rows say it is not published. Recheck them against cc's fix for (7).
- C3 MED (checked) :230: says pgrep failure warns and starts anyway. Code refuses (lib/agent.sh:704-706), and test/liberators/agents.bats:796-802 expects the refusal.
- C5 MED :178 and :181-198: the config sample has no guard row, and its managed layer and Bash rules are not kovacs-sysadm's.
- C6 MED :482: the sandbox-profile sentence contradicts the first install, which replaces the distro's file and keeps it as .molt-orig.
- C7 MED :334 says hooks come "once the variable is published":
  - homes get the hook once the config dir is declared, but the guard script only after the move;
  - the user settings get the hook once the state is in place.
- C8 MED :216-228: the start refusals have no row for harness, for no molt.toml, or for unreadable entries. Drop the role clause, which cannot be reached.
- C9 MED :358-378: the doctor tables predate env. Row 372 now holds for the hook script only. The env lines and claude's env-unlisted line are missing.
- C10 MED :248: an undeclared sleeve does get env.sh and a GUI file wherever env runs.
- C11 MED :306, and the message quoted at :267, say "no env.sh or GUI file was written". env runs after claude regardless and publishes the other pairs. The code's message needs rewording too (cc).
- C12 MED :312 and CHANGELOG:13 say "must enable env, after claude". Only env's presence is checked, not its order, and only where the config dir is declared.
- C13 MED :488: the floor's fleet status is stale. rhadamanth and gyges declare the dir and enable sysadm, and the floor follows the declaration, not the move.
- C14 LOW :312, :316 and :318: on Linux, molt.conf's PATH reaches terminals too. The rows leave out PATH and the prefixes, and MOLT\_ prefixes are left out of publishing.
- C15 LOW :326: the env and GUI files also hold values, the prefixes and the login PATH.
- C16 LOW :24: gyges-infra "becomes gyges-sysadm when gyges is moved", but gyges declared on 23 Oct (Molt-matts 4f78dba). Confirm the live session name before rewording.
- C17 LOW, counts: :423, :425, :427, :486, :490 and :504.
- C18 LOW :118: vars.sh "must not set" MOLT_AGT_DIR should say "must not change".
- C19 LOW :118: the example can't happen without a symlink.
- C20 LOW :114: a molt.toml that names no liberators runs every liberator, agents included.
- C21 LOW :28: the host list leaves out pihole.
- C22 LOW :144: only a file edited since it was rendered is backed up.
- C23 LOW :260-280 and :298: some move refusals and the jq-regex line are missing.
- C24 LOW :282: a repointed path becomes absolute when the config dir is outside $HOME, and only paths at a boundary count.
- C25 LOW :425: run sandbox-creds.sh from a dev checkout, since opt and brew ship no test/.

## writing-a-liberator.md

- D1 HIGH (checked) :188-202 and :177: the dock example calls bare gsettings, which the guide's own row at :147 forbids (issue 0047). Use molt_gsettings_unreachable, then molt_gsettings, as vscode does.
- D2 HIGH (checked) :102-106: the example install calls molt_link without `|| return 1`. resleeve runs install inside an `if`, where set -e does not apply, so a failed link reports "installed".
- D3 HIGH (checked) :206 says "HOME-sandboxed bats test infrastructure", but test/test_helper.bash never sets HOME. A test that runs a liberator's install must export HOME into BATS_TEST_TMPDIR, as zsh.bats's \_zsh_env does.
- D4 HIGH :7, :29, :158 and :204-206 never say which tree. In opt and brew, liberators/ is a published copy:
  - a new file there is "not in the manifest";
  - molt install --force or brew upgrade replaces it;
  - molt test refuses outside dev.

  Say to write and test in the dev tree and commit before publishing.

- D7 MED :5-29 never says what shell a liberator runs in: sourced under set -euo pipefail, and every hook is called inside a condition. That means:
  - set -e never stops a hook;
  - set -u ends the run, silently in resleeve, list and status;
  - pipefail turns `grep -q` into a failure;
  - on bash 3.2 an empty "${a[@]}" is fatal.
- D8 MED :152-154: molt_error goes to stderr as "Zen [error]:"; info and warn go to stdout; molt_debug prints only with MOLT_DEBUG=1. resleeve drops a check's stderr.
- D9 MED :60 and :138-139: molt_config_stale takes source, target and inputs, the source repo-relative and without .tmpl, and looks only in the user repo. A template Molt ships uses molt_render_stale.
- D10 MED :62, :84-85 and :117-118: molt_link_healthy passes a link to the wrong file. Use molt_report_link_faults and molt_link_all over one link list, as git does.
- D11 MED :31-46: the optional `{name}_repo` and `{name}_repo_git_commands`, which molt git reads, are missing.
- D12 MED (checked) :150-151: molt_distro prints none off Linux and unknown without os-release, never macos. molt_arch prints amd64, not x86_64. molt_platform can print unknown.
- D13 MED :129-154: the helper table leaves out molt_instance_var, molt_claude_config_dir, molt_sudo_install and molt_sudo_remove, molt_git_pull, molt_tilde, MOLT_LOCAL_BIN for executables, and $MOLT_ROOT/templates.
- D14 MED :204-206: Testing is one line. It should cover:
  - molt test <name>, which runs shellcheck first and runs no tests while shellcheck finds anything;
  - /bin/bash 3.2;
  - each test starting with no gsettings (gsettings_from_path);
  - test_hostname, not molt_hostname;
  - fake_brew_formula and install_fake_sudo.
- D23 LOW :7-29:
  - doctor finds `^<name>_check()` by that text;
  - the file must be liberators/<name>.sh;
  - \_check runs for status and list too.
- D24 LOW :158: "add it to your molt.toml" should say instances/<host>/molt.toml when there is one.
- D25 LOW :117-121: the example verify checks the link even where check and install skip it.
- D26 LOW: the guide says nothing about publishing a variable. Since WP05 a liberator adds a contributor to the env liberator and never writes zshenv, a LaunchAgent or an environment.d file.

## CHANGELOG.md

- D5 HIGH (checked) :8-25: Unreleased has nothing for ST0008 WP01-04 and the conformance (5bf482a, 3add4f8, 96ae9e4, 82266c1, ca040c1).
  - Added: molt install; molt use; the version line from molt version and --version; the formula template and tools/formula.
  - Changed: MOLT_LOCAL_BIN's default moves from ~/bin to ~/.local/bin, so Molt's link moves where the two differ (kovacs); upgrade by tree; molt test in dev only; local-bin keeps the link molt use set; doctor checks the tree, its manifest and the PATH shadow.
- D15 MED: entries are missing for:
  - issue 0047 (gsettings that reaches dconf, and doctor's gsettings check);
  - 0043 (desktop fails over files no gsettings can apply);
  - 0045 (a jq without regex support named as that);
  - 0048 (vscode links code into MOLT_LOCAL_BIN);
  - 0044, under Removed (molt_instance_vars_file gone, molt_instance_file added).
- D16 MED :13, the WP05 entry:
  - the env-unlisted fault fires only where the config dir is declared, the order is not checked, and install fails as well as check;
  - the publish is all-or-nothing as committed, which changes with cc's fix;
  - MOLT\_ prefixes are left out;
  - Removed should list molt_claude_env_file.
- D17 MED (checked) :220: [0.1.0] is dated 2025-01-01; tag v0.1.0's commit is 2026-03-12.
- D19 LOW :17: only this sleeve's own bg_color goes into the wrapper; every instance's ssh_bg_color does.
- D20 LOW :77 and :116: \_molt_liberator_entries never shipped in a tag; v0.2.0 has \_molt_table_entries.
- D21 LOW, counts: :59, :64, :70-72, :74, :77, :85, :94, :106, :130, :135, :145-146, :166, :168, :170, :177, :191, :200 and :226 (eg "17 built-in liberators", "6 new bats tests").
- D22 LOW: :5-6 are wrapped by hand, blank lines split lists at :19, :75, :81, :107, :109 and :123, and there are no Keep a Changelog link references.

## usage-rules.md

Intent-seeded and never refreshed; its project section is empty.

- D6 HIGH (checked):
  - :66 and :80 name .git/hooks/pre-commit and bin/intent_critic. Neither exists. The gate is .githooks/pre-commit through core.hooksPath, running `intent critic shell` through Intent's gate.
  - :5 and :52 name ~/.intent/ext/ and `intent ext`, which are not built in v3.
- D18 MED :5 and :54-62: "Intent v2.10.0" (config.json says 3.1.0), and the settings.json wiring as described is stale.
- D27 LOW :25 and :66: the template placeholder [[LANG]] is still there.

## Notes and stubs

- docs/notes/tn0001-molt-and-conflab.md is a design note, not built. There is no drift, but D28 LOW: :3-5 and :81-83 join into one paragraph.
- intent/docs/technical_product_design.md is an unfilled stub, so there is nothing to drift.

## Code notes, outside the docs

- liberators/brew.sh:52-82: brew_maintain runs update, upgrade and cleanup unchecked and ends with molt_info, so a failed brew upgrade returns 0.
- lib/liberator.sh:114-137: liberator_has_repo and liberator_repo have no caller outside test/git.bats.
- f4fdebc changed liberators/claude.sh's mode from 755 to 644. That is harmless, since liberators are sourced.
- Doctor's PATH-shadow check counts as not passed, but doctor exits 0 (A15), and ST0008 D3 says doctor fails. Code or doc, vc's call.
- molt_resleeve with a manifest that enables nothing for the platform runs every liberator (B5).

## The blog brief

docs/blog/bl0001 is ac's. It matched the as-built code at 155486f and followed WP05 at 1cc3a31. Its env-writer bullet gets a recheck when cc's fix forward lands.
