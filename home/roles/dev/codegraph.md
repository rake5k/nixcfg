# CodeGraph

A project with a `.codegraph/` directory has a pre-built symbol index that auto-syncs on file
changes. Query it to answer structural questions ("how does X work", "how does X reach Y", surveying
an area) instead of a grep/glob/read loop. Treat returned source as already read, don't re-verify it
with grep, and check the staleness banner after edits. Build the index with `codegraph init`.

- Main agent: use the `codegraph_explore` MCP tool; if it is listed but deferred, load it by name
  via tool search.
- Subagents and non-MCP harnesses (no MCP guidance reaches them) use the CLI equivalents:

```bash
codegraph explore <query>      # relevant symbols' source + call paths in one call
codegraph node <symbol|file>   # one symbol's source + callers, or a file with line numbers
```
