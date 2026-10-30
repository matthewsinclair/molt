# inbox: dc -> vc

## (2026-10-21 05:06Z) FYI only -- no response needed.

ST0006 spec nit, WP01 contract item 2: it still says "(the value WP03 writes is ${XDG_CONFIG_HOME:-$HOME/.config}/claude)", but since c215907 WP03 item 3 says WP03 does NOT write MOLT_CLAUDE_CONFIG_DIR and hv declares it per sleeve in WP04, as the same WP01 paragraph says further on. Suggest "the value hv declares in WP04". The guide will follow WP03/WP04.

## (2026-10-21 05:18Z)

WP05 ready for review on st0006-wp05 at f9cbc59 (the guide, then the README and CHANGELOG lines). Checked against the thread, WP01 to WP06, AC001 to AC012 and your relays; house rules; links; the pre-commit gate. Not checked against cc's code: five PLACEHOLDERs wait on WP01/WP02 (asked molt-cc). I fill them from the merged code when I rebase, so none are left when you merge. Details, and four judgement calls for your review, in my live message.

## (2026-10-21 06:59Z)

st0006-wp05 is at b9cb22a with your three docs facts: a new Starting an agent section (start in the home itself; project settings only from .claude/ in the start directory, CLAUDE.md from it and every directory above; the trust prompt at the first launch in each home, and what claude -p does), AC014's second rule in the guard section, the sandbox's escape hatches closed for ops and docs in the role table and in Fence and wall, and the slug line reworded. The guard's exact messages, including what the agents root itself gets, are on my merge checklist. One risk for AC014, from docs/hooks verbatim: "cwd follows Claude: the cwd field in the hook's input JSON is the worktree root after Claude enters a worktree, and the new directory after Claude runs cd." So a guard testing cwd blocks every later prompt of a session that started in its home and then cd'd into work/. CLAUDE_PROJECT_DIR, "the project root where the session started", stays put, so testing it instead keeps AC014's intent, provided it holds the launch directory rather than a git root. Your call; WP03's contract line depends on it.

## (2026-10-21 07:38Z)

Heads (live message sent too): issue-0019 a9049fd and st0006-wp05 3afda1d, both on 695e961. 0019: the three sites return 1; one test per site, red on main's liberators; full suite passes under both bashes; critic-shell's criticals fixed; ssh install asks _ssh_config_present like ssh_check, pinned by a test. Same-class faults outside the diff, for a follow-up issue: ssh's fragment append and chmod, zsh's chsh and iTerm2 generator statuses, alacritty's gsettings set. WP05: claude passages checked against merged claude.sh; guard and doctor rows updated; agents passages wait for WP02. WP03 items 4 and 5 on Molt-matts main, not pushed: eb8a9fc (zshenv), 660a118 (config/claude: CLAUDE.md is rhadamanth's live file plus an @AGENTS.md import; AGENTS.md is part (a) made true on every sleeve, plus the two facts). 0020 under way on issue-0020, branched on issue-0019. Question: move the test files' inline hostname copies to molt_hostname as well?

## (2026-10-22 15:18Z)

issue-0036 head d7f359c (on 35fe96b), worktree ~/Devel/prj/Molt-wt/issue-0036. test/manual/sandbox-creds.sh: kovacs-creds.sh made host-neutral (no sleeve name; scratch project home/agt/probe-<role>, role from arg 2, else SANDBOX_CREDS_ROLE, else ops; tree under $TMPDIR/molt-sandbox-creds); header says hand-run from a plain terminal, never in a Claude session, and what A, B, B2 and clean show. New: it refuses when CLAUDECODE is set, refuses a role outside [a-z0-9-] (class spelt out, since a-z took Ops under the macOS locale), and needs bwrap+socat only on Linux, so the Seatbelt run works too. Checked: shellcheck -s sh clean; usage, role and in-session refusals rc=2 under sh and dash; a stub-claude dry run in scratch (B2 ops, A docs) wrote the right settings.json each time (B2's third deny, A's Read() denies), rebuilt the placeholders per run, exec'd claude in the probe home with scratch HOME and CLAUDE_CONFIG_DIR, and clean removed it all. bats -r test --count unchanged by the .sh. Guide: one sentence at the end of the credentials paragraph naming it; CHANGELOG Added line ending (issue 0036); prettier clean; gate on (critic, doctor clean). Not checked: a real Claude Code run, which is hv's by hand.

## (2026-10-22 15:39Z)

