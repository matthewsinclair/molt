# Sleeve Agents

A sleeve agent is a local agent, Claude Code for now, that does machine work on one sleeve as you: system administration, operations, or documenting the machine. Molt gives each one a home: a directory declared in the sleeve's `molt.toml` and rendered from a role kept in your config repo, holding the agent's instructions, its permissions and its memory. The agent runs in its home.

Without a home, an agent like this runs from `$HOME`. There it has no instruction file of its own and no project-level permissions, it shares a memory slot with every other session started in `$HOME`, and Claude Code's own files sit loose in the home directory. So Molt also moves Claude Code's state out of `$HOME`, once per sleeve, and refuses a Claude started there.

## Sleeve, project and estate agents

|            | Sleeve agent                                               | Project agent                      | Estate agent                                                                                                                                          |
| ---------- | ---------------------------------------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Works on   | one machine                                                | one project                        | one Gtools estate                                                                                                                                     |
| Runs in    | its home, `$MOLT_AGT_DIR/<hostname>-<role>/`               | the project's working tree         | the estate's content root, the directory Gtools registers as `GTOOLS_ESTATE` and deploys the estate's `.claude/` into, eg `~/Dropbox/Sinclair-Shared` |
| Named      | `<hostname>-<role>`, eg `kovacs-sysadm`                    | `<project>-<suffix>`, eg `molt-vc` | `<estate>-estate`, eg `sinclair-estate`                                                                                                               |
| Bounded by | its role contract and permission profile, rendered by Molt | the project and Intent             | the Gtools consulting contract and the estate's pinned `settings.json`, deployed by Gtools                                                            |

This guide is about sleeve agents. A project agent is a session run inside an Intent project, which already gives it instructions, permissions and memory, and an estate agent is a session run in a Gtools estate, which Gtools provisions, so Molt manages neither.

## Naming

### Sleeve agents

A sleeve agent is always named `<hostname>-<role>`: `rhadamanth-sysadm`, `kovacs-ops`, `gyges-docs`. The hostname is the sleeve's short hostname, the name of its `instances/<hostname>/` directory, and the role is one of the roles below. You never write the name: Molt derives it from the `[[agent]]` entry, so it cannot be mistyped.

gyges' agent is still called `gyges-infra`, from before this convention. It becomes `gyges-sysadm` when gyges is moved, which happens later.

### Hosts

Physical machines take their names from the Hyperion Cantos: rhadamanth, gyges, shrike, yggdrasil, farcaster. Virtual machines take Altered Carbon envoy and sleeve names: kovacs.

### Project agents

A project agent is named `<project>-<suffix>`, eg `molt-vc` or `gtools-ic`. The six suffixes below are the convention for Intent projects, named on 21 Oct 2026. Molt's whiteboard roster, [`intent/whiteboard/README.md`](../../intent/whiteboard/README.md), is the record, and this table repeats it:

| Suffix | Name              |
| ------ | ----------------- |
| `sc`   | Supervisor Claude |
| `vc`   | Validation Claude |
| `cc`   | Control Claude    |
| `ic`   | Interface Claude  |
| `ac`   | Authoring Claude  |
| `dc`   | DevX Claude       |

Molt itself runs `vc`, `cc`, `dc` and `ac`. A suffix names a project session's job and a role names a sleeve agent's, so `dc`, DevX Claude, is a project agent, while `docs` is a sleeve role.

### Estate agents

An estate agent is named `<estate>-estate`: `sinclair-estate`, `geodica-estate`. An estate has one agent, so the suffix never varies. Gtools provisions it, with `gtools doctor` and the contract it deploys, and Molt does not manage it.

Its content root is the directory Gtools registers as `GTOOLS_ESTATE` and deploys the estate's `.claude/` into: `~/Dropbox/Sinclair-Shared` for sinclair, and `~/Dropbox/Geodica/Consulting` for geodica today. Start the session in that directory or below it. Claude Code loads `CLAUDE.md` and settings from the launch directory and its parents, never from a child, so a geodica session started in `~/Dropbox/Geodica` loads none of them.

## Roles

A role is a directory under your config repo's `config/agents/roles/`, so the set is yours to define. The convention is three roles, the same on every sleeve:

| Role     | For                          | Sandbox                     |
| -------- | ---------------------------- | --------------------------- |
| `sysadm` | system administration        | off: it cannot be sandboxed |
| `ops`    | operations and monitoring    | on, escape hatches closed   |
| `docs`   | documentation of the machine | on, escape hatches closed   |

`sysadm` may change the machine, which is why it cannot run sandboxed. `ops` observes and diagnoses, and writes only inside its home. In `ops` and `docs` the sandbox's escape hatches are closed, as [Fence and wall](#fence-and-wall) explains. Every agent's work goes in its home's `work/` directory, while its session starts in the home itself (see [Starting an agent](#starting-an-agent)). What each role may and may not touch is set out in its contract, `config/agents/roles/<role>/AGENTS.md.tmpl`, and its permission profile beside it. What every sleeve agent shares, such as its home and how to start in it, is in one preamble, `config/agents/AGENTS.md.tmpl`.

