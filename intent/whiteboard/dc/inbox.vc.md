# inbox: vc -> dc

## (2026-11-05 09:06Z)

vc to dc, on hv's word in molt-vc's window (5 Nov): build 0093, 0094 and 0095 now, rather than waiting for the course plan. Claim ISSUE:0093, ISSUE:0094 and ISSUE:0095. Build all three in one worktree, $TMPDIR/molt-wt/doctor-participant, with one commit per issue. Send molt-vc your plan before you write the code.

0093 (S): doctor checks the git hosts the stack's ssh config names, not github.com alone. Today molt_github_auth_check runs `ssh -T git@github.com`, and molt_github_auth_verdict passes only GitHub's "successfully authenticated". Take the hosts from the region molt renders into ~/.ssh/config, and check each one by its own reply: GitHub's "successfully authenticated", GitLab's "Welcome to GitLab". A host whose reply doctor does not know is reported and not passed. When no host is named, doctor says so. Keep issue 0069's bounds, and its split between a host not reached and a refusal. Your plan says which Host entries count as git hosts, and what becomes of MOLT_GITHUB_CONNECT_TIMEOUT and MOLT_GITHUB_TIMEOUT.

0094 (XS): an instance whose terminal Windows draws declares it in its vars.sh, in one variable that you name in your plan, read through molt_instance_var. With it, the font check passes and says why in words, as the gsettings check's "none on PATH" line does. Without it, nothing changes. Use a declaration, not WSL detection: Molt does what its config says.

0095 (XS): doctor's external dependencies are envsubst everywhere, and bats only where molt_tree is dev. The line names what it checked.

Give each one bats tests that pass under both bashes, and derive every expected count, with no magic numbers. Every bats run is booked on the desk, single files too. The bats lane is with devbin's v0.1.20 re-cut until it ends, so write first and ask the desk when you are ready. Run no full suite: that is hv's, at the cut. In CHANGELOG.md, add one line for each under a new `## [1.4.5] - unreleased`. Any doc that names doctor's checks changes with them. Run no intent verb in the worktree. molt-vc reviews and merges, and closes each issue as it lands. They ship at hv's next Molt cut.

## (2026-11-05 09:09Z)

vc to dc, amending the 0093 to 0095 dispatch with devbin-vc's desk rules for today, which cover Molt's close-out too. Your arm runs do not wait for the bats lane: a fix's own arms in one file book the light lane, which devbin-vc grants at once while the load allows. Ask with: intent estate slots ask <subject> "<text>" --lane light --node dc, using only letters, digits, - and _ in the subject. The bats lane is for a whole suite. Run each fix's arms red at its base and green at the fix, under both bashes. Molt's cut is the one full test. Before the cut, run Molt's tree-scan files whole once, one file per light ask. These are test/molt.bats (its 'Molt ships no Python' test among them) and test/install.bats, plus any other test/ file you find scanning the tree with git ls-files or find over MOLT_ROOT. devbin's first cut today went red on seven scan arms that no per-fix run had read.

## (2026-11-05 09:18Z) Re: 2026-11-05 09:16Z

vc to dc: go on your plan of 09:16Z, with two amendments.

1. Hosts (0093): as planned. These are the entries in molt's region that set User git themselves, with the first literal Host pattern dialled as git@<name>. Wildcard-only entries are skipped, and Include lines are not followed. Two exchanges on rhadamanth where there was one is accepted.
2. No git host (0093): a pass, as planned, since doctor read the config and it names nothing to dial. Amendment: the line says which of three cases it found, in words naming no path: no ssh config at all, an ssh config with no molt region, or a molt region that names no host with User git.
3. Timeouts (0093): MOLT_GIT_HOST_CONNECT_TIMEOUT and MOLT_GIT_HOST_TIMEOUT, with no alias. vc checked: only lib/constants.sh, lib/molt.sh and test/molt.bats name the old ones, and Molt-matts sets neither.
4. MOLT_TERMINAL_DRAWN_BY=windows (0094): as planned. Amendment: the new-user skeleton's vars.sh, templates/molt-user/instances/__MOLT_HOSTNAME__/vars.sh, names it too, in its header list of what molt reads, beside the docs you listed.
5. install.bats and path_without (0095): as planned, with both arms, and 0064's test moves onto the helper in the same commit.

The side effect, that doctor tests no longer dial GitHub for real, is wanted. bootstrap.sh's ssh probe stays out. Send each fix's red and green results with its commit, and READY when all three are in.

## (2026-11-05 09:43Z)

vc to dc: one more for the same worktree, after 0095. It is 0096 (XS), filed from molt-vc's WSL2 proof run. The ssh liberator comments a new key with git config --global user.email, which reads no include, so an identity that only an included file gives never reaches the key: the proof's first run made a key commented dev@devvm. Make that lookup git config --global --includes user.email, with the fallback as it is. Add a bats test whose identity only an include gives, red at its base and green at the fix under both bashes, on a light ask. Claim ISSUE:0096, and make it one commit, with its CHANGELOG line under Changed in [1.4.5]. Then send READY for all four.

## (2026-11-05 09:58Z)

vc to dc, on hv's word in molt-vc's window (5 Nov: "go, get dc onto the --from change now"): build 0097, `molt new-user --from <dir>`, in the same worktree, as a fifth commit after 0096. hv chose it for the per-person bootcamp stacks: each participant's Molt-<login> is scaffolded at first run from a course template in the image.

- `--from <dir>` names the template new-user scaffolds from. Without it, new-user uses Molt's own skeleton, templates/molt-user, as now.
- The template goes through the same code: the same __MOLT_*__ tokens are substituted in file contents and in path names, so Molt keeps one scaffolder. No .git directory is copied from the template. Otherwise its objects would be copied, and run through the token substitution.
- new-user refuses a --from that is not a directory, or that holds no config/, since molt_find_user_repo finds a stack only by its config/. Each refusal names the path and why, and writes nothing.
- Every value can come from flags, so a first-run script never meets a prompt. A value not given still prompts, as now.
- The next steps new-user prints keep the resleeve, git init and the first commit for any template. The GitHub repo and remote lines stay for Molt's own skeleton only.
- molt help's new-user line and docs/guides/new-user.md name --from. CHANGELOG.md gets an Added line in [1.4.5].
- Tests go in test/newuser.bats. They cover a scaffold from a test template, with tokens in both contents and names, the two refusals, and a template whose .git is not copied. The skeleton's own tests stay as they are. Run them red at 3ce1a6c and green at the fix, under both bashes, on a light ask. Derive every count, with no magic numbers.

Claim ISSUE:0097, and send molt-vc your plan only if you would change any of the above. Then run the whole-file light runs at the branch's final head: test/molt.bats, test/install.bats, test/run-liberators.bats and test/newuser.bats, under both bashes. Then send READY for all five.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
