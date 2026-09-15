---
name: updating-nixcfg
description:
  Workflow for changing nixcfg when the change affects downstream flakes (nixcfg-home, nixcfg-work)
  — commit locally, repoint downstream inputs at the local .git, verify with nix flake check, push,
  then relock. Use when editing nixcfg, flake-commons, or a Nix fork consumed by the nixcfg
  ecosystem (homeage, stylix, home-manager).
allowed-tools:
  Read, Edit, Bash(cd:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git status),
  Bash(git diff:*), Bash(nix flake update:*), Bash(nix flake check:*)
---

# Updating nixcfg

When making changes to `nixcfg` that affect downstream flakes (`nixcfg-home`, `nixcfg-work`):

1. **Commit in nixcfg** (do not push yet):

   ```bash
   cd nixcfg && git add -A && git commit -m "description"
   ```

2. **Point downstream flakes to local nixcfg** by temporarily changing the `nixcfg` input in
   `nixcfg-home/flake.nix` and `nixcfg-work/flake.nix`:

   Resolve the absolute path first — flake URLs do not expand `~` or `$HOME`:

   ```bash
   git -C ../nixcfg rev-parse --show-toplevel
   ```

   ```nix
   # from:
   nixcfg.url = "github:rake5k/nixcfg";
   # to (substitute the path printed above):
   nixcfg.url = "git+file://<nixcfg-toplevel>/.git";
   ```

   Use `git+file://`, not `path:` — `path:` copies the whole tree and fails on
   `.codegraph/daemon.sock` (`unsupported type`). Point at `.git`, not the worktree: the bare fetch
   exports the committed HEAD and skips the worktree, whose `.gitmodules` and `.git/config.lock` the
   Claude Code sandbox masks with `/dev/null` (`parsing .gitmodules file ... is locked`). Only
   committed changes are picked up, hence step 1.

3. **Update and verify** in both repositories:

   ```bash
   cd nixcfg-home && nix flake update nixcfg && nix flake check
   cd nixcfg-work && nix flake update nixcfg && nix flake check
   ```

   If checks fail, fix in `nixcfg/`, amend or create a new commit, and repeat this step.

4. **On success:** push the nixcfg commit, then restore the remote URL in both downstream flakes:

   ```nix
   nixcfg.url = "github:rake5k/nixcfg";
   ```

   Then lock to the pushed version:

   ```bash
   cd nixcfg-home && nix flake update nixcfg
   cd nixcfg-work && nix flake update nixcfg
   ```

5. **Commit and push** the flake.lock updates (and any config changes) in `nixcfg-home` and
   `nixcfg-work`.

## Nix forks

For Nix forks consumed by the nixcfg ecosystem (e.g. `homeage`, `stylix`, `home-manager`), the same
workflow applies: commit → point downstream flake to local path → `nix flake check` → push → relock.
