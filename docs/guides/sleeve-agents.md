# Sleeve Agents

A sleeve agent is a local agent, Claude Code for now, that does machine work on one sleeve as you: system administration, operations, or documenting the machine. Molt gives each one a home: a directory declared in the sleeve's `molt.toml` and rendered from a role kept in your config repo, holding the agent's instructions, its permissions and its memory. The agent runs in its home.

Without a home, an agent like this runs from `$HOME`. There it has no instruction file of its own and no project-level permissions, it shares a memory slot with every other session started in `$HOME`, and Claude Code's own files sit loose in the home directory. So Molt also moves Claude Code's state out of `$HOME`, once per sleeve, and refuses a Claude started there.

## Sleeve agents and project agents

|            | Sleeve agent                                               | Project agent                      |
| ---------- | ---------------------------------------------------------- | ---------------------------------- |
| Works on   | one machine                                                | one project                        |
| Runs in    | its home, `$MOLT_AGT_DIR/<hostname>-<role>/`               | the project's working tree         |
| Named      | `<hostname>-<role>`, eg `kovacs-sysadm`                    | `<project>-<suffix>`, eg `molt-vc` |
| Bounded by | its role contract and permission profile, rendered by Molt | the project and Intent             |

This guide is about sleeve agents. A project agent is a session run inside an Intent project, which already gives it instructions, permissions and memory, so Molt does not manage it.

## Naming

### Sleeve agents

A sleeve agent is always named `<hostname>-<role>`: `rhadamanth-sysadm`, `kovacs-ops`, `gyges-docs`. The hostname is the sleeve's short hostname, the name of its `instances/<hostname>/` directory, and the role is one of the roles below. You never write the name: Molt derives it from the `[[agent]]` entry, so it cannot be mistyped.

gyges' agent is still called `gyges-infra`, from before this convention. It becomes `gyges-sysadm` when gyges is moved, which happens later.

### Hosts

Physical machines take their names from the Hyperion Cantos: rhadamanth, gyges, shrike, yggdrasil, farcaster. Virtual machines take Altered Carbon envoy and sleeve names: kovacs.

### Project agents

A project agent is named `<project>-<suffix>`, eg `molt-vc` or `gtools-ic`. Every Intent project uses the same six suffixes, named on 21 Oct 2026. Molt's whiteboard roster, [`intent/whiteboard/README.md`](../../intent/whiteboard/README.md), is the record, and this table repeats it:

| Suffix | Name              |
| ------ | ----------------- |
| `sc`   | Supervisor Claude |
| `vc`   | Validation Claude |
| `cc`   | Control Claude    |
| `ic`   | Interface Claude  |
| `ac`   | Authoring Claude  |
| `dc`   | DevX Claude       |

Molt itself runs `vc`, `cc` and `dc`. A suffix names a project session's job and a role names a sleeve agent's, so `dc`, DevX Claude, is a project agent, while `docs` is a sleeve role.

## Roles

A role is a directory under your config repo's `config/agents/roles/`, so the set is yours to define. The convention is three roles, the same on every sleeve:

| Role     | For                          | Sandbox                     |
| -------- | ---------------------------- | --------------------------- |
| `sysadm` | system administration        | off: it cannot be sandboxed |
| `ops`    | operations and monitoring    | on                          |
| `docs`   | documentation of the machine | on                          |

`sysadm` may change the machine, which is why it cannot run sandboxed. `ops` observes and diagnoses, and writes only inside its home. Every agent's work goes in its home's `work/` directory. What each role may and may not touch is set out in its contract, `config/agents/roles/<role>/AGENTS.md.tmpl`, and its permission profile beside it.

## Three layers