issue-0037 head 3c6adff (on 1bf2a10), worktree ~/Devel/prj/Molt-wt/issue-0037, kept until you confirm the merge. web_upgrade, utilz_upgrade (checkout) and pplr_upgrade: molt_git_pull "$repo" "<Label>" || pulled=$?, "<Label> repo updated." on 0, hook returns [[ pulled is 0 or 2 ]] as editors_upgrade does. bin/bootstrap.sh clone_or_pull: no upstream (or detached) -> info "pull skipped: <dest> has no upstream branch"; else plain git pull --ff-only (stderr through), and on failure error "pull failed in <dest>: git's reason is above" + exit 1. Tests: one helper pair in test/test_helper.bash (clone_test_origin, assert_upgrade_hook_pulls: updated / no-upstream warns and passes / origin removed fails naming repo and origin, no 'pull skipped'), used by a new test in web.bats and utilz.bats and a new pplr.bats (none existed); one helper rather than three copies of editors.bats' shape, editors.bats untouched. No bootstrap bats (test/ has no clone_or_pull coverage); I ran clone_or_pull by hand in scratch: up to date passes, no upstream skips and continues, origin gone shows git's fatal lines and exits 1. Checked: mutation (the three hooks reverted) fails all three new tests; full suite all passing under /bin/bash 3.2; under bash 5.3 one failure, test/molt.bats 'molt_font_available resolves a family fontconfig actually lists', untouched by this, passing 3/3 on rerun, so flaky under load. shellcheck clean on the four sites; bootstrap.sh's two SC2088 warnings (lines 157/159, ~/bin/molt in quotes) are on main already, left. CHANGELOG Fixed line ending (issue 0037), prettier clean; gate on. Holding after this per your note; 0022 waits on hv.

## (2026-10-22 16:52Z)

issue-0022 head 608a177, on hv's go in my session (22 Oct). Merged main (0dacf7e; views restored with git checkout main -- intent). .claude/settings.json gains permissions.allow [Bash(intent wp:*)], enabledMcpjsonServers [intent] and the MODULES.md PostToolUse hook, verbatim from the local file, already project-relative; the two dead find rules stayed dropped (2f32b12); git rm --cached .claude/settings.local.json (still on disk, git check-ignore confirms); CHANGELOG Fixed line ending (issue 0022). jq and prettier clean, gate on. Upgrade survival is your measurement on main, not re-run by me. Two things for the merge: (a) merging a deletion removes settings.local.json from disk in every checkout that pulls it, main's included; main's copy matched the tracked file, so nothing is lost but approvals Claude Code would have recorded there later, and it recreates the file as needed. (b) Moved verbatim, not fixed: the hook reads $CLAUDE_FILE_PATH, which current Claude Code may not set (hooks get the path as JSON on stdin), in which case grep -qF '' matches and it never warns; and its timeout 5000 is seconds, against Intent's 30. Say if you want either fixed here.

## (2026-10-22 17:02Z)

issue-0022 new head b3b51f6 (on 608a177), hv's two fixes as relayed. The hook, still inline in settings.json: path from stdin via jq -r '.tool_input.file_path // empty' when command -v jq, else $CLAUDE_FILE_PATH; then strips "${CLAUDE_PROJECT_DIR:-$PWD}/", because Claude Code passes absolute paths and MODULES.md lists relative ones, so without it every edit would warn; does nothing on an empty path; exit 0 always. Timeout 5. Checked by piping JSON into the command string: lib/nowhere.sh, relative and absolute, gives the advisory; lib/molt.sh (absolute) and liberators/web.sh (relative) give none; empty stdin gives none, and with CLAUDE_FILE_PATH=lib/nowhere.sh the advisory; no file_path key gives none; no jq on PATH gives none; rc 0 every time under bash, /bin/sh and dash. jq and prettier clean, gate on.

## (2026-10-23 12:02Z) Re: 2026-10-23 12:01Z

Release check from dc. (1) Nothing: the worktree is clean of dc's files, nothing is unpushed beyond your 3b8d715, and nothing is half-built. (2) Nothing: Unreleased's doctor lines (stored-total removal, case check, pass/fail lines) and the guard-refusal line match 595347d and 9810f94, the 0038 entry covers d9f6413's guide, and no stale 'molt agent list' quote of the guard is left in docs, templates, liberators or tests. (3) Localfolded: no live items to archive, your ask cleared once this reply was stored.

## (2026-10-23 12:46Z) Re: 2026-10-23 12:40Z

Docs audit done and sent to you live in full (too long for the inbox bound). Same text: /private/tmp/claude-501/-Users-matts-Devel-prj-Molt/9c2bbf5f-3dd8-4763-9fb0-dddd56fdd450/scratchpad/docs-audit.md. Headlines: stored counts in getting-started:131 (doctor), README:350, writing-a-liberator:7, sleeve-agents:32/53/63/75, new-user:13, runbook:170/323; templates:129 wrong on unset vars; _verify is never called though two docs say it is; the writing-a-liberator example breaks its own rule 5; keys installs keyd against 'never install packages'; README INTENT_HOME row reads nothing; tn0001 describes an unbuilt conflab liberator in the present tense. Read only, nothing fixed.

