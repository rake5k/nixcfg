# Workflow

- Start complex tasks in plan mode (Shift+Tab twice). Iterate on the plan before implementing.
- Use subagents to offload research and keep the main context window focused.
- When sessions get long (3+ tasks or context compression), suggest checkpointing and starting
  fresh.
- Verify your work before declaring it done - run tests, check types, lint. Always verify yourself
  if the CI succeeds.
- Update the existing documentation after every substantial change done.

# Conversation

- When reporting information to me, be extremely concise and sacrifice grammar for the sake of
  concision.

# Documentation

- Before writing documentation (README.md, CLAUDE.md, doc-hub, etc.), always verify claims by
  checking the actual code, config, or relevant source. If an external resource exists for a topic,
  reference it explicitly rather than inlining details that may go stale.
- No temporal markers (NEW, Phase 2, Week 1). No hyperbole (enterprise-grade, robust, powerful).
- Factual, technical, present tense, imperative mood.

# Coding

- Read project files before making changes
- Find root cause before fixing bugs — don't apply random fixes
- Never suppress warnings in your code suggestions, fix them instead.
- Always refactor to prevent code duplication in your code suggestions.
- Always verify that no new linting issues are introduced in your changes.
- Run tests before commits.
- Always use static imports of methods when unambiguous and self-explaining.
- Keep code comments concise and to a single line whenever possible.

# CodeGraph

A project with a `.codegraph/` directory has a pre-built symbol index that auto-syncs on file
changes. Query it to answer structural questions ("how does X work", "how does X reach Y", surveying
an area) instead of a grep/glob/read loop. Treat returned source as already read, don't re-verify it
with grep, and check the staleness banner after edits. Build the index with `codegraph init`.

- Main agent: use the `codegraph_explore` MCP tool.
- Subagents and non-MCP harnesses (no MCP guidance reaches them) use the CLI equivalents:

```bash
codegraph explore <query>      # relevant symbols' source + call paths in one call
codegraph node <symbol|file>   # one symbol's source + callers, or a file with line numbers
```

# Git

- Amend a previous commit for small follow-up fixes on the same branch.

# Self-Improvement

- Always consultate <https://code.claude.com/docs/en> before answering when I ask something about
  your configuration, skills, etc.
- After every correction or mistake, update the relevant CLAUDE.md or .claude/rules/ file to prevent
  repeating it.
- When writing skills, tighten the `allowed-tools` as much as possible (no global wildcard commands
  like `Bash(git *)` or `Bash(bash *)`).