## Three layers

| Layer         | Where                                             | Owned by       | Holds                                                                                                                                                           |
| ------------- | ------------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Role source   | your config repo's `config/agents/`               | you, in git    | the shared preamble `AGENTS.md.tmpl`, and for each role the contract `roles/<role>/AGENTS.md.tmpl` and the permission profile `roles/<role>/settings.json.tmpl` |
| Agent home    | `$MOLT_AGT_DIR/<hostname>-<role>/`                | Molt, rendered | `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `memory/`, `work/`                                                                                           |
| Harness state | `$XDG_CONFIG_HOME/claude`, as `CLAUDE_CONFIG_DIR` | Claude Code    | credentials, transcripts, plugins and user settings: one per machine, shared by every session                                                                   |

The agent home is both the agent's config and the directory it runs in. Claude Code reads project-level settings from `.claude/` in the directory a session starts in, and from no directory above it, so starting the agent in its home is what applies the home's settings: the two coincide by construction (see [Starting an agent](#starting-an-agent)). The home's settings set `autoMemoryDirectory` to `<home>/memory`, so the agent's memory lives in its home rather than in the harness state, where Claude Code keys auto memory by git repository, or by the project root outside one.

### What a session in the home reads

A session started in a home reads four layers of instructions, widest first:

| Layer      | File                                                                          | Carries                                                                                            |
| ---------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| User scope | `CLAUDE.md` and `AGENTS.md` in the config dir, linked from `config/claude/`   | the rules every session on every sleeve follows                                                    |
| Agent      | the home's `AGENTS.md`, first from `config/agents/AGENTS.md.tmpl`             | what every sleeve agent shares: who it is, its home and how to start in it, the files Molt renders |
| Role       | the home's `AGENTS.md`, next from `config/agents/roles/<role>/AGENTS.md.tmpl` | the role's own text: what the role is for, what it may touch, what it must not                     |
| Host       | `instances/<hostname>/agents/<role>.md`, appended to the home's `AGENTS.md`   | facts true on this machine only: its stack layout, what is installed, its known issues             |

The home's `CLAUDE.md` is a one-line `@AGENTS.md` stub. Put each instruction in exactly one layer: a rule that holds everywhere belongs in user scope, one that holds for every sleeve agent in the preamble, and the role contract repeats neither. The preamble is optional; without one, the role's template opens the file.

When your config repo has `config/claude/CLAUDE.md` and `AGENTS.md`, Molt links them into the config dir on every sleeve, moved or not (on a sleeve that has not moved, the config dir is still `~/.claude`), so the cross-session rules are the same everywhere; a regular file already at either path is backed up before the link replaces it. Project agents read these files too.

## Declaring an agent

In the sleeve's `instances/<hostname>/molt.toml`, enable the `agents` liberator and add an `[[agent]]` table for each role the sleeve runs:

```toml
[[liberator]]
name = "agents"
enabled = true

[[agent]]
role = "sysadm"

[[agent]]
role = "ops"

[[agent]]
role = "docs"
enabled = false
```

| Key       | Required | Default    | Meaning                                                                   |
| --------- | -------- | ---------- | ------------------------------------------------------------------------- |
| `role`    | yes      |            | a role your config repo defines: a directory under `config/agents/roles/` |
| `enabled` | no       | `true`     | `false` declares the agent without rendering its home                     |
| `harness` | no       | `"claude"` | the only value Molt accepts                                               |

The `[[agent]]` entries render nothing without the `[[liberator]]` entry for `agents`, though `molt agent list` reads them either way.

Homes live under `MOLT_AGT_DIR`. It defaults to the `agt/` sibling of `MOLT_PRJ_DIR`, the way `MOLT_CFG_DIR` defaults to `cfg/`, so `~/Devel/prj` gives `~/Devel/agt`. With neither set, Molt does not guess: `MOLT_AGT_DIR cannot be resolved: MOLT_PRJ_DIR is unset`, and no home is made. Export it from your `zshenv` beside `MOLT_PRJ_DIR`, so your shells and your agents see the same value. An agent runs as you, and Unix has no convention for an interactive agent that runs as its user: `/opt`, `/var/lib` and `/srv` are for software and for services under their own accounts.

Molt refuses an agents root it cannot hold homes in, and then makes none, renders no home-launch guard and moves no state. The root must be absolute and canonical, with no trailing slash, no `//` and no `.` or `..` component, and hold no line break. It must not be at or above `$HOME`, `MOLT_PRJ_DIR` or `MOLT_CFG_DIR`, compared by where the paths lead, because the guard would then refuse launches in your projects. It must not be at or under `~/.claude`, Claude Code's config dir, or the config dir the sleeve declares, because a home there would move with Claude Code's state. And the sleeve's `vars.sh` must not set, empty or unset `MOLT_AGT_DIR`, since the guard and the homes must agree on one root: set it where molt runs, beside `MOLT_PRJ_DIR`. Each refusal is one line naming the root and the fault, eg `MOLT_AGT_DIR, ~/Devel/agt, is at or under ~/.config/claude, the config dir this sleeve declares for Claude Code: ...`.

