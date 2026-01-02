# AGENTS.md

## Build / Lint / Test Commands

NOTE: Linting commands like `markdownlint`, `yamllint`, etc.
MUST be run within the Nix development shell using `nix develop`.
These tools are only available inside the dev shell, not system-wide.

- **Build entire config**: `nix build .#nixos`
- **Home‑manager config**: `nix build .#homeConfigurations.demo@non-nixos.activationPackage`
- **Run pre‑commit hooks**: `pre-commit run --all-files`
- **Lint markdown**: `markdownlint . --config .markdownlint.json`
- **Nix formatter**: `nixfmt` (or `nixfmt -l .`)
- **Nix LSP checks**: `statix check`
- **Shell scripts**: `shellcheck` (via `pre‑commit`)
- **YAML lint**: `yamllint -c .yamllint .`
- **Run all checks**: `nix flake check`
- **Single flake test**: `nix build .#checks.<system>.default` (if a check outputs a derivation)

## Code‑Style Guidelines

- **Imports**: Group `lib`, `pkgs`, then custom modules; one per line.
- **Formatting**: Use `nixfmt` and `statix`; follow existing style (e.g.,
`recursive = ...` on its own line).
- **YAML / Markdown**: Run `yamllint` and `markdownlint`; no trailing spaces, `lf` endings.
- **Naming**: Resources `lower‑case-hyphens`; variables `camelCase`; attributes
  `lower_case_underscores`.
- **Error handling**: Use `assert` in Nix; shell scripts with `set -euo pipefail`.
- **Testing**: Add to `checks` and run with `nix flake check`; use `nix develop` for dev shell.

## Rules for AGENTs

- No Cursor or Copilot rules found.
- Follow style conventions and lint tools.
