# claudecode

Home Manager role exposing `claude-<backend>` wrappers, shared settings, MCP servers, skills, slash
commands, and the ccstatusline layout. See `default.nix` for options.

## Settings

`settings_common.json` holds the settings shared by every backend. It is merged with the backend's
`env` overrides and the consuming flake's `custom.roles.dev.claudecode.extraSettings`, then passed
to `claude --settings`, which outranks `~/.claude/settings.json`.

`permissions.{allow,deny,ask}` and `hooks.<event>` lists are concatenated across the common defaults
and `extraSettings`, so a downstream flake adds rules and hook handlers without redeclaring the
shared ones; every other key follows `lib.recursiveUpdate` (downstream wins). Keep
downstream-specific entries — employer domains, private plugins and skills — in that flake's
`extraSettings`, not here.

`~/.claude/settings.json` is deliberately left unmanaged: Claude Code writes to it itself
(`/config`, `/model`, plugin installs), so a read-only store symlink would break those. Keys set
here shadow it; `hooks` entries merge across both, with identical handlers deduplicated.

Plugins enabled via `enabledPlugins` need their marketplace declared in `extraKnownMarketplaces`
unless it ships as a built-in (`claude-plugins-official`).

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
npx ccstatusline@latest --config ccstatusline.json
```

The utility provides an interactive editor for widgets, separators, colors, and powerline settings,
and writes changes back to the given file. Commit the result.
