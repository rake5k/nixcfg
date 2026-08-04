# claudecode

Home Manager role exposing `claude-<backend>` wrappers, shared settings, MCP servers, skills, and
the ccstatusline layout. See `default.nix` for options.

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

## ccstatusline

`ccstatusline.json` holds the statusline widget layout, linked to
`~/.config/ccstatusline/settings.json` (see `default.nix`). Hand-editing the raw JSON is
error-prone; edit it through the configuration utility instead:

```bash
npx ccstatusline@latest --config ccstatusline.json
```

The utility provides an interactive editor for widgets, separators, colors, and powerline settings,
and writes changes back to the given file. Commit the result.
