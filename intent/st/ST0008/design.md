# ST0008 design: dev, opt and brew trees

## D1. Three trees, one runtime set

A **tree** is a directory holding `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`. `bin/molt` already finds `MOLT_ROOT` from its own resolved path, so every tree runs the same way and no environment variable names one. Never read `MOLT_ROOT` from the environment.

| Tree | Where                                         | Written by                                     | Upgraded by                         |
| ---- | --------------------------------------------- | ---------------------------------------------- | ----------------------------------- |
| dev  | the git checkout                              | git                                            | `molt upgrade` (git pull, as today) |
| opt  | `MOLT_INSTALL_PREFIX`, declared by the sleeve | `molt install`, run in a dev tree              | `molt install --force` from dev     |
| brew | `$(brew --prefix)/opt/molt/libexec`           | the formula, running `molt install` in the keg | `brew upgrade` (D5)                 |

The **runtime set** is what git names under `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`, and nothing else: no `test/`, `intent/`, `docs/` or board. It is listed once, in one function, and both `molt install` and the doctor read that function.

## D2. `molt install [--prefix <dir>] [--force] [--managed-by brew]`

Runs only in a dev tree, and is refused by name from opt or brew.

- **The prefix** comes from `--prefix`, else `MOLT_INSTALL_PREFIX` from the sleeve's `vars.sh`. There is no default. When neither is set the command is refused by name, because a publish to the wrong place looks the same as a publish to the right one (Utilz, devbin).
- **A dirty tree is refused**, and no flag overrides it. "Dirty" means the runtime set only, so live board views do not block a publish.
- **The copy:** the runtime set goes to `<prefix>`, along with a manifest, `<prefix>/.molt-install`. The manifest records the source commit, the version, `managed_by` (`molt` or `brew`) and a checksum per file.
- **An existing prefix** is replaced only with `--force`, and only when its manifest says Molt wrote it. A prefix that holds anything else is refused.
- **`--managed-by brew`** is for the formula. An install it writes refuses `molt install` and `molt use` into it, and says to use brew.

## D3. Tree identity

One function names the running tree, from `MOLT_ROOT`:

- **brew** when the manifest says `managed_by: brew`.
- **opt** when it has a manifest from Molt.
- **dev** when `MOLT_ROOT` is a git work tree with no manifest.
- **Anything else** is unknown, and doctor fails on it.

Every caller asks this one function (Highlander).

- **`molt version` and `molt --version`** print the version, the tree, and the commit (the manifest's, or HEAD's), eg `molt 0.3.0 (opt, 905305c) at ~/Devel/opt/molt`. `molt doctor` prints the same line.
- **In opt and brew,** `molt test` and the shellcheck lint are refused, naming the dev tree to run them in. The doctor's directory check stops requiring `test/` there. Instead it checks the manifest's checksums, and names any file that drifted.

## D4. `molt use [dev|opt|brew]`

`~/bin/molt`, the local-bin liberator's link, is the switch. The link is the only record of the choice, and nothing else stores it.

- **`molt use`** with no argument reports which tree the link serves, and changes nothing.
- **`molt use dev`** points the link at the dev tree's `bin/molt`. The dev tree is the checkout under `MOLT_PRJ_DIR`, the path the bootstrap clones to.
- **`molt use opt`** points it at `$MOLT_INSTALL_PREFIX/bin/molt`.
- **`molt use brew`** points it at `$(brew --prefix)/opt/molt/libexec/bin/molt`.

Each switch refuses a tree that isn't there, naming the step that makes it, then prints the new `molt version` line.

**The local-bin liberator stops choosing.** Today `local-bin_install` links `~/bin/molt` to whichever tree is running. Under this design, `bin/molt resleeve` from the checkout would flip a sleeve on opt back to dev. Instead:

- check passes on a healthy link to any of the three trees' `bin/molt`;
- install makes the link only when there is none, or the link is broken, pointing it at the running tree;
- verify names the tree the link serves.

## D5. `molt upgrade` by tree

The config repos (Molt-matts) are pulled in every tree, as today. The framework step depends on the running tree:

- **dev:** the git pull, exactly as now, including the dirty-tree check.
- **opt:** no pull. It says that opt is upgraded from the dev tree with `molt install --force`, and names the dev tree's commit when it is ahead of the manifest. It never publishes on its own, because a publish is a verb hv types.
- **brew:** `brew upgrade matthewsinclair/molt/molt` when `brew outdated` names it. When the keg's version changed, molt restarts on the new version, through the same restart path a pull uses (`_upgrade_restart_if_pulled`). A brew upgrade that fails is a failed pull, counted in the verdict (issue 0015).
- **`--self`:** does the framework step and the config pulls, and nothing else, in every tree.

## D6. The formula, the tap and the release

- **The template:** `packaging/homebrew/molt.rb` is a template, as devbin's is, and is never installed from. It holds placeholders for the tag and the revision.
- **The render tool:** a zsh script, `tools/formula` (no Python), offers `render <tag> <out>` and `publish`. `render` reads the tag's commit from git. `publish` renders the newest release tag into a checkout of `matthewsinclair/homebrew-molt` and pushes it. Nobody types a tag or a commit.
- **The formula's url** is `https://github.com/matthewsinclair/molt.git`, at the tag and revision, because the repo is public.
- **Install and dependencies:** `install` runs `bin/molt install --prefix libexec --managed-by brew`, and `bin.install_symlink libexec/"bin/molt"`. No `depends_on "bash"`: Molt supports macOS's own bash 3.2, and CI's macOS runner proves it. The formula says so in a comment. `test do` checks `molt version`.
- **The tap repo:** hv approved creating the public `matthewsinclair/homebrew-molt` on 24 Oct. vc creates it once WP04's render has been run end to end against a scratch tap.
- **The release steps:** `docs/releasing.md`, or the existing release notes in `intent/wip.md`'s Notes, gains the formula publish as the step after the tag push.

## D7. Sleeves

- **rhadamanth:** the dev tree stays at `~/Devel/prj/Molt`, and hv works and tests there with `bin/molt`. The everyday `molt` goes to `use opt` first, to prove the switch, and then to `use brew` once the tap exists. Either way, `molt upgrade` stops refusing over board views.
- **kovacs:** brew only, through kovacs-sysadm. This assumes Homebrew on Linux on ARM64. If it isn't there yet, kovacs-sysadm installs it, and kovacs keeps its clone until the formula installs.
- **gyges:** moves to brew only over time, through gyges-sysadm. It isn't in this thread's acceptance.
- **farcaster and pihole:** keep their dev trees. A dev tree stays a supported install.

## Not in this thread

- No Molt-from-brew bootstrap path. `bin/bootstrap.sh` keeps cloning. A brew sleeve's first steps, `brew install` then `molt resleeve`, go into the getting-started guide as text only.
- No fleet audit verb, unlike devbin's `fleet`.