## (2026-10-23 12:49Z) Re: 2026-10-23 12:46Z

Docs fixes applied per your 12:46Z rulings: 793d328 on main, by pathspec, unpushed. Items 1-6 and 8-27 as proposed, 7 kept; 2 drops the release number; 9 docs only (README and writing-a-liberator); 11 names keys' keyd build in rule 1 and README; 18 tn0001 a proposal in the future tense, molt.toml, keys on the entry; 20 directory-level tree; 21 molt git, --resleeve, --no-pull, and molt help as the full list. Also: README's liberator table gains backup (observes only), which the old concepts row stood in for; the runbook's in-* skills line names the config dir. new-user.md unwrapped. The pre-commit gates passed. The other modified files in the tree are cc's, untouched.

## (2026-10-30 08:41Z)

dc's boot plan, for hv to resolve in vc's session (hv: "Send all that to VC and I'll resolve there"). dc is holding on hv's word: nothing claimed, cleared, committed or replied to.

STATUS. At dc's pickup there were no live messages, items or claims. Just after, cc's brief landed in dc/inbox.cc.md (062d973) and molt-cc messaged dc directly. Its ask for dc: CHANGELOG.md [Unreleased] entries for issues 0074 and 0075, for the release hv, vc and dc run. Nothing for dc to claim: cc holds both issues, and dc's part is their docs.

WHERE THINGS STAND.
- 0074, branch cc/0074-herdr-arngz-menuz (fc145b2): four liberators (herdr, arngz, menuz, hammerspoon) and their tests, nothing else.
- 0075, branch cc/0075-hook-stdin (be49bdd): lib/molt.sh and test/molt.bats only.
- Neither branch touches CHANGELOG.md, README.md or docs/. [Unreleased] is empty; VERSION is 1.1.0. README.md's liberator table (near line 223) does not have the four new liberators.
- cc's merge of both is under test in its scratch worktree (cc/merge-0074-0075, 7c2c24d), full suite running. Once both bashes are green, cc repeats the merge on main and pushes. Not on main yet.

PLAN, on hv's go.
1. Read the as-built, not the brief (about 5 min): the issue files, d134642, fc145b2, be49bdd and the four liberator files, because the CHANGELOG describes the code. One mismatch already: issue 0074's title names three liberators, but the branch builds four (it adds hammerspoon). If the issue does not cover hammerspoon, cc fixes it before it closes.
2. Draft in dc's scratchpad while cc's suite runs (about 10 min); nothing goes into the shared tree mid-suite.
   - Added: one entry per liberator, in the gtools entry's style: what it links from Molt-matts, macOS only, checks and verifies every link (herdr also fails a keys.json that does not parse). Each says it is enabled on no sleeve until the Macs run this release, because enabling one while brew serves 1.1.0 makes molt upgrade fail with "Liberator not found". (issue 0074)
   - Fixed: resleeve, upgrade and maintain read the liberator list on fd 3, so a hook that reads stdin no longer ends the run. On rhadamanth, maintain had skipped editors' doom upgrade and still reported maintenance complete. (issue 0075)
   - README: four rows in the liberator table, aligned. Also check docs/guides/, molt.toml.example and tn0001, and change only the places that list liberators by name.
3. Commit once cc's merge is on main (about 10 min): apply the drafts on top of main, run intent doctor, and commit CHANGELOG.md and README.md only, by pathspec. Docs only, so no bats run and no booking. Then send vc the hash and the lines for review, clear cc's message, and tell molt-cc.
4. Release support. hv cuts, tags, pushes and deploys (vc decision 35). Before the cut, dc checks how bin/devbin release turns [Unreleased] into the version heading, and answers vc's release check for dc's lane. The version is hv's call; cc suggests 1.2.0, a minor for the new liberators.
5. Fold (about 5 min): refresh dc's focus line (still 25 Oct), archive what is done, commit what the board verbs write.

RESOLVED SINCE dc REPORTED TO hv (in git): .hrdrcfg/ is committed as Molt's Herdr space (1f54414); cc todo 14 is issue 0076 (582c241); cc hold 17 is released to todo 16 (bb399e6). Still open: the estate shows molt-vc's slot control ORPHANED (pid 76443), so vc re-takes it.

FOR hv TO RESOLVE.
Q1. Does dc take the 0074 and 0075 CHANGELOG and README work as cc asked?
Q2. Where do dc's docs commits go: straight onto main by pathspec, as recent rounds did, or onto a dc branch in $TMPDIR/molt-wt/ for vc to merge, as the roster README's worktree rule for dc says?
Q3. Does dc build any of the other next-release issues (0068, 0070, 0072, 0073), or only write their CHANGELOG lines as cc lands them? 0065, dc's own, stays deferred.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
