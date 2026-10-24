# BL0001: So You Want to Run a Local Agent

**Date:** 2026-10-21
**Status:** Draft brief. hv writes the piece; these are the working notes for it.
**Thread:** ST0006 WP07

## Precis

An agent on your own machine, running as you, is the most useful way to run one and the most exposed. It can look at the machine instead of being told about it, and it holds your keys while it looks. The piece argues that the exposure is managed not by trusting the model more, or by using it less, but by organising the agent: a name that says which machine and which job, a home that is its configuration and its working directory at once, a contract that says what it is for and what it may touch, permissions in layers where the layer the agent cannot edit wins, and all of it kept as configuration in git so every machine gets the same agent. The practice is general. Molt is one worked example of it, and the notes say where the example begins.

## Audience

Someone who runs their own machines (a laptop, a VM, a box at home), already uses an agentic CLI for code, and wants it doing machine work too: system administration, operations, documenting the machine. Comfortable with a shell, git and config files. Not the reader who only uses the chat app; not the operator of agent swarms, though the principles reach that far.

## Title candidates

- Organising a Local Agent (hv's)
- So You Want to Run a Local Agent
- A Name, a Home and a Contract
- Give Your Agent a Home
- An Agent on Your Own Machine, Organised

## Notation

Bullets come in kinds, so the notes scan:

- A plain bullet is a point to make.
- `eg:` is an example to reach for.
- `check:` is a fact to verify before it goes to print, with where it came from. Every Claude Code `check:` was read against the docs on 21 Oct 2026: `(docs: <page>)` names the page at `code.claude.com/docs/en/<page>`, and the bullet says where the docs differ or are silent. The docs change with each release, so read them again before publication.
- `Molt:` is the worked example. It marks where the general advice ends.

## Structure

### 1. So you want to run an agent on your machine

- Define machine work: system administration, operations and monitoring, documenting the machine. Distinct from coding in a repository, where the project already bounds the agent.
- The naive first run: open a terminal in `$HOME`, type the agent's name, ask it to fix something. It works, which is the problem: it has no instruction file, no project-level permissions, a memory slot shared with every other session started from `$HOME`, and it leaves the harness's files loose in your home directory.
- eg: the kovacs moment, 21 Oct 2026. A local agent on an Ubuntu VM running out of `$HOME`, LLM files left in the home directory, "a bit too risky for my liking". The ask that followed: a way to install, name, configure and manage a local agent safely.
- The piece's promise: the risk is managed by organising the agent, not by trusting the model more or using it less.
- The premise, stated so nobody reads past it: the agent runs as you, on your machine, with your credentials. An account per agent is a stronger boundary and belongs in the "later" section, not here.

### 2. Why is that a good thing?

- The agent is where the context is. On the machine it can look (disk, logs, config, what is installed) instead of being told, and most of the cost of asking anyone for help is describing the machine.
- The grind it is good at: why a service is down, what is eating the disk, upgrades, config drift between machines, the runbook nobody writes, keeping a machine's own documentation current.
- Memory: an agent with persistent memory learns the machine's quirks and stops rediscovering them. eg: the backup tool's run history that lists failed copies which were the owner's own interruptions, while the copy in flight is invisible to it; the process probe that matches nothing while the app is plainly running, asked from inside the very terminal window it could not see.
- A colleague on the box, reachable by message: ask the agent on the home server what state the machine is in instead of logging in to look.
- What the chat app cannot do: it cannot see your machine, and you would not want it to.
- The honest counterweight, said here before the risks section earns it: the machine is also where your keys are.

### 3. What are the risks?

- It runs as you: your uid, your ssh keys, your credentials, your git identity, your sudo. The blast radius is your account, and on a single-user machine that is the machine. Nor are credentials per agent: the harness keeps one state per machine, shared by every session on it.
- It can change the machine. For the system-administration job that is the point, so the risk cannot be designed out, only bounded.
- It reads untrusted content: logs, web pages, mail, files other people wrote. Prompt injection arrives through the work, not through the chat.
- It can edit its own fence: the permission settings that live in its working directory are files it can write, and a sandbox narrows that less than it seems. check: on Claude Code, inside the directories a sandboxed command may write to, it still cannot write the files the harness loads configuration from: the `.claude` settings files, its skills, agents, commands and hooks directories and `.mcp.json`, in the working directory and above it; shell rc files, `.gitconfig` and `.git`'s `hooks` and `config`, in the working directory; most of the config dir, with `~/.claude.json` and the credential store. No `allowWrite` entry or Edit allow rule lifts that. But it binds sandboxed commands only: a command in `sandbox.excludedCommands` runs with no filesystem restrictions, a failed command can be retried outside the sandbox on approval unless `allowUnsandboxedCommands` is `false`, hooks run outside it, and Edit and Write follow the permission rules instead (docs: sandboxing). ST0006's context said "no exemption", which holds for allow rules and not for these.
- State sprawl: by default the harness keeps credentials, transcripts, settings and memory in `$HOME`, and every session started from `$HOME` shares one memory slot, so one job's memory bleeds into the next. check: Claude Code keys auto memory by git repository, every worktree and subdirectory of one repository sharing a single memory directory, and outside a repository by the project root (docs: memory).
- No contract: nothing says who this agent is, what it is for, what it may touch, where its work goes. Every session decides afresh.
- Attribution: a harness that signs commits with its own trailers writes an AI byline into your repositories' history, and purging it later means rewriting pushed history. eg: hv's rule that AI attribution is purged on sight, and the day it had to be.
- Self-modification: a live session cannot survive its own state being moved. An agent that reorganises the harness it is running in takes its own transcript and credentials out from under itself. eg: the refuse-while-running check that listed every Claude process except the session it was running in, because macOS `pgrep` leaves out its own ancestors unless told otherwise (ST0006 WP01, 21 Oct 2026).

### 4. What are some good ways to manage these risks?

- The principle: name it, home it, bound it. Name it for what it is: which machine and which job, `<hostname>-<role>`, a name you can address, search for and reason about.
- Home it: one directory that is both the agent's configuration and its working directory, so the permissions it runs under are the permissions in its home by construction, as long as it starts there (section 5). Memory and work live in the home, not under a slug in the harness state. Then take `$HOME` away as a launch place: keep the harness state in one declared place outside it, and refuse a session started in `$HOME` with a hook that blocks its first prompt, so a `~/.claude` that reappears says some launch path missed the setting, and a check can say so. check: a `UserPromptSubmit` hook that exits 2 blocks the prompt and shows its stderr to the user without adding it to the context (docs: hooks); section 5 says when hooks wait for trust.
- Contract it: an instruction file in the home that says who the agent is, what the role is for, what it may touch, where its work goes, and how a session opens and closes. Put each rule in exactly one layer: rules for every session everywhere at user scope, what every machine agent shares in a preamble that opens each contract, the role's rules in the role contract, facts true of this machine only in a host overlay.
- Least privilege by role: split what you want done by how much power it needs, not by topic. One role may change the machine; one observes and diagnoses and writes only inside its home; one writes documentation. Sandbox every role but the one that changes the machine, and close the sandbox's escape hatches in the same settings: no excluded commands, and `allowUnsandboxedCommands` set to `false`.
- Fence and wall: settings the agent can edit are a fence; a root-owned managed-settings file it cannot edit is the wall, and a deny in the wall holds whatever the fence allows. check: "If a tool is denied at any level, no other level can allow it" (docs: permissions). The wall is per machine, not per agent: it binds every session on the box, so a per-role setting such as the sandbox switch has to live in the fence.
- The wall is only as high as the agent's reach. A role with sudo can climb it, so for the role that changes the machine the wall is a guard rail, not a boundary; past that point the boundary is a Unix account or a VM per agent, which this piece names and does not use. check: the docs name the system directories the managed file lives in, and say that on WSL `/etc/claude-code` is user-writable (docs: managed-settings).
- Keep it all as configuration in git and render it per machine: the role source, the homes, the user-scope rules. A role change is reviewed as a diff; a rendered home is never hand-edited. Attribution is the test case: turn it off in the harness and write the rule down at user scope, so every machine carries it. check: on Claude Code that is the `attribution` setting; the older `includeCoAuthoredBy: false` is honoured only until `attribution.commit` or `attribution.pr` is set (docs: settings-reference).
- Molt: the layers (role source in the config repo, agent home under `$MOLT_AGT_DIR`, harness state under `$XDG_CONFIG_HOME/claude`); the home-launch guard; `molt doctor` reporting a `~/.claude` present after the move as a launch path that missed the variable, or a move that did not finish.

### 5. How do I set up and configure the agent?

- Choose the harness, find out where it keeps its state and how to move it, and pick the new place: the XDG config dir is the natural one. Set the variable everywhere a session can start: login shells, ssh, and GUI launches (a LaunchAgent `setenv` on macOS, `environment.d` on Linux). A GUI launch does not read your shell's startup files, and whatever a GUI-launched session is given its hooks and MCP servers inherit, so publish the PATH your login shell builds there too, or a hook can run a different copy of a tool from the one your shell runs. Write the shell's file and the GUI's from one place, so they cannot drift apart. check: on Claude Code, `CLAUDE_CONFIG_DIR` moves the config dir, under which "all settings, session history, and plugins are stored", and project and local settings cannot set it (docs: env-vars). The docs do not say `~/.claude.json` moves too; a test on 21 Oct 2026 showed that it does (ST0006 context).
- Move the state once, yourself, from a plain terminal with every session quit, never from inside an agent; and publish the variable only once the state is where it points. The other order starts the next session empty in the new place, and the move then meets a non-empty target: two copies, neither whole. Once the variable is published, keep it published through a mistake: a shell that loses it starts the next session afresh in `~/.claude`.
- Make the home: the contract (`AGENTS.md`, with a one-line `CLAUDE.md` that imports it), `.claude/settings.json` carrying the role's permissions and a memory directory inside the home, and empty `memory/` and `work/`. check: a line `@AGENTS.md` in `CLAUDE.md` imports the file, to a depth of four hops. Claude Code also reads `AGENTS.md` natively, but only where no `CLAUDE.md` sits in the working directory or above it, so the import is the form that holds (docs: memory).
- Start the agent in the home itself, not below it: the `cd` is the launch, whether you type it or a launcher such as `molt agent start` makes it. check: Claude Code loads project settings from the working directory's `.claude/` with no fallback to a parent (docs: permissions), but loads `CLAUDE.md` from the working directory and every directory above it (docs: memory). Started in `work/`, the agent still reads its contract but runs without its home's permissions, sandbox and memory setting: the contract follows it down, the fence does not. By the same rule, a `CLAUDE.md` in any parent of the homes joins every agent's contract.
- Accept the workspace-trust prompt the first time. check: until it is accepted, an interactive session holds back hooks from every settings file, the user's included (docs: hooks), and the home's `permissions.allow` rules and `autoMemoryDirectory` (docs: permissions; docs: settings-reference). A `claude -p` run never shows the prompt: it runs the hooks and uses the memory setting, but not the home's allow rules (docs: permissions).
- Put the wall where the harness looks for it. check: Claude Code's settings precedence, highest first: managed, `--settings`, `.claude/settings.local.json`, `.claude/settings.json`, user. A key set higher overrides the same key lower down, but list keys such as `permissions.allow` combine across files (docs: settings). Managed file: `/Library/Application Support/ClaudeCode/managed-settings.json` on macOS, `/etc/claude-code/managed-settings.json` on Linux and WSL, and every `*.json` in a `managed-settings.d/` beside it merges after it in alphabetical order (docs: managed-settings).
- Molt: declare `MOLT_CLAUDE_CONFIG_DIR` in the sleeve's `vars.sh`; add `[[agent]]` entries with a `role` to `instances/<hostname>/molt.toml` and, where that file names its liberators, enable `agents`, and `env` after `claude`; `molt upgrade` (or `molt resleeve`) renders the homes and runs the move, backing up `~/.claude` and `~/.claude.json` beside the config dir first, and refusing while any Claude runs, Chrome's native host included, or while `env` is not enabled to publish the result.
- Molt: the move repoints each path into `~/.claude` that the moved `settings.json` names, a hook's script included. eg: on rhadamanth's move (23 Oct 2026) a hand-installed hook still named its script under `~/.claude/`; the interpreter could not open it and exited 2, a PreToolUse hook's block code, so every Bash call in every session was refused until the line was repointed (issue 0038).
- Molt: one env writer publishes the variable to `~/.config/molt/env.sh`, which `~/.zshenv` sources, and to the GUI file, `~/Library/LaunchAgents/com.molt.env.plist` or `~/.config/environment.d/molt.conf`, only once the state is in the declared dir, together with each tool's `*_INSTALL_PREFIX` the sleeve's `vars.sh` exports. GUI apps also get the PATH a clean login shell builds, which is refused unless `~/.local/bin` comes first, so a desktop session's hooks find the tools a shell finds. Each value stands alone: a refused one is named and fails the run while the rest are still published, and a config dir that cannot be used keeps the value already published. Molt runs neither `launchctl` nor `systemctl`, so the GUI file takes effect for apps launched after the next login.
- Molt: the wall and the sandbox, as built. On a sleeve that enables `sysadm` and declares the config dir, `molt upgrade` asks for sudo once and installs the deny floor the config repo declares for it, reads of SSH private keys and AWS credentials, as `managed-settings.d/molt-sysadm.json`; on a Linux sleeve with `ops` or `docs`, whose distro ships the `bwrap-userns-restrict` AppArmor profile, it installs Molt's copy of that profile so the sandbox can run, the distro's kept beside it and put back when the sleeve no longer needs Molt's.
- Molt: `molt agent list` shows each agent and the state of its home, `molt agent roles` the roles the sleeve declares, and `molt agent config <role>` one agent's rendered files, guard, sandbox and effective permissions, with the layer each rule came from; `molt agent home <role>` prints the home, for a `cd`. Each takes the role or the full name.
- Molt: `molt agent start sysadm` starts kovacs-sysadm in its home, as `claude start --name kovacs-sysadm`, the one word `start` its first prompt. It starts nothing, and names the fix, when the agent is not enabled, its role is not defined, its home is not current, the shell was opened before the move, or a session of that name is already running.
- Molt: the preamble says what `start` asks for: bearings, not work. The agent reads its memory and the newest note in `work/`, says in a few lines who and where it is and what is open, changes nothing, and waits for an instruction; any other first prompt is the instruction. Before a session ends it leaves a note in `work/` saying what is open, for the next session to read.
- Molt: a launch from the wrong place is refused with the way back in. From `$HOME` the guard says `launch from an agent home: molt agent start <role>`, and from the agents root `launch from an agent home, not the agents root: molt agent start <role>`; from below a home, `launch from the agent home itself: molt agent start <hostname>-<role>`, naming that home's agent; a session that did not get the sleeve's config dir, or got another, is told to quit, open a new shell or log out and in, and start it with `molt agent start <role>`.
- Molt: what a session in the home reads, widest first: the user-scope `CLAUDE.md` and `AGENTS.md` linked into the config dir, then the home's `AGENTS.md`, rendered from a preamble every sleeve agent shares, the role contract and the host overlay, in that order.

### 6. What if I have multiple different (scoped) things I want my agent(s) to do?

- One agent per role, not one agent that does everything. Permissions and memory are per home, so an agent that administers the machine and also writes its documentation has administrator powers while it writes documentation.
- A role is a trust level, not a task. These cover a machine: may change it, may observe it, may document it. eg: `sysadm` (cannot be sandboxed), `ops` (observes and diagnoses, writes only inside its home, sandboxed), `docs` (sandboxed).
- The naming makes the set legible: `kovacs-sysadm`, `kovacs-ops`, `kovacs-docs`. The name is derived from host and role, never typed, so it cannot be mistyped.
- Sleeve agent, project agent, estate agent: an agent run inside a project is already bounded by the project (its instructions, its permissions, its tooling), so it does not need this machinery; it needs a different naming. eg: the project-session suffixes, `sc` supervisor, `vc` validation, `cc` control, `ic` interface, `ac` authoring, `dc` devx, giving `molt-vc`. A suffix names a project session's job; a role names a machine agent's job. `dc` is a project agent; `docs` is a machine role. The third kind is bounded by an estate, not a machine or a project: one per Gtools estate, provisioned by Gtools, run from the estate's content root and named for it. eg: `sinclair-estate`, `geodica-estate`.
- Coordination once there are several: a shared board with one writer per board and one writer per inbox, claims by work item so two agents do not build the same thing, and a human node who adjudicates and is never impersonated.
- Molt: the roles are directories under the config repo's `config/agents/roles/<role>/`, so the set is yours to define; the convention is the roles above on every machine.

### 7. What if I have multiple machines?

- Same roles on every machine from one source. The role contract and the permission profile are written once, in git, and rendered per machine.
- Per-host facts go in a per-host overlay (this machine's layout, what is installed, its known issues), appended to the rendered contract and never mixed into the role.
- User-scope rules travel too: link the same `CLAUDE.md` and `AGENTS.md` into every machine's config dir, so the cross-session rules are the same everywhere. eg: the Git Commits rule, which one machine lacked until 20 Oct 2026 while another had it; the same week, the config repo's history turned out to carry AI trailers back to March.
- Move one machine at a time, behind a per-machine switch: merging the mechanism changes nothing until a machine declares the variable.
- Keep the harness at one version across the machines, or write only settings that every version in use accepts. eg: `attribution: false` needs Claude Code v2.1.281 or later, and an earlier version rejects it and skips the whole settings file that holds it (docs: settings-reference). A setting meant to quiet the harness drops every rule in its file on the machine that lags.
- An agent on each box, reached by message, rather than one agent that ssh-es everywhere: the per-box agent has that box's context and only that box's blast radius. eg: an agent on the machine at home in the UK and one in the VM, each messaged rather than reached over ssh.
- What travels with the home (contract, permissions, memory) against what stays per machine (harness state, credentials, transcripts).
- Molt: stack and sleeve (the config is the stack, each machine a sleeve it is loaded into, `resleeve` the bootstrap verb; Altered Carbon, as flavour, not advice); `instances/<hostname>/` for the per-host overlay; `MOLT_AGT_DIR` as a peer of `prj/` and `cfg/`; `MOLT_CLAUDE_CONFIG_DIR` as the per-machine switch.

### 8. Who is this advice for?

- Three points on a line. At one end, "just use the agent app": no machine access, nothing here applies, the app's defaults are the right fence. At the other, tens of coding agents in swarms with their own orchestration and infrastructure: you built this already, in a bigger shape.
- The middle, which is this piece: one person, a few machines, an agentic CLI already in use for code, wanting machine work done safely. Nobody writes this down for them, because the app readers do not need it and the swarm operators did it themselves.
- Where the advice keeps scaling: naming, homes, contracts, fence and wall, one source rendered everywhere all apply to a swarm as much as to one agent.
- Where it stops: at the point where agents need their own accounts, their own machines or an orchestrator, which this piece does not cover.
- A self-test for the reader: if you have ever run an agent from `$HOME` and felt uneasy about it, this is for you.

### 9. Etc

- What this does not solve: prompt injection through the content the agent reads; the fence being editable by the agent, which is why there is a wall; a wall that a role with sudo can climb; Edit and Write prompting rather than being sandboxed; one credential set per machine, shared by every agent on it.
- Where it goes next: an account per agent as the stronger boundary; other harnesses, later if ever. The managed deny floor for the role that cannot be sandboxed, once next, is built (ST0006 WP06; section 5).
- Closing line candidate: an agent with a name, a home and a contract is an agent you can reason about; one running from `$HOME` is a guest with your keys.
- Note for the write-up: the scoping statement (an account per agent, a VM per agent, an orchestrator: stronger boundaries this piece does not use) sits in sections 1, 4, 8 and 9 of these notes because each has a job for it; in the piece, one section owns it and the others point at it.