## What Molt renders

On `molt resleeve` and `molt upgrade`, the `agents` liberator renders each enabled agent's home:

| In the home             | Rendered from                                                                                                                                                                                            |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`             | `config/agents/AGENTS.md.tmpl` if present, then `config/agents/roles/<role>/AGENTS.md.tmpl`, then `instances/<hostname>/agents/<role>.md` if present, with a blank line before each part after the first |
| `CLAUDE.md`             | a one-line `@AGENTS.md` stub                                                                                                                                                                             |
| `.claude/settings.json` | `config/agents/roles/<role>/settings.json.tmpl`, with `autoMemoryDirectory` set to `<home>/memory`                                                                                                       |
| `memory/`, `work/`      | created empty, and the agent's from then on: Molt never writes to them again                                                                                                                             |

Templates go through Molt's usual renderer (see [Template System](templates.md)), so only `MOLT_*` variables are substituted and any other `$VAR` is left as written. Besides the sleeve's own instance variables, an agent's templates can use:

| Variable          | Value                            |
| ----------------- | -------------------------------- |
| `MOLT_HOSTNAME`   | the sleeve's short hostname      |
| `MOLT_AGENT_NAME` | `<hostname>-<role>`              |
| `MOLT_AGENT_ROLE` | the role                         |
| `MOLT_AGENT_HOME` | the home, `$MOLT_AGT_DIR/<name>` |

A contract that names a `MOLT_*` variable for its reader, rather than wanting its value, should write the name without the `$`.

Each rendered file has a `.molt-rendered` sidecar recording a digest of its sources (see [Detecting stale renders](templates.md#detecting-stale-renders)). Re-rendering is a no-op while the digests match. A change to the role's templates or to the host's overlay makes the home stale, and the next `molt upgrade` re-renders it. A role your config repo does not define is a fault that names the role and the path Molt looked in. A role's `settings.json.tmpl` must render to one JSON object, or the home's settings are not written: `agents: <name>'s settings.json, from role <role>'s settings.json.tmpl, is not usable: the template does not render to one JSON object`.

Each file is built whole, preamble and overlay included, before Molt compares it with what is in the home, so an unchanged home is left alone and a changed one is backed up once. Lines a home's `AGENTS.md` carries above `@@MOLT:BEGIN@@` are kept only when the new render opens with the marker (see [Preserving hand-written entries](templates.md#preserving-hand-written-entries)); with a preamble ahead of a role contract that carries it, the render no longer opens with the marker, so put the marker at the top of the preamble, or keep such text in the overlay.

A home renders whether or not the sleeve's Claude Code state has moved (see below). That is deliberate: on a sleeve whose agent still runs from `$HOME`, the home can be rendered first, so the agent can copy its own files in before its state moves.

## Listing and inspecting agents

```bash
molt agent list
molt agent config <name>
```

`molt agent list` prints each declared agent. Molt's messages carry `Zen:`, `Zen [warning]:` or `Zen [error]:`, which the samples in this guide leave off; the table, the `No agents:` line and `molt agent config` print bare:

```
NAME                         ROLE     ENABLED  STATE          HOME
kovacs-sysadm                sysadm   true     current        ~/Devel/agt/kovacs-sysadm
kovacs-ops                   ops      false    role undefined ~/Devel/agt/kovacs-ops
```

`STATE` is one of `current`, `stale`, `not rendered` and `role undefined`; `stale` covers any rendered file missing or out of date, and a missing `memory/` or `work/`. Faults in the `[[agent]]` entries follow the table as warnings, each as `molt agent: molt.toml: <fault>` with the faults [molt doctor](#what-molt-doctor-reports) lists, and the command then exits 1. A sleeve whose `molt.toml` has no `[[agent]]` entries prints `No agents: this sleeve's molt.toml has no [[agent]] entries.`, and one with no `molt.toml` fails.

`molt agent config <name>` prints one agent: its role, harness and home, and the currency of each rendered file; whether the home's settings run the home-launch guard, on a sleeve that declares its config dir; then the settings files Claude Code merges for a session in the home, highest precedence first; then the effective permissions, each rule tagged with the layer it came from:

```
kovacs-sysadm
  role      sysadm
  harness   claude
  enabled   true
  home      ~/Devel/agt/kovacs-sysadm
  files
    AGENTS.md                current
    CLAUDE.md                current
    .claude/settings.json    stale
  settings, highest first
    managed  /etc/claude-code/managed-settings.json (absent)
    local    ~/Devel/agt/kovacs-sysadm/.claude/settings.local.json (absent)
    home     ~/Devel/agt/kovacs-sysadm/.claude/settings.json
    user     ~/.config/claude/settings.json
  permissions, deny winning at every layer
    deny   Bash(rm -rf:*)                               home
    allow  Bash(uptime)                                 home
```

