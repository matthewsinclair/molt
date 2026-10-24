# ST0008 design: dev, opt and brew trees

## D0. The contract this design conforms to

Every tool released through Homebrew follows one contract: Molt, Utilz, Intent and devbin (hv, 24 Oct). It is devbin's `docs/dev-opt-brew.md` at commit `aeed31e4`, sections T1 to T10, cited by path and commit and never copied here. Its T3 amendment is decision 58: opt fails, brew notes, and an old-form or manifest-less brew keg still answers `brew`. That amendment lands with devbin issue 0213. When this design and the contract disagree, the contract wins and this file is corrected.

hv's two rulings behind it, given by TUI on 24 Oct:

- **"Your links first"**. Formulas link into Homebrew's `bin` as normal. `~/.local/bin` comes before Homebrew's `bin` on every sleeve, and `use` switches the per-user link.
- **The contract lives in devbin's docs.**

What follows is how Molt meets the contract, and only what is specific to Molt.

## D1. Three trees, one runtime set

A **tree** is a directory holding `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`. `bin/molt` already finds `MOLT_ROOT` from its own resolved path, so every tree runs the same way and no environment variable names one. Never read `MOLT_ROOT` from the environment.

| Tree | Where                                         | Written by                                     | Upgraded by                         |
| ---- | --------------------------------------------- | ---------------------------------------------- | ----------------------------------- |
| dev  | the git checkout                              | git                                            | `molt upgrade` (git pull, as today) |
| opt  | `MOLT_INSTALL_PREFIX`, declared by the sleeve | `molt install`, run in a dev tree              | `molt install --force` from dev     |
| brew | `$(brew --prefix)/opt/molt/libexec`           | the formula, running `molt install` in the keg | `brew upgrade` (D5)                 |

The **runtime set** is what git names under `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`, and nothing else: no `test/`, `intent/`, `docs/` or board. It is listed once, in one function, and both `molt install` and the doctor read that function.

**brew is named by its opt link** (T1). In a keg, `MOLT_ROOT` resolves to `Cellar/molt/<version>/libexec`, which `brew upgrade` deletes, so one function names a brew root by `$(brew --prefix)/opt/molt/libexec` wherever a path is shown or recorded.

## D2. `molt install [--prefix <dir>] [--force] [--managed-by brew]`

This is the publish (T2). It runs only in a dev tree, and is refused by name from opt or brew.

- **The prefix** comes from `--prefix`, else `MOLT_INSTALL_PREFIX` from the sleeve's `vars.sh`. There is no default. When neither is set the command is refused by name, because a publish to the wrong place looks the same as a publish to the right one.
- **A dirty runtime set is refused**, and no flag overrides it. Only the runtime set counts, so live board views do not block a publish.
- **The copy:** the runtime set goes to `<prefix>`, together with the manifest `<prefix>/.molt-install` in T3's form:
  - `# key: value` header lines, carrying `tool: molt`, `version`, `source_commit` (the full sha) and `managed_by` (`molt` or `brew`);
  - then one `shasum -a 256 -c` line per file, sorted with `LC_ALL=C sort`.
- **An existing prefix** is replaced only with `--force`, and only when its manifest says `managed_by: molt`. A prefix whose manifest names no `managed_by`, or another one, is refused by name, as is one that holds anything else. `--force` is the one re-publish route.
- **An old-form manifest** (bare `key: value` headers, written before the contract) is not read as a second format. In opt, doctor fails and names `molt install --force`, which may replace it on its `managed_by: molt` line. In brew, doctor notes it and names `brew upgrade`, and the tree is still `brew` (T3 as amended).
- **`--managed-by brew`** is for the formula. An install it writes refuses `molt install` and `molt use` writes into it, and says to use brew.

## D3. Tree identity and the version line

One function names the running tree from `MOLT_ROOT`, in T4's order:

