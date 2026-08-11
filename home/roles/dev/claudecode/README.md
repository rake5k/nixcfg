# claudecode

Home Manager role exposing `claude-<backend>` wrappers, shared settings, MCP servers, skills, slash
commands, and the ccstatusline layout. See `default.nix` for options.

## Settings

`settings_common.json` holds the settings shared by every backend. It is merged with the backend's
`env` overrides and the consuming flake's `custom.roles.dev.claudecode.extraSettings`, then passed
to `claude --settings`, which outranks `~/.claude/settings.json`.

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

[codegraph](https://github.com/colbymchenry/codegraph) is wired up this way. It is not in nixpkgs
and ships per-platform prebuilt blobs, so both the MCP server and the `codegraph` command run
through `npx` at a version pinned in `default.nix`. Indexing is per project and stays manual:

```bash
cd <project> && codegraph init
```

## Slash commands

Markdown files under `commands/` are linked into `~/.claude/commands/` by `default.nix` and become
`/<name>` commands. `wiki.md` implements `/wiki`, a Logseq/Obsidian knowledge base with an L1/L2
cache model.

## ccstatusline

`ccstatusline.json` holds the statusline widget layout, linked to
`~/.config/ccstatusline/settings.json` (see `default.nix`). Hand-editing the raw JSON is
error-prone; edit it through the configuration utility instead:

```bash
npx ccstatusline@latest --config ccstatusline.json
```

The utility provides an interactive editor for widgets, separators, colors, and powerline settings,
and writes changes back to the given file. Commit the result.