| Layer         | Where                                             | Owned by       | Holds                                                                                         |
| ------------- | ------------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------- |
| Role source   | your config repo's `config/agents/roles/<role>/`  | you, in git    | the role contract `AGENTS.md.tmpl` and the permission profile `settings.json.tmpl`            |
| Agent home    | `$MOLT_AGT_DIR/<hostname>-<role>/`                | Molt, rendered | `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `memory/`, `work/`                         |
| Harness state | `$XDG_CONFIG_HOME/claude`, as `CLAUDE_CONFIG_DIR` | Claude Code    | credentials, transcripts, plugins and user settings: one per machine, shared by every session |

The agent home is both the agent's config and the directory it runs in. Claude Code reads project-level settings from `.claude/` in its working directory, so starting the agent in its home is what applies the home's settings: the two coincide by construction. The home's settings set `autoMemoryDirectory` to `<home>/memory`, so the agent's memory lives in its home rather than under a working-directory slug in the harness state.

### What a session in the home reads

A session started in a home reads three layers of instructions, widest first:

| Layer      | File                                                                        | Carries                                                                                             |
| ---------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| User scope | `CLAUDE.md` and `AGENTS.md` in the config dir, linked from `config/claude/` | the rules every session on every sleeve follows                                                     |
| Role       | the home's `AGENTS.md`, from `config/agents/roles/<role>/AGENTS.md.tmpl`    | the role's own text: who the agent is, what the role is for, what it may touch, where its work goes |
| Host       | `instances/<hostname>/agents/<role>.md`, appended to the home's `AGENTS.md` | facts true on this machine only: its stack layout, what is installed, its known issues              |

The home's `CLAUDE.md` is a one-line `@AGENTS.md` stub. Put each instruction in exactly one layer: a rule that holds everywhere belongs in user scope, and the role contract does not repeat it.

When your config repo has `config/claude/CLAUDE.md` and `AGENTS.md`, Molt links them into the config dir on every sleeve, moved or not, so the cross-session rules are the same everywhere; a regular file already at either path is backed up before the link replaces it. Project agents read these files too.

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

Homes live under `MOLT_AGT_DIR`, which defaults to `$HOME/Devel/agt`: a peer of the `prj/` and `cfg/` directories that `MOLT_PRJ_DIR` and `MOLT_CFG_DIR` name. Export it from your `zshenv` beside `MOLT_PRJ_DIR`, so your shells and your agents see the same value. An agent runs as you, and Unix has no convention for an interactive agent that runs as its user: `/opt`, `/var/lib` and `/srv` are for software and for services under their own accounts.

## What Molt renders

On `molt resleeve` and `molt upgrade`, the `agents` liberator renders each enabled agent's home:

| In the home             | Rendered from                                                                                               |
| ----------------------- | ----------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`             | `config/agents/roles/<role>/AGENTS.md.tmpl`, followed by `instances/<hostname>/agents/<role>.md` if present |
| `CLAUDE.md`             | a one-line `@AGENTS.md` stub                                                                                |
| `.claude/settings.json` | `config/agents/roles/<role>/settings.json.tmpl`, with `autoMemoryDirectory` set to `<home>/memory`          |
| `memory/`, `work/`      | created empty, and the agent's from then on: Molt never writes to them again                                |

Templates go through Molt's usual renderer (see [Template System](templates.md)), so only `MOLT_*` variables are substituted and any other `$VAR` is left as written. Besides the sleeve's own instance variables, an agent's templates can use:

| Variable          | Value                            |
| ----------------- | -------------------------------- |
| `MOLT_HOSTNAME`   | the sleeve's short hostname      |
| `MOLT_AGENT_NAME` | `<hostname>-<role>`              |
| `MOLT_AGENT_ROLE` | the role                         |
| `MOLT_AGENT_HOME` | the home, `$MOLT_AGT_DIR/<name>` |

A contract that names a `MOLT_*` variable for its reader, rather than wanting its value, should write the name without the `$`.