The managed layer also lists any drop-ins in `managed-settings.d/`. A file the role has no template for shows `role <role> has no <template>`, and a session with no rules at any layer shows `none` under permissions. Reading the rules needs `jq`, and a layer that is not JSON with permission lists fails the command, naming the file. An undeclared name fails with `molt agent: <name> is not declared on this sleeve; declared: <the declared names>`.

## Starting an agent

There is no launch command. To start an agent, start Claude in its home:

```bash
cd "$MOLT_AGT_DIR/kovacs-sysadm" && claude
```

Start it in the home itself, never in a directory below it. Claude Code reads project settings only from `.claude/` in the directory a session starts in, with no fallback to a parent, while it reads `CLAUDE.md` from that directory and every one above it. An agent started in its `work/` therefore keeps its contract and loses its fence, its sandbox and its memory setting. Once it is started in its home, working under `work/` by path, or with a `cd` inside a command, is fine. On a sleeve whose state has moved, the home-launch guard blocks the prompts of a session started at the agents root or below a home, and of one that did not get the sleeve's config dir, as a Claude started from a shell opened before the move does, so start an agent from a shell opened after the move: `echo $CLAUDE_CONFIG_DIR` there prints the config dir (see [A Claude started in $HOME, below a home, or without the config dir, is refused](#a-claude-started-in-home-below-a-home-or-without-the-config-dir-is-refused)).

Accept the trust prompt at the first launch in each home. The home's `permissions.allow` rules, hooks in settings files and the home's `autoMemoryDirectory` wait for that prompt, which an interactive session shows once per directory. Claude Code's documentation says a `claude -p` run never shows it, uses the hooks in the home's settings but not its allow rules, and warns `this workspace has not been trusted` on stderr; it gives `autoMemoryDirectory` the same trust rule as hooks. Molt has not tested this.

## Moving Claude Code's state out of $HOME

By default Claude Code keeps its state in `~/.claude` and `~/.claude.json`. `CLAUDE_CONFIG_DIR` relocates both: every `~/.claude` path, and `~/.claude.json` as well, which Claude Code's documentation does not say but a test on 21 Oct 2026 showed. Molt moves a sleeve's state once, to the directory the sleeve declares (by convention `$XDG_CONFIG_HOME/claude`), and from then on keeps it there: no `~/.claude` at all, and no compatibility symlink.

### Declaring the variable is what moves a sleeve

A sleeve opts in by declaring `MOLT_CLAUDE_CONFIG_DIR` in its `instances/<hostname>/vars.sh`:

```bash
export MOLT_CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
```

Until it does, the sleeve keeps today's behaviour: no move, no env or GUI file, no `$HOME` hook. Of what this thread adds, only the user-scope links described above are made either way; the links and the statusLine the claude liberator made before are made as they were. Once it does, the next `molt upgrade` or `molt resleeve` runs the move, so declare it when the sleeve is ready to move, and run that upgrade as the next section says.