1. **brew** when the manifest says `managed_by: brew`.
2. **opt** when the manifest's `tool` is `molt`.
3. **dev** when `MOLT_ROOT` is a git work tree with no manifest.
4. **unknown** otherwise, and doctor fails on it.

Every caller asks that one function, and one function gives a tree's commit.

- **The version line** (T4): `molt version`, `molt --version` and `molt doctor` print `molt <version> (<tree>, <sha12>[+dirty]) at <root>`, eg `molt 0.3.0 (opt, 905305c1a2b3) at /Users/matts/Devel/opt/molt`.
  - The sha is the manifest's `source_commit` in opt and brew, or HEAD in dev.
  - `+dirty` follows it in dev while the runtime set is dirty.
  - When git cannot read a dev tree, the sha is `unknown` and doctor fails, saying why.
  - `<root>` is absolute, never abbreviated with `~`, and a brew root is its opt link.
- **In opt and brew** (T7), `molt test` and the shellcheck lint are refused, naming the dev tree to run them in. The doctor's directory check does not require `test/` there. Instead it checks the manifest's checksums and names any file that drifted.

## D4. `molt use [dev|opt|brew]`

The switch is one link, `~/.local/bin/molt` (T5). `MOLT_LOCAL_BIN` defaults to `~/.local/bin`; it was `$HOME/bin` until the contract. On rhadamanth the two are one directory. On kovacs they are not, and kovacs's link moves at its next resleeve. The link is the only record of the choice, and nothing else stores it.

- **`molt use`** with no argument reports which tree the link serves, or `brew` when there is no link and the first `molt` on PATH resolves into the keg. It changes nothing.
- **`molt use dev`** points the link at the dev tree's `bin/molt`. The dev tree is the checkout under `MOLT_PRJ_DIR`, the path the bootstrap clones to.
- **`molt use opt`** points it at `$MOLT_INSTALL_PREFIX/bin/molt`.
- **`molt use brew`** removes the link, so Homebrew's own `bin/molt` answers. No link means brew: that is the one rule, and it is the state a brew-only sleeve is in without ever running `use`.

`use dev` and `use opt` refuse a tree that isn't there, naming the step that makes it. Every switch then prints the new version line.

**The shadow check.** Doctor, and `molt use` with no argument, fail when the link exists but is not the first `molt` on PATH (a stale link that a brew link shadows is named as one), and name what shadows it. The comparison is of resolved directories, never path strings. On rhadamanth `~/bin` is a symlink to `~/.local/bin`, so both PATH entries name one link.

