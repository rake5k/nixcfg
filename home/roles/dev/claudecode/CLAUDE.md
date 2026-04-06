# Workflow

- Start complex tasks in plan mode (Shift+Tab twice). Iterate on the plan before implementing.
- Use subagents to offload research and keep the main context window focused.
- When sessions get long (3+ tasks or context compression), suggest checkpointing and starting
  fresh.
- Verify your work before declaring it done - run tests, check types, lint. Always verify yourself
  if the CI succeeds.
- Update the existing documentation after every substantial change done.

# Tools

- Always use `glab` CLI to interact with GitLab (merge requests, issues, pipelines, etc.).

# Documentation

- ALWAYS ask before creating .md files. Propose: filename, purpose, alternative (existing file?).
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

# Git

- Amend previous commit only for small follow-up fixes on the same branch.

# Self-Improvement

- Always consultate <https://code.claude.com/docs/en> before answering when I ask something about
  your configuration, skills, etc.
- After every correction or mistake, update the relevant CLAUDE.md or .claude/rules/ file to prevent
  repeating it.
