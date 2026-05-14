---
name: commit
description:
  Enforces a commit message convention. Use when creating git commits, amending commits, or when the
  user asks to commit changes.
---

# Commit Skill

## Message Format

Format every commit message following the Conventional Commits v1.0.0 specification:

```
<description>

[optional body]

[optional footer(s)]
```

## Message Convention

Only describe what actually changed in the staged changeset. Ignore other files/lines that are not
being committed.

## Pre-commit

Before every commit, run all project tests and ensure they pass. Do NOT commit if any test fails —
fix the issue first.

## Rules

**Never** add `Co-Authored-By` or any AI attribution to commit messages
