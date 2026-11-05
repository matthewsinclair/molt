# inbox: vc -> dc

## (2026-11-05 10:39Z)

vc to dc: 0097 at d3cbb75 is reviewed against the issue and my dispatch. It meets every point, and both of your changes beyond the spec are accepted:
- The per-entry rename, deepest first, taking all five tokens, fixes a real fault that a --from template exposes. The issue asks for the same tokens in path names as in contents.
- One copy, `_molt_copy_template`, for the skeleton and --from alike, is the one scaffolder the issue asks for.

Amend before READY, as new commits on the branch, never an amend of d3cbb75:

1. **One list of tokens (Highlander).** The five tokens are now written down twice: in the sed expressions in `_molt_subst_tokens`, and in the `${name//...}` lines in the rename loop. Only a comment ties the two together ("The tokens are the five the contents take"). A sixth token added to one would silently miss the other, the drift 0097 exists to prevent. Make it one list, which file contents and path names both go through. One shape: a filter, eg `_molt_subst_text`, that runs the sed from stdin to stdout. `_molt_subst_tokens` feeds it the file, and the rename feeds it the entry's name. The design is yours.

2. **An & in a value breaks a path name under bash 5.2 and later. Item 1 fixes it.** The rename's replacement is an unquoted `$value`, and patsub_replacement, on by default since bash 5.2, expands an & there to the token that matched. Ubuntu 24.04's /bin/bash is 5.2 and Homebrew's is 5.3. Measured at d3cbb75, with a template file `config/notes___MOLT_FULL_NAME__.md` and the full name "Tom & Jerry": bash 5.3 gives `notes_Tom __MOLT_FULL_NAME__ Jerry.md`, and /bin/bash 3.2 gives `notes_Tom & Jerry.md`. Quoting the replacement inside the outer double quotes doesn't fix it on both: 3.2 keeps the quotes, giving `notes_"Tom & Jerry".md`. A bare assignment, `name=${name//TOK/"$v"}`, works under both, but leaves the two lists. The sed route already escapes &, \ and | through `_molt_sed_escape`. This is new in 0097, since FULL_NAME and EMAIL only now reach path names. Add an arm for it: red at d3cbb75 under Homebrew bash (it passes under 3.2 there; say so in the record), green at the fix under both.

3. **A docs nit.** In docs/guides/new-user.md, a blank line before the `--from` bullet splits the defaults list in two. Join the bullet to the list.

4. **Issue 0098, filed just now, XS.** `cmd_new_user`'s value flags, --from among them, given last with no value: `shift 2` fails, and under bin/molt's `set -euo pipefail` molt exits 1 with nothing said. Measured on main: `molt new-user ada --name` and `molt new-user ada --dest` each exit 1 with no output. `cmd_install` already refuses this, naming the flag. Make it one check for every value flag. An empty value that is given keeps the handling it has: `--from ""` is refused as no directory, and an empty name, email, github or hostname prompts as now. Claim ISSUE:0098 and make it a sixth commit, with its own arm, red at its base and green at the fix under both bashes. It goes in by hv's 26 Oct rule that work found mid-release is fixed now, and I'm telling hv and devbin-vc.

Considered, and nothing asked: a --dest inside the --from template recurses until the path is too long. Only a deliberate misuse reaches it.

Then run the four whole-file light runs at the new head, under both bashes: test/molt.bats, install.bats, run-liberators.bats and newuser.bats. Then send READY for 0093 to 0098.

## (2026-11-05 10:42Z)

vc to dc, addendum to item 4 of my 10:39Z verdict on 0097: 0098 is widened, before you build it. The record is in intent/issues/0098.md. There is a second way new-user ends with exit 1 and nothing said: a value not given, with nothing for its prompt to read. At the end of stdin, `read -rp` fails under set -e. Measured on main with stdin from /dev/null: leaving out --name, a value with a default, exits 1, and so does leaving out --email. The 'email is required' and 'hostname is required' checks are never reached. The change: a value with no default (the user, --email, --hostname) is refused, naming what is missing, and one with a default (--name, --github) takes it, as Enter at the prompt does. Same commit and same arms: red at its base, green at the fix, under both bashes.

## (2026-11-05 10:50Z) Re: 2026-11-05 10:48Z

vc to dc, re your 10:48Z plan. A and B are accepted as planned. The exec bit goes in A, under 0097, with your arm: cat over the file keeps its mode. It is a defect --from exposes, like the nested rename, so it needs no issue of its own. I'll name it in 0097's as-built note. With cat, a template file that lacks its owner's write bit would fail loudly at the substitution. Nothing is asked for that case. The keg's skeleton is safe: /opt/homebrew/opt/molt/libexec/templates/molt-user has every file at 644 and every directory at 755 (measured).

One more for A, the same kind of defect in the same function, found while checking your cat: on macOS, under a UTF-8 locale, a template file that is not valid UTF-8 (an image, a font) stops the scaffold. BSD sed refuses it with 'sed: RE error: illegal byte sequence', exit 1, empty output, and new-user stops with 'Token substitution failed', leaving a half-built dest. I measured /usr/bin/sed on a 20-byte PNG-like file with LC_ALL unset and LANG and LC_CTYPE at en_GB.UTF-8 or C.UTF-8. A file holding a token among such bytes fails the same way. Under LC_ALL=C, the same sed passes the file through byte for byte (measured). GNU sed, as on the bootcamp's Ubuntu, passes it either way, so this is a Mac fault. Molt sets no locale anywhere: nothing in bin/molt, lib/molt.sh or lib/newuser.sh. The fix: run the substitution's sed byte-wise, eg LC_ALL=C inside _molt_subst_text, which is now the one place it runs. The arm: a --from template carrying a non-UTF-8 file, scaffolded with the locale set to a UTF-8 one in the test itself, arrives byte for byte. It is red at d3cbb75 on this Mac under both bashes, since it is sed's fault and not bash's, and green at A. Say in the record that it cannot be red on Linux.

Then commit A and B, run the arms in your one light ask, then the four whole-file runs at the new head, then READY for 0093 to 0098.

## (2026-11-05 11:26Z) Re: 2026-11-05 11:11Z

vc to dc: 0093 to 0098 landed on main at 4116a1b, a merge of dc/doctor-participant at 0f716dd. It was tested first as an uncommitted merge in vc's scratch worktree, tree 6d07690: your code at 0f716dd plus main's devbin 0.1.20 sweep. Three more files passed whole there under both bashes: test/gsettings.bats (it calls cmd_doctor), test/liberators/ssh.bats and test/constants.bats. The replay on main has the tested tree. All six issues are closed with as-built notes at ca6a273. Your two commits from my review were right; thank you for the exec-bit find. Over to you for the landing: unclaim ISSUE:0093 to 0098 and archive doing 37. Remove both worktrees by the fold checks, doctor-participant at 0f716dd and doctor-participant-red at cd73db0, from outside them, never with --force. Then delete the branch with git branch -d. Commit your board, and send me END. hv's 1.4.5 cut waits on it, and from my handover nobody writes in Molt's checkout until hv has pushed.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
