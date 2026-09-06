# claudecode

Home Manager role exposing `claude-<backend>` wrappers, shared settings, MCP servers, skills, slash
commands, and the ccstatusline layout. See `default.nix` for options.

## Settings

`settings_common.json` holds the settings shared by every backend. It is merged with the backend's
`env` overrides and the consuming flake's `custom.roles.dev.claudecode.extraSettings`, then passed
to `claude --settings`, which outranks `~/.claude/settings.json`.

Lists are concatenated across the common defaults and `extraSettings`, so a downstream flake adds
permission rules, hook handlers and sandbox entries without redeclaring the shared ones; every other
key follows `lib.recursiveUpdate` (downstream wins). Keep downstream-specific entries — employer
domains, private plugins and skills — in that flake's `extraSettings`, not here.

`~/.claude/settings.json` is deliberately left unmanaged: Claude Code writes to it itself
(`/config`, `/model`, plugin installs), so a read-only store symlink would break those. Keys set
here shadow it; `hooks` entries merge across both, with identical handlers deduplicated.

Plugins enabled via `enabledPlugins` need their marketplace declared in `extraKnownMarketplaces`
unless it ships as a built-in (`claude-plugins-official`).

## Sandbox

The `sandbox` block in `settings_common.json` turns on the
[sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing), which confines Bash commands and
their children at the OS level (bubblewrap on Linux, Seatbelt on macOS). `bwrap` and `socat` need no
declaration here — the nixpkgs `claude-code` wrapper puts both on `PATH`.

The policy assumes sessions run with `--dangerously-skip-permissions`, where the sandbox is the only
boundary left, so the escape routes are closed rather than gated: `failIfUnavailable` refuses to
start instead of silently running unsandboxed, `allowUnsandboxedCommands` drops the
`dangerouslyDisableSandbox` retry, and `network.strictAllowlist` denies an unlisted host instead of
prompting. Secrets are listed under `credentials` rather than `filesystem.denyRead`: the effect is
the same, and a `deny` file entry also pins `filesystem.disabled` so no downstream scope can switch
the filesystem layer off.

`claude-seccomp` blocks every AF_UNIX socket inside the sandbox, which also blocks the nix daemon
socket and with it every `nix` command. `network.allowAllUnixSockets` lifts that, but the Linux
sandbox has no per-path socket allowlist, so it also exposes `/run/docker.sock`, which is equivalent
to root on the host. Both docker socket paths are therefore in `filesystem.denyRead`, which replaces
them with `/dev/null` inside the sandbox. Use `denyRead`, not `denyWrite`: a `denyWrite` entry
leaves the socket connectable and `docker` keeps working.

Commands that cannot work under these rules fail with no retry, by design. Run them yourself with
the [`!` prompt](https://code.claude.com/docs/en/interactive-mode#shell-mode-with-prefix), which
stays unsandboxed in interactive sessions:

- `docker`, which is incompatible with the sandbox. It is deliberately not in `excludedCommands`,
  which would reopen the socket path the `denyRead` entries close.
- `hm-switch`, `nixos-rebuild` and anything else needing `sudo` or writes across `$HOME`.
- `git checkout` or `git merge` across a branch that changes a
  [protected path](https://code.claude.com/docs/en/sandboxing#protected-paths) such as
  `.claude/skills`, which fails with `unable to unlink old`.

Downstream flakes append to the `sandbox` lists through `extraSettings` the same way they append
permissions; `nixcfg-work` adds its Artifactory and Gradle hosts there.

## Plugins

`enabledPlugins` in `settings_common.json` only enables plugins; it does not install them.
Installation state lives in `~/.claude/plugins` and is not managed here, so each entry needs a
one-time install:

```bash
claude plugin install <name>@<marketplace>
```

See the [plugin docs](https://code.claude.com/docs/en/discover-plugins).

## MCP servers

`settings.json` has no `mcpServers` key, so servers are generated into a store file and passed via
`claude --mcp-config`. Since `--strict-mcp-config` is not set, they merge with the servers already
configured in `~/.claude.json`.

[codegraph](https://github.com/colbymchenry/codegraph) is wired up this way, using
`pkgs.unstable.codegraph` for both the MCP server and the `codegraph` command. Indexing is per
project and stays manual:

```bash
cd <project> && codegraph init
```

The rest of what `codegraph install` would write is declared instead of installed: the
`mcp__codegraph__*` allow rule and the `codegraph prompt-hook` `UserPromptSubmit` hook in
`settings_common.json`, and the agent guidance in `../codegraph.md`, which is appended to
`~/.claude/CLAUDE.md` and reused verbatim as opencode's `AGENTS.md`. Do not run `codegraph install`
— it replaces the managed `CLAUDE.md` symlink with a plain file, which then blocks Home Manager
activation.

## Slash commands

Markdown files under `commands/` are linked into `~/.claude/commands/` by `default.nix` and become
`/<name>` commands. `wiki.md` implements `/wiki`, a Logseq/Obsidian knowledge base with an L1/L2
cache model.

The wiki lives outside every project, so `settings_common.json` allows
`Read(~/Documents/notes/claude/**)` and `Edit(~/Documents/notes/claude/pages/**)` — writes are
scoped to `pages/`, keeping `journals/`, `logseq/` and `llm-wiki.yml` prompt-gated. Path rules are
only consulted for `Read` and `Edit`; an `Edit` rule covers `Write` and `NotebookEdit` too, and a
`Write(...)` or `Glob(...)` path rule is
[ignored with a startup warning](https://code.claude.com/docs/en/permissions#read-and-edit).

## Hooks

Scripts under `hooks/` are linked into `~/.claude/hooks/` and registered in the `hooks` block of
`settings_common.json`. See the [hooks docs](https://code.claude.com/docs/en/hooks).

`wiki-index.sh` (`SessionStart`) prints the `### Index` routing lines of every `/wiki` hub page,
which Claude Code appends to the session context — the wiki's index without its page bodies, so
routing to a page needs no explicit `/wiki query`. It locates the wiki via `LLM_WIKI_ROOT` (default
`~/Documents/notes/claude`), reads `pages_dir` from `llm-wiki.yml`, and exits silently when neither
is present. `LLM_WIKI_INDEX_MAX_LINES` (default 150) caps the injection; the overflow is reported in
the output, not dropped silently.

It also counts the dated lines pending in `Wiki/Reference/Ingest-Inbox` — the capture queue sessions
append durable learnings to — and reports them, so `/wiki ingest inbox` gets offered instead of
forgotten. Capture is automatic and cheap (one line, no commit); draining into pages stays manual.

## ccstatusline

`ccstatusline.json` holds the statusline widget layout, linked to
`~/.config/ccstatusline/settings.json` (see `default.nix`). Hand-editing the raw JSON is
error-prone; edit it through the configuration utility instead:

```bash
npx ccstatusline@2.2.29 --config ccstatusline.json
```

The utility provides an interactive editor for widgets, separators, colors, and powerline settings,
and writes changes back to the given file. Commit the result.

The version is pinned here and in `settings_common.json`. Keep both in sync: the linked
`~/.config/ccstatusline/settings.json` is a read-only store path, so a version whose config schema
is newer than `ccstatusline.json` cannot persist its migration and renders `⚠ invalid config`
instead of the statusline. To upgrade, bump both, re-run the utility to migrate the layout file, and
commit it together with the pin.
