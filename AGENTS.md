# AGENTS.md

## Overview

This repository contains NixOS and Home‑Manager configurations built by the Nix Flake `nixos`,
`homeConfigurations`, and `nixOnDroidConfigurations`. The following sections explain how to build,
lint, test, and develop the code within a _Nix development shell_ (`nix develop`).

## Build / Lint / Test Commands

The commands below are divided into groups to help agents and developers quickly pick the operation
they need.

### 1. Build all configurations

```bash
# Build the NixOS system and all Home‑Manager configurations for *every* supported system.
#  `nix flake check` will also invoke each check defined in flake-commons.

nix flake check
```

### 2. Build a single configuration

```bash
# Build the NixOS system for the default Linux configuration.
# Replace `x86_64-linux` with another system if needed.

nix build .#packages.x86_64-linux.nixos
```

### 3. Home‑Manager activation packages

```bash
# Build and apply the Home‑Manager configuration for the non‑NixOS demo user.
# The generated activation package can be executed with `activate`.

nix build .#packages.x86_64-linux.non-nixos-demo
```

### 4. Pre‑commit hooks

```bash
# Run every pre‑commit hook on all files.
# The hooks install in the devShell automatically.

pre-commit run --all-files
```

### 5. Individual pre‑commit hooks

```bash
# Run a specific hook, e.g., `shellcheck` or `markdownlint`.

pre-commit run shellcheck
pre-commit run markdownlint
```

### 6. Linting & formatting

| Tool           | Command                                      | Notes                                     |
| -------------- | -------------------------------------------- | ----------------------------------------- |
| `markdownlint` | `markdownlint . --config .markdownlint.json` | Lints Markdown files.                     |
| `yamllint`     | `yamllint -c .yamllint .`                    | Lints YAML files defined in the repo.     |
| `nixfmt`       | `nixfmt -l .`                                | Formats all `.nix` files.                 |
| `statix`       | `statix check`                               | Lints Nix syntax and best‑practice style. |
| `shellcheck`   | `shellcheck` via pre‑commit                  | Lints all shell scripts.                  |

### 7. Run tests for a single check

The flake-commons project provides a set of _checks_ that can be run individually:

```bash
# List all checks for the current system
nix build .#checks.<system>.default

# Run a single named check (replace <name> with the actual check name)
# e.g., `nix build .#checks.x86_64-linux.nixpkgs-test` will invoke the test defined there.

nix build .#checks.x86_64-linux.<name>
```

If you need to run the test in a sandboxed environment you can also use `nix test`:

```bash
nix test .#check.<system>.<name>
```

### 8. Building a specific package

Individual packages can be built with the `packages` attribute set. For example:

```bash
nix build .#packages.x86_64-linux.<package-name>
```

## Code‑Style Guidelines

The following rules are enforced by the linter tools above and are expected to be followed by all
contributors.

### Imports

- Group `lib`, `pkgs`, and custom modules at the top of each file, one per line.
- Do not import sub‑packages unless necessary.

### Format & Style

- Always use `nixfmt` and `statix` before committing.
- Prefer attributes over lambda functions when possible.
- Keep each expression on its own line for readability.

### Types & Expressions

- Explicitly declare types for public attributes: `type = ...`.
- Avoid `throw` or `builtins.abort`; use `assert` for conditions.

### Naming Conventions

| Entity     | Convention               |
| ---------- | ------------------------ |
| Resources  | `lower-case-hyphens`     |
| Variables  | `camelCase`              |
| Attributes | `lower_case_underscores` |
| Functions  | `camelCase`              |

### Error Handling

- Use `builtins.tryEval` or `assert` for runtime checks.
- Prefer `builtins.abort` to surface errors during build.
- When writing shell scripts, use `set -euo pipefail`.

### Testing

- All checks should be written in `flake-commons` and invoked via `nix flake check`.
- Add a new check by creating a derivation inside `flake-commons` and exposing it through the
  `checks` attribute.
- Keep the test suites independent from user‑specific secrets.

## Cursor / Copilot Rules

- This repository currently does **not** contain any `.cursor` or `.cursorrules` directories.
- There is no `.github/copilot-instructions.md` file. The repository is open to contributions, but
  no special Copilot guidance has been defined yet.

## Development Workflow

1. Enter the development shell:
   ```bash
   nix develop
   ```
2. Run the linting tools. They are automatically available due to `pre-commit-hooks`.
3. Build or test changes with one of the commands above.
4. Commit and push.

Feel free to ask an agent for help with any of the commands listed here or for further explanations.

---

_The file is intentionally verbose to aid readability for both humans and bots._