Each rendered file has a `.molt-rendered` sidecar recording a digest of its sources (see [Detecting stale renders](templates.md#detecting-stale-renders)). Re-rendering is a no-op while the digests match. A change to the role's templates or to the host's overlay makes the home stale, and the next `molt upgrade` re-renders it. A role your config repo does not define is a fault that names the role and the path Molt looked in.

A home renders whether or not the sleeve's Claude Code state has moved (see below). That is deliberate: on a sleeve whose agent still runs from `$HOME`, the home can be rendered first, so the agent can copy its own files in before its state moves.

The first time you start Claude in a home, accept the workspace-trust prompt: Claude Code ignores a project-level `autoMemoryDirectory` until the workspace is trusted.

## Listing and inspecting agents

```bash
molt agent list
molt agent config <name>
```

`molt agent list` prints each declared agent: its name, role and home, whether it is enabled, and whether its rendered files are current.

`molt agent config <name>` prints the agent's home and role, the currency of each rendered file, and its effective permissions: `permissions.allow`, `deny` and `ask` merged from the managed settings, the user settings and the home's `.claude/settings.json`, each rule tagged with the layer it came from. An undeclared name fails and lists the declared ones.

**PLACEHOLDER (molt-cc, WP02): sample output of `molt agent list` and of `molt agent config kovacs-sysadm`.**

There is no launch command. To start an agent, start Claude in its home:

```bash
cd "$MOLT_AGT_DIR/kovacs-sysadm" && claude
```

## Moving Claude Code's state out of $HOME

By default Claude Code keeps its state in `~/.claude` and `~/.claude.json`. `CLAUDE_CONFIG_DIR` relocates both: every `~/.claude` path, and `~/.claude.json` as well, which Claude Code's documentation does not say but a test on 21 Oct 2026 showed. Molt moves a sleeve's state once, to the directory the sleeve declares (by convention `$XDG_CONFIG_HOME/claude`), and from then on keeps it there: no `~/.claude` at all, and no compatibility symlink.

### Declaring the variable is what moves a sleeve

A sleeve opts in by declaring `MOLT_CLAUDE_CONFIG_DIR` in its `instances/<hostname>/vars.sh`:

```bash
export MOLT_CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
```

Until it does, the sleeve keeps today's behaviour: no move, no env or GUI file, no `$HOME` hook. Only the user-scope links described above are made either way. Once it does, the next `molt upgrade` or `molt resleeve` runs the move, so declare it when the sleeve is ready to move, and run that upgrade as the next section says.

### Quit every Claude first, and use a plain terminal

A live session cannot survive its own state moving: `mv ~/.claude` under a running Claude takes its transcript, credentials and state out from under it. Run the upgrade that moves a sleeve from a plain terminal, with every Claude Code process on the sleeve quit. That includes Claude in Chrome: while Chrome runs with the extension, its native host (`~/.local/bin/claude --chrome-native-host`) is a `claude` process, so quit Chrome as well.

### What the move does, and when it refuses

When `~/.claude` is a real directory and the config dir does not exist yet, the claude liberator backs up `~/.claude` and `~/.claude.json`, then moves both into the config dir. The backup is a clone made beside the target, never in `$HOME`: `cp -cR` on APFS and `cp -a --reflink=auto` on Linux, so even a large `~/.claude` costs little or no extra space where the filesystem can clone.

**PLACEHOLDER (molt-cc, WP01): where the backup lands and what it is called.**

It refuses, and moves nothing, when:

- any Claude Code process is running; the refusal names the processes
- the config dir exists and is not empty; the refusal names what is in it, and Molt never merges the two

**PLACEHOLDER (molt-cc, WP01): the exact text of each refusal.**

### The variable follows the state

Molt publishes `CLAUDE_CONFIG_DIR` only once the state is where it points: when the move succeeded in this run, or when `~/.claude` is already gone and the config dir exists. Anything at all at `~/.claude`, whether a file, a directory or a link, holds publication back.

When the move is refused, for any reason, Molt writes nothing in that run in either directory: no env file, GUI file, link, statusLine or hook. The refusal says the variable was not published, and the claude liberator fails while the resleeve carries on with the other liberators, so agent homes still render.

The order matters. Published first, the variable would start the next Claude empty in the new directory, with a new login and a new `.claude.json`, and the later move would meet a non-empty target: two copies of the state, neither of them whole.

### Where the variable is published

| File                                          | Reaches                                                                  |
| --------------------------------------------- | ------------------------------------------------------------------------ |
| `~/.config/molt/env.sh`                       | every zsh, through the `zshenv` line below, including ssh and TTY logins |
| a LaunchAgent plist (macOS)                   | GUI apps: it runs `launchctl setenv CLAUDE_CONFIG_DIR` at login          |
| `~/.config/environment.d/claude.conf` (Linux) | the user session: on GNOME, every GUI and terminal child                 |

**PLACEHOLDER (molt-cc, WP01): the LaunchAgent's label and the plist's path.**

Each carries a `.molt-rendered` digest sidecar. Your config repo's `zshenv` sources the env file when it exists, which is safe on a sleeve that has not moved:

```sh
[ -r ~/.config/molt/env.sh ] && . ~/.config/molt/env.sh
```

The GUI file takes effect at the next login, because Molt does not call `launchctl` or `systemctl` itself, so log out and back in after the move. Nothing Molt renders for this names a Molt checkout: the hook script, the env file and the GUI file refer only to `~/.config/molt/`, the config dir and `$HOME`, so they do not depend on where Molt is installed.

### After the move

Start each agent from its home, and accept workspace trust the first time. The native installer's own paths stay where they are and are not clutter: `~/.local/bin/claude`, `~/.local/share/claude`, `~/.local/state/claude` and `~/.cache/claude`. `CLAUDE_CONFIG_DIR` does not move them. Leftovers from an npm-era install, `~/.cache/claude-cli-nodejs` and `~/.npm`, are not Claude Code's state either; the move leaves them, and removing them is a separate step.

### A Claude started in $HOME is refused

Once the variable is published, Molt also merges a `UserPromptSubmit` hook into the user settings, changing that key and no other, as it does for the statusLine. The hook runs `~/.config/molt/claude-home-guard.sh`, a POSIX `sh` script that needs `jq` but not `molt`, so it does not depend on `molt` being on `PATH` when a prompt is sent. When the session's working directory is `$HOME`, it blocks the prompt with:

```
launch from an agent home: molt agent list
```

Any other working directory passes, so project agents are unaffected.

## What molt doctor reports

`molt doctor` reports these through the claude and agents liberators' checks.

**PLACEHOLDER (molt-cc, WP01 and WP02): the exact wording of each report, to replace the descriptions in the first column.**

| Report                                                                       | Means                                                                                                           | What to do                                                                                                          |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE_CONFIG_DIR` is unset in the environment molt runs in                 | the shell molt ran from did not get the variable: the env file is missing, or `zshenv` does not source it       | open a new shell; if it persists, check the `zshenv` line and that `~/.config/molt/env.sh` exists                   |
| `~/.claude` or `~/.claude.json` is present while the config dir is elsewhere | something started Claude without the variable, and it wrote fresh state in `$HOME`                              | find the launch path that missed it, eg a GUI app started before you logged back in, or a shell that skips `zshenv` |
| the env file, GUI file or hook is missing or stale                           | what is published no longer matches what Molt would render                                                      | `molt upgrade`                                                                                                      |
| a user-scope link is pending, broken or missing                              | your config repo has `config/claude/CLAUDE.md` or `AGENTS.md`, and the config dir does not link to it           | `molt upgrade` makes the link, backing up a regular file it replaces                                                |
| an agent home is missing or stale                                            | an enabled agent has not been rendered, or its role templates or host overlay changed since it was              | `molt upgrade`                                                                                                      |
| a role is undefined                                                          | an `[[agent]]` names a role with no directory under `config/agents/roles/`; the report names the path looked in | add the role, or fix the entry                                                                                      |

The native installer's paths listed above are not faults.

## Fence and wall

Claude Code merges settings from several levels. From the highest precedence down: managed settings, `--settings`, `.claude/settings.local.json`, `.claude/settings.json` (the home's), and the user settings in the config dir. `permissions.allow`, `deny` and `ask` merge across the levels, and a deny wins at every level.

The home's `.claude/settings.json` is a fence: it carries the role's permission profile, but it sits in a directory the agent works in, and the agent could edit it. The managed-settings file is the wall: root owns it, so the agent cannot change it, and since a deny wins at every level, a deny there holds whatever the levels below allow. It lives at `/Library/Application Support/ClaudeCode/managed-settings.json` on macOS and `/etc/claude-code/managed-settings.json` on Linux, with drop-in files in `managed-settings.d/` beside it.

`ops` and `docs` get the fence and the sandbox. With `sandbox.enabled`, sandboxed Bash cannot write any `.claude` settings, hooks, shell rc files, `.git` config or the config dir, with no exemption. Edit and Write are not sandboxed; they prompt instead.

`sysadm` cannot be sandboxed, because changing the machine is its job, so for now its permissions live only in the fence. A managed deny floor for `sysadm` is planned (ST0006 WP06): Molt will render the role's `permissions.deny` into a root-owned drop-in, `managed-settings.d/molt-sysadm.json`, through the `sudo` path the `system` liberator already uses, and `molt agent config` will show those rules as managed. What the floor denies is the user's decision; WP06 supplies the mechanism.

Claude Code is the only harness Molt renders homes for. A dedicated Unix account per agent would be a stronger boundary than any of this, and stays an option for later.