**PATH: your links first** (T5, hv's ruling). Molt-matts' zshrc puts `~/.local/bin` ahead of the FIRST Homebrew `bin` entry. `brew shellenv` puts `/opt/homebrew/bin` on PATH twice on rhadamanth (intent-vc's measurement), so it is a `path_prepend` after `brew shellenv` has run, not the `path_add` it is today. The switch governs login shells only. Whether launchd's PATH follows is a sleeve decision outside the contract, and it is put to hv (vc todo 25).

**The local-bin liberator stops choosing.** Today `local-bin_install` links `~/bin/molt` to whichever tree is running, so `bin/molt resleeve` from the checkout would flip a sleeve on opt back to dev. Instead:

- check passes on a healthy link to a dev or opt tree's `bin/molt`, and on no link at all when the running tree is brew;
- install makes a missing or broken link only when the running tree is dev or opt, pointing it at that tree. In brew it makes nothing, since a link into the keg would undo `use brew` at the next resleeve. It never removes one, and it refuses by name anything else at the link's path, a regular file included;
- verify names the tree the link serves.

## D5. `molt upgrade` by tree

The config repos (Molt-matts) are pulled in every tree, as today. The framework step depends on the running tree (T6):

- **dev:** the git pull, exactly as now, including the dirty-tree check.
- **opt:** no pull. It says that opt is upgraded from the dev tree with `molt install --force`, and names the dev tree's commit when it is ahead of the manifest. It never publishes on its own, because a publish is a verb hv types.
- **brew:** with `HOMEBREW_NO_AUTO_UPDATE=1` throughout:
  1. `brew update`, a counted step of its own;
  2. `brew outdated`;
  3. `brew upgrade matthewsinclair/molt/molt` when that names it.

  When the opt link resolves to a new keg, molt restarts on it through the same restart path a pull uses. A failed update or upgrade is counted in the verdict (issue 0015). `--dry-run` skips the update and says so.

- **`--self`:** does the framework step and the config pulls, and nothing else, in every tree.

## D6. The formula, the tap and the release

- **The template** (T8): `packaging/homebrew/molt.rb` is never installed from, and holds exactly one placeholder each for the tag and the revision.
- **The render tool:** a zsh script in the repo, `tools/formula` (no Python), offers `render <tag> <out>` and `publish`. `render` reads the tag's commit from git. `publish` renders the newest release tag into a checkout of `matthewsinclair/homebrew-molt` and pushes it. Nobody types a tag or a commit.
- **The formula's url** is `https://github.com/matthewsinclair/molt.git`, at the tag and revision, because the repo is public.
- **Install:** `install` runs `bin/molt install --prefix libexec --managed-by brew`, then `bin.install_symlink libexec/"bin/molt"`, so a brew-only user who never runs `use` still gets a working `molt` (T5, T8).
- **Caveats** name `molt use` for a maintainer with a dev or opt tree.
- **No `depends_on "bash"`:** Molt supports macOS's own bash 3.2, and CI's macOS runner proves it. The formula says so in a comment.
- **`test do`** runs the version line.
- **The tap repo:** hv approved creating the public `matthewsinclair/homebrew-molt` on 24 Oct. vc creates it once the conforming formula has been rendered and installed end to end against a scratch tap.
- **The release steps:** `docs/releasing.md`, or the existing release notes in `intent/wip.md`'s Notes, gains the formula publish as the step after the tag push.

## D7. Sleeves

- **rhadamanth:** the dev tree stays at `~/Devel/prj/Molt`, and hv works and tests there with `bin/molt`. The everyday `molt` goes to `use opt` first, to prove the switch, and then to `use brew` once the tap exists. Either way, `molt upgrade` stops refusing over board views.
- **kovacs:** brew only, through kovacs-sysadm. This assumes Homebrew on Linux on ARM64. If it isn't there yet, kovacs-sysadm installs it, and kovacs keeps its clone until the formula installs. Its `~/bin/molt` gives way to the brew formula's link; `~/bin` and `~/.local/bin` are different directories there.
- **gyges:** moves to brew only over time, through gyges-sysadm. It isn't in this thread's acceptance.
- **farcaster and pihole:** keep their dev trees. A dev tree stays a supported install.
- **Tool install prefixes reach the shell through Molt's one env writer.** A sleeve's `vars.sh` is read only when Molt renders, so a tool's opt prefix declared there reaches no shell on its own. Molt publishes each declared prefix through the writer that already publishes `CLAUDE_CONFIG_DIR`: `~/.config/molt/env.sh`, which `~/.zshenv` sources, plus the launchd plist and environment.d. First up is `UTILZ_INSTALL_PREFIX`, declared on rhadamanth as `"$MOLT_OPT_DIR/utilz"`. It must be live before Utilz 2.14.3 is cut (utilz-vc's ask, 24 Oct). A brew-only sleeve declares none.

## Not in this thread

- No Molt-from-brew bootstrap path. `bin/bootstrap.sh` keeps cloning. A brew sleeve's first steps, `brew install` then `molt resleeve`, go into the getting-started guide as text only.
- No fleet audit verb, unlike devbin's `fleet`.
- `liberators/vscode.sh` links `code` into a hardcoded `$HOME/bin`, outside Molt's link set and outside the contract. It is a separate issue.