The value must be a path Molt can write unchanged into each file that publishes it. It must be absolute and canonical, with no trailing slash, no `//` and no `.` or `..` component. It must hold no character those files read as syntax: either quote, `$`, a backquote, a backslash, `<`, `>`, `&` or a line break. It must not end in whitespace, which environment.d strips. It must be a directory of its own, not `$HOME`, `~/.claude` or anything under it. `MOLT_AGT_DIR` must be an agents root Molt accepts, as [Declaring an agent](#declaring-an-agent) sets out, because the home-launch guard is rendered with it. A `vars.sh` that cannot be read, does not parse, or stops before its end when sourced is refused as well. In each case the claude liberator fails before it moves or writes anything, with a line that names the fault, eg `MOLT_CLAUDE_CONFIG_DIR is not a canonical path, with no trailing slash, // or . or .. component: <path>`, and `molt doctor` reports the same line.

### Quit every Claude first, and use a plain terminal

A live session cannot survive its own state moving: `mv ~/.claude` under a running Claude takes its transcript, credentials and state out from under it. Run the upgrade that moves a sleeve from a plain terminal, with every Claude Code process on the sleeve quit. That includes Claude in Chrome: while Chrome runs with the extension, its native host (`~/.local/bin/claude --chrome-native-host`) is a `claude` process, so quit Chrome as well.

### What the move does, and when it refuses

When `~/.claude` is a directory or `~/.claude.json` a file, and the config dir is absent or empty (an empty one is removed first), the claude liberator backs up `~/.claude` and `~/.claude.json`, then moves both into the config dir. The backup sits beside the config dir, never in `$HOME`, named `<config dir>.molt-backup.<YYYYmmddHHMMSS>` in local time like every Molt backup, eg `~/.config/claude.molt-backup.20261021093000/`. It holds `.claude/` and `.claude.json` exactly as they were in `$HOME`, and Molt never removes it. It is a clone, `cp -cRp` on APFS and `cp -a --reflink=auto` on Linux, so even a large `~/.claude` costs little or no extra space where the filesystem can clone.

It refuses, and moves nothing, while any Claude Code process is running. Each line of the refusal is a `Zen [error]:` line, the prefix left off below. It lists each one as `<pid> <command line>`, cut to 100 characters, including the session molt was started from, so an agent cannot move its own state:

```
claude: Claude Code is running, and a live session cannot survive its own state moving:
  3741 /Users/you/.local/bin/claude --chrome-native-host
  41859 claude
claude: quit every Claude Code on this machine, then run molt resleeve from a plain terminal
claude: CLAUDE_CONFIG_DIR was not published: no env.sh or GUI file was written, and nothing else was changed
```

It also refuses in these cases, each ending with the same not-published line. Here `~` is your home directory and `~/.config/claude` the declared config dir:

| Refusal                                                                                                                                                              | When                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| `~/.config/claude already holds <its first five entries>[ and N more], so ~/.claude and ~/.claude.json did not move into it; molt never merges the two`              | the config dir is not empty                  |
| `~/.claude is a symlink to <target>, so Claude Code's state was not moved`                                                                                           | `~/.claude` is a link, not a real directory  |
| `~/.config/claude is not a directory molt can move into, so Claude Code's state was not moved`                                                                       | the config dir is a symlink or a file        |
| `~/.claude/.claude.json and ~/.claude.json both exist, and molt will not choose between them, so Claude Code's state was not moved`                                  | there are two `.claude.json` files           |
| `<new dir> holds nothing, and CLAUDE_CONFIG_DIR named <old dir>, which exists: Claude Code's state may be there. Move it into <new> by hand, or declare <old> again` | the declared config dir changed after a move |

If something fails after the backup was made, the not-published line drops ", and nothing else was changed", and the line before it names the copies.

### The variable follows the state

Molt publishes `CLAUDE_CONFIG_DIR` only once the state is where it points: when the move succeeded in this run; when `~/.claude` and `~/.claude.json` are already gone and the config dir exists; or on a sleeve Claude Code has never run on, with nothing in `$HOME` and no config dir, where Molt creates the config dir and publishes. Anything at all at `~/.claude` or `~/.claude.json`, whether a file, a directory or a link, holds publication back.

When the move is refused, for any reason, Molt writes nothing in that run in either directory: no env file, GUI file, link, statusLine or hook. The refusal says the variable was not published, and the claude liberator fails while the resleeve carries on with the other liberators, so agent homes still render.

The order matters. Published first, the variable would start the next Claude empty in the new directory, with a new login and a new `.claude.json`, and the later move would meet a non-empty target: two copies of the state, neither of them whole.

### Where the variable is published

| File                                                                                                  | Reaches                                                                    |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `~/.config/molt/env.sh`, holding `export CLAUDE_CONFIG_DIR="<dir>"`                                   | every zsh, through the `zshenv` line below, including ssh and TTY logins   |
| `~/Library/LaunchAgents/com.molt.claude-config-dir.plist` (macOS), label `com.molt.claude-config-dir` | GUI apps: at login it runs `/bin/launchctl setenv CLAUDE_CONFIG_DIR <dir>` |
| `~/.config/environment.d/claude.conf` (Linux), holding `CLAUDE_CONFIG_DIR=<dir>`                      | the user session: on GNOME, every GUI and terminal child                   |

Each carries a `.molt-rendered` digest sidecar. Your config repo's `zshenv` sources the env file when it exists, which is safe on a sleeve that has not moved:

```sh
[ -r ~/.config/molt/env.sh ] && . ~/.config/molt/env.sh
```

The GUI file takes effect at the next login, because Molt does not call `launchctl` or `systemctl` itself, so log out and back in after the move. Nothing Molt renders for this names a Molt checkout: the hook script, the env file and the GUI file refer only to `~/.config/molt/`, the config dir, `$HOME` and, in the hook script, the agents root `MOLT_AGT_DIR`, so they do not depend on where Molt is installed.

### After the move

Start each agent from its home, as [Starting an agent](#starting-an-agent) says. The native installer's own paths stay where they are and are not clutter: `~/.local/bin/claude`, `~/.local/share/claude`, `~/.local/state/claude` and `~/.cache/claude`. `CLAUDE_CONFIG_DIR` does not move them. Leftovers from an npm-era install, `~/.cache/claude-cli-nodejs` and `~/.npm`, are not Claude Code's state either; the move leaves them, and removing them is a separate step. npm's own cache lives in `~/.cache/npm`, under `XDG_CACHE_HOME` where that is set, through the `~/.npmrc` the npm liberator renders, because the status line runs through `npx`, which would otherwise write `~/.npm` again at every refresh, so once `~/.npmrc` names the new cache, `~/.npm` can be removed for good.

### A Claude started in $HOME, below a home, or without the config dir, is refused

Once the variable is published, Molt also merges a `UserPromptSubmit` hook into the user settings, changing that key and no other, as it does for the statusLine, and the agents liberator writes the same hook into each home's `.claude/settings.json`, beside any hooks the role's profile has. The hook runs `~/.config/molt/claude-home-guard.sh`, a POSIX `sh` script that needs nothing beyond `sh`, so it does not depend on `molt` being on `PATH` when a prompt is sent. It checks the directory the session was started in, `CLAUDE_PROJECT_DIR`, which Claude Code sets on the hook's process. It never reads the hook's JSON input, whose `cwd` follows every `cd`, so a `cd` inside a command, or a worktree Claude enters, never trips it. Paths are compared by where they lead, so a symlinked spelling of `$HOME` is still `$HOME`. When the session was started in `$HOME`, the script prints this on stderr and exits 2, which blocks the prompt:

```
launch from an agent home: molt agent list
```

It blocks a session started in `MOLT_AGT_DIR` but not in an agent home itself the same way. At the agents root it prints `launch from an agent home, not the agents root: molt agent list`. Below a home, such as in its `work/`, it names the home to launch from:

```
launch from the agent home itself: cd <home>
```

A session started in an agent home itself passes, as does one started anywhere else, so project agents are unaffected. A directory directly in `MOLT_AGT_DIR` is taken for a home, whether or not an agent is declared there. If the hook has no `CLAUDE_PROJECT_DIR` or no `HOME`, or either is not an absolute path, the script exits 1 with a line that says so, eg `claude-home-guard: the hook has no CLAUDE_PROJECT_DIR, so the launch directory was not checked`, which shows the line and blocks nothing.

The guard also blocks a session that did not get the sleeve's config dir. A Claude started from a shell opened before the move, or from an app started before you logged back in, has no `CLAUDE_CONFIG_DIR`, so it starts afresh in `$HOME`, with a second login and new `~/.claude` and `~/.claude.json`, and it never reads the user settings, which are in the config dir it missed. The home's own settings are read from the directory the session starts in, whatever config dir it uses, so the home's copy of the hook runs, and the guard lives in `~/.config/molt/`, outside any config dir, so it is there either way. Hooks get the session's own environment, so the guard sees what the session saw:

```
this Claude Code did not get CLAUDE_CONFIG_DIR (want <config dir>): quit it, open a new shell, or log out and in, and relaunch from the home
```

A session whose `CLAUDE_CONFIG_DIR` names another directory gets `this Claude Code has CLAUDE_CONFIG_DIR <dir>, not <config dir>` and the same advice. Directories are compared by where they lead, so a symlinked spelling of the config dir passes. Such a session shows the trust dialog for the home first, since its fresh state has trusted nothing, and hooks in a project's settings run only once it is trusted. Its first prompt is then refused, but by then Claude Code has written its fresh state in `$HOME`, the login included, and `molt doctor` reports it, as below: quit the session, remove what it wrote, and relaunch from a new shell.

## What molt doctor reports

`molt doctor`'s check of the enabled liberators shows `not installed: claude`, followed by the first three lines the claude liberator's check printed, as it printed them, under the `not installed:` line; the agents liberator's the same. The tables below leave off the `Zen:` prefix, and the claude liberator's own `claude:`. Below, `~/.config/claude` stands for the sleeve's config dir, which is still `~/.claude` on a sleeve that has not moved.

On a sleeve that has declared `MOLT_CLAUDE_CONFIG_DIR`, the claude liberator reports:

| Report                                                                                                                                                                      | Means                                                                                                                                                             | What to do                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `MOLT_CLAUDE_CONFIG_DIR could not be read: <why>`, or a line naming what is wrong with a declared path                                                                      | `vars.sh` cannot be read or sourced, or a declared path is one Molt refuses, as [Declaring the variable](#declaring-the-variable-is-what-moves-a-sleeve) sets out | fix `vars.sh`, or `MOLT_AGT_DIR` where you export it                                                                |
| `Claude Code's state is still in ~/.claude and ~/.claude.json, and this sleeve's config dir is ~/.config/claude: quit every Claude Code, then run molt resleeve to move it` | the move is pending                                                                                                                                               | what it says, from a plain terminal                                                                                 |
| `CLAUDE_CONFIG_DIR is not set where molt runs; ~/.config/molt/env.sh sets it in a shell that sources it`                                                                    | the state has moved, but the shell molt ran in did not get the variable                                                                                           | open a new shell; if it persists, check the `zshenv` line                                                           |
| `CLAUDE_CONFIG_DIR is <X>, not this sleeve's config dir <dir>`                                                                                                              | the environment carries another value, eg one from before the declared dir changed                                                                                | open a new shell after `molt upgrade`; if it persists, find what else sets it                                       |
| `~/.claude is present while the config dir is ~/.config/claude: a launch path missed CLAUDE_CONFIG_DIR, or a move did not finish`                                           | something started Claude without the variable and it wrote fresh state in `$HOME`, or a move stopped part way; the same line reports `~/.claude.json`             | find the launch path that missed it, eg a GUI app started before you logged back in, or a shell that skips `zshenv` |
| `~/.claude is a symlink to <target>`                                                                                                                                        | a link sits at the old path, and Molt never makes one                                                                                                             | find what made it                                                                                                   |
| `~/.config/claude, this sleeve's config dir, does not exist yet`                                                                                                            | Claude Code has not run on this sleeve, so there was no state to move                                                                                             | `molt upgrade` creates it                                                                                           |
| `<path> is missing`, or `<path> differs from its template or this sleeve's vars.sh`                                                                                         | the env file, GUI file or hook script is not what Molt would render                                                                                               | `molt upgrade`                                                                                                      |
| `~/.config/molt/claude-home-guard.sh refuses launches under <old root>, but MOLT_AGT_DIR is <root>: re-run molt upgrade`                                                    | `MOLT_AGT_DIR` changed after the guard was rendered                                                                                                               | `molt upgrade`                                                                                                      |
| `~/.config/molt/claude-home-guard.sh checks sessions for config dir <old dir>, but this sleeve's is <dir>: re-run molt upgrade`, or `for no config dir`                     | the guard was rendered with another config dir, or before it checked one                                                                                          | `molt upgrade`                                                                                                      |
| `~/.config/molt/claude-home-guard.sh is not executable`                                                                                                                     | the hook script cannot run                                                                                                                                        | `molt upgrade`                                                                                                      |
| `~/.config/claude/settings.json has no home-launch hook`, `has a different home-launch hook`, `is missing` or `is empty`                                                    | the user settings lack the hook, or carry another                                                                                                                 | `molt upgrade`                                                                                                      |
| `~/.config/claude/settings.json is not a JSON object`, or `is a symlink to <target>; it must not be linked, so molt will not write it`                                      | Molt will not write the hook into that file                                                                                                                       | make it a regular file holding a JSON object, then `molt upgrade`                                                   |
| `~/.config/claude/settings.json cannot be checked: jq is not installed`                                                                                                     | Molt reads and merges the user settings with `jq`                                                                                                                 | install `jq`                                                                                                        |

A fault in `vars.sh` or in a declared path is reported alone, because nothing past it can be checked. While the move is pending, the claude liberator reports the pending move rather than the unset variable. Until a sleeve declares the variable it reports none of these, and an unset `CLAUDE_CONFIG_DIR` there is not a fault.

On every sleeve, whether or not it has declared the variable:

| Report                                                                                           | Means                                                                                                                                                                                            | What to do                                                               |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| `~/.config/claude/CLAUDE.md is missing`, `is a broken symlink`, or `points at <X>, not <Y>`      | the user-scope link is not made yet, or is wrong; the same lines cover `AGENTS.md`                                                                                                               | `molt upgrade`                                                           |
| `~/.config/claude/CLAUDE.md is not a symlink`                                                    | a regular file is where the link goes                                                                                                                                                            | `molt upgrade`, which backs the file up first                            |
| `agents: <name>: <home>/<file> is missing`, or `is stale`, for any rendered file                 | the home has not been rendered, or its role templates or host overlay changed since it was, or, on a sleeve that declares its config dir, its `settings.json` does not run the home-launch guard | `molt upgrade`                                                           |
| `agents: <name>: <home>/memory is missing`, or `<home>/work is missing`                          | one of the agent's own directories is gone                                                                                                                                                       | `molt upgrade` creates it again, empty                                   |
| `agents: <name>: role <role> is not defined: there is no <user repo>/config/agents/roles/<role>` | the entry names a role your config repo does not define                                                                                                                                          | add the role, or fix the entry                                           |
| `agents: <name>: role <role> has no <user repo>/config/agents/roles/<role>/<template>`           | the role's directory lacks one of its templates                                                                                                                                                  | add the template                                                         |
| `agents: molt.toml: an [[agent]] entry has no role`                                              | an entry without its one required key                                                                                                                                                            | add the role                                                             |
| `agents: molt.toml: role <role> is declared by more than one [[agent]] entry`                    | two entries for one role                                                                                                                                                                         | keep one                                                                 |
| `agents: molt.toml: the <role> entry writes a name; an agent is named <hostname>-<role>`         | an entry sets the name Molt derives                                                                                                                                                              | remove the name                                                          |
| `agents: molt.toml: the <role> entry names harness codex; claude is the only one`                | a harness Molt does not render for                                                                                                                                                               | remove `harness`, or set it to `"claude"`                                |
| `agents: molt.toml: the <role> entry has enabled = <value>, not true or false`                   | `enabled` is not a boolean                                                                                                                                                                       | set it to `true` or `false`                                              |
| `agents: MOLT_AGT_DIR, <root>, ...`, or another line naming what is wrong with the agents root   | the root is one Molt refuses, as [Declaring an agent](#declaring-an-agent) sets out; reported last, after any molt.toml faults, on a sleeve with agents to home, and nothing past it is checked  | fix `MOLT_AGT_DIR` or `MOLT_PRJ_DIR` where you export them, or `vars.sh` |

The native installer's paths listed above are not faults.

## Fence and wall

Claude Code merges settings from several levels. From the highest precedence down: managed settings, `--settings`, `.claude/settings.local.json`, `.claude/settings.json` (the home's), and the user settings in the config dir. `permissions.allow`, `deny` and `ask` merge across the levels, and a deny wins at every level.

The home's `.claude/settings.json` is a fence: it carries the role's permission profile, but it sits in a directory the agent works in, and the agent could edit it. The managed-settings file is the wall: root owns it, so the agent cannot change it, and since a deny wins at every level, a deny there holds whatever the levels below allow. It lives at `/Library/Application Support/ClaudeCode/managed-settings.json` on macOS and `/etc/claude-code/managed-settings.json` on Linux, with drop-in files in `managed-settings.d/` beside it.

`ops` and `docs` get the fence and the sandbox. With `sandbox.enabled`, sandboxed Bash cannot write any `.claude` settings, hooks, shell rc files, `.git` config or the config dir, with no exemption. The sandbox binds sandboxed commands only, and it has two escape hatches, which the `ops` and `docs` profiles both close. A command matching `sandbox.excludedCommands` runs with no filesystem restrictions and no network proxy, so the profiles list no excluded commands. A command that fails in the sandbox can be retried outside it on approval unless `sandbox.allowUnsandboxedCommands` is `false`, so the profiles set it to `false`. Hooks, Edit and Write run outside the sandbox, and Edit and Write only prompt.

Every profile denies `Read()` of `~/.ssh/id_*` and `~/.aws/credentials`. A `Read()` deny refuses the Read tool, and also a Bash command whose text names the path, before it runs, but not a command that reaches the file another way. `ops` and `docs` also carry `sandbox.credentials.files` deny entries for `~/.ssh` and `~/.aws/credentials`, which bind what the sandbox runs, not the command's text. Tested on 21 Oct 2026 with Claude Code 2.1.306 under macOS Seatbelt, in a scratch home: with those entries alone, sandboxed Bash got `Operation not permitted` reading both files, `~/.ssh/config`, and the listing of `~/.ssh`, so an `ssh` from `ops` or `docs` runs with no keys and no config. The same run on Linux, under bubblewrap, is still owed. `sysadm` has no sandbox, so its `Read()` denies, its contract and the [managed floor](#managed-floor) stand between it and those files.

`sysadm` cannot be sandboxed, because changing the machine is its job, so its permissions live in the fence, and the [managed floor](#managed-floor) holds its two credential denies where it cannot edit them.

Claude Code is the only harness Molt renders homes for. A dedicated Unix account per agent would be a stronger boundary than any of this, and stays an option for later.

## Managed floor

The floor is two `Read()` denies, `Read(~/.ssh/id_*)` and `Read(~/.aws/credentials)`, placed where a `sysadm` agent cannot reach them. The `sysadm` fence carries the same two rules: the fence is the agent's own view of its limits, and the floor holds them at a layer it cannot edit. What the floor denies is the user's decision, and Molt derives nothing.

The user stack holds them in `config/agents/roles/sysadm/floor.json`: one JSON object whose only key is `permissions`, whose only key is `deny`, an array of strings. It is not a template. On a sleeve whose `molt.toml` enables an `[[agent]]` with `role = "sysadm"`, the agents liberator copies the file's bytes unchanged into `managed-settings.d/molt-sysadm.json` in the managed-settings dir, `/Library/Application Support/ClaudeCode` on macOS and `/etc/claude-code` on Linux, with a `<SIDECAR>` sidecar beside it, both root-owned and mode 644, through `sudo`. Molt writes nothing else there. A sleeve with no enabled `sysadm` agent gets no floor.

A managed deny binds every Claude Code session on the sleeve, not only the agent's, and a deny wins at every level, so the user's own sessions there cannot read those two files either, whatever a project's or the user's settings allow. That is the point. Read them from a plain terminal. Like any `Read()` deny, the floor refuses the Read tool and a Bash command whose text names the path, not a command that reaches the file another way.

Writing the floor needs root, so `molt upgrade` on a `sysadm` sleeve may stop part way at a `sudo` password prompt, when the agents liberator installs or updates the floor. It asks only when the drop-in is missing or its bytes differ from `floor.json`'s, so any edit to `floor.json`, whitespace included, asks again at the next upgrade. With no `sudo`, or a refused one, the liberator fails, naming it, and writes nothing into the managed dir.

`molt agent config <hostname>-sysadm` lists the drop-in in the managed layer, above the local, home and user layers, and tags the two rules `managed`:

<EXAMPLE>

`molt doctor` check 14 warns on a `sysadm` sleeve whose floor is missing or stale, and on a sleeve with no `sysadm` agent that still carries a floor Molt wrote; otherwise it passes.

When a sleeve no longer enables a `sysadm` agent, the next `molt upgrade` removes the drop-in and its sidecar, through `sudo`. Molt removes only a `molt-sysadm.json` whose sidecar it wrote: one without that sidecar was put there by someone else, and is left in place and reported.
