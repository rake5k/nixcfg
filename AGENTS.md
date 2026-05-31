# AGENTS.md

## Overview

This repository contains NixOS and Home‑Manager configurations built by the Nix Flake `nixos`,
`homeConfigurations`, and `nixOnDroidConfigurations`. The following sections explain how to build,
lint, test, and develop the code within a _Nix development shell_ (`nix develop`).

## Project Structure

```
nixcfg/
├── flake.nix          # Main flake definition, hosts, outputs
├── flake.lock         # Locked inputs
├── home/              # Home Manager configuration
│   ├── base/          # Basic user configs
│   ├── programs/      # Custom program modules
│   ├── roles/         # Custom roles for bundling configsets
│   └── users/         # User-specific configs
├── hosts/             # NixOS host configs
│   ├── nixos-vm/
│   ├── nix-on-droid/
│   └── non-nixos-vm/
├── lib/               # Internal flake library
├── nix-on-droid/      # Custom NixOnDroid modules
├── nixos/             # Custom NixOS modules
│   ├── base/          # Basic NixOS configs
│   ├── containers/    # Container modules
│   ├── programs/      # Program modules
│   └── roles/         # Roles for bundling configsets
└── secrets/           # agenix-encrypted secrets
```

### Key Input Dependencies

The flake depends on:

- **nixpkgs** - Main package set (nixos-26.05)
- **nixpkgs-unstable** - Unstable branch for newer features
- **flake-commons** (rake5k/flake-commons) - Shared utilities
- **nur** - Nix User Repositories
- **home-manager** - User dotfile management
- **darwin** - MacOS configuration
- **nix-on-droid** - Android Nix management
- **agenix** - Secret management
- **agenix-cli** - CLI utilities for agenix
- **disko** - Disk partitioning
- **homeage** - Home age secret management
- **impermanence** - Zero-configuration immutable NixOS
- **lanzaboote** - Secure boot
- **nix-index-database** - Nix index for performance
- **nvidia-patch** - NVIDIA driver patches
- **stylix** - Theming and customization
- **wallpapers** - Personal wallpaper collection

### Configuration Flow

1. **flake.nix** defines all outputs:
   - `nixosConfigurations` - NixOS system configs
   - `homeConfigurations` - Home Manager user configs
   - `nixOnDroidConfigurations` - Nix-on-Droid configs
   - `darwinConfigurations` - Darwin/MacOS configs
   - `devShells` - Development shells

2. **nixos/** - NixOS-specific modules:
   - `base/` - Core system configuration (boot, nix, network, etc.)
   - `programs/` - Program configurations
   - `roles/` - Role-based composition (desktop, nas, gaming, etc.)
   - `users/` - Per-user configuration

3. **home/** - Home Manager modules:
   - `base/` - Basic user environment
   - `programs/` - Custom program modules
   - `roles/` - Role-specific configs (gnome, gtk, terminal, etc.)
   - `users/` - User-specific overrides

4. **secrets/** - Encrypted secrets for agenix decryption

### Roles System

The configuration uses a role-based composition system:

**nixos/roles/** - NixOS roles:

- `desktop/` - General desktop environment
- `desktop/mobile/` - Mobile-friendly desktop
- `gaming/` - Gaming setup
- `nas/` - NAS configuration (various sub-roles)
- `containers/` - Container runtime
- `android/` - Android development
- `ai/` - AI/ML setup
- `sound/` - Audio configuration
- `printing/` - Printer support
- And more...

**home/roles/** - Home Manager roles:

- `desktop/gnome/`, `desktop/gtk/`, `desktop/wayland/` - DE configurations
- `terminal/` - Terminal emulator setup
- `password-manager/` - Password manager configuration
- `shell/` - Shell configuration
- `notification/` - Notification daemon
- And more...

### Secrets Management

Secrets are stored encrypted in `secrets/` using agenix. The process:

1. Add host public keys to [.agenix.toml](.agenix.toml)
2. Push updated [.agenix.toml](.agenix.toml) to git
3. Re-key secrets on existing hosts:

   ```bash
   # On NixOS:
   sudo agenix -i /etc/ssh/ssh_host_ed25519_key -i ~/.age/key.txt -r -vv

   # On non-NixOS:
   agenix -i ~/.age/key.txt -r -vv
   ```

4. Rebuild to decrypt: `sudo nixos-rebuild switch`

To update a secret:

```bash
# Decrypt current secret
age --decrypt -i ~/.age/key.txt -o tmpfile < ./secrets/<secretfile>.age

# Edit tmpfile

# Re-encrypt
age --encrypt --armor -i ~/.age/key.txt -o ./secrets/<secretfile>.age < tmpfile
```

## Build / Lint / Test Commands

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

### 4. Rebuild configurations

```bash
# On NixOS
sudo nixos-rebuild switch

# On non-NixOS (Home Manager)
hm-switch

# On Nix-on-Droid
nix-on-droid switch --flake .#<hostname>
```

### 5. Setup (first-time configuration)

```bash
# Apply system configuration
nix run github:rake5k/nixcfg#setup -- <flake-url>

# Fresh NixOS install with disk partitioning
nix run $FLAKE#disko-install -- <hostname> $FLAKE
```

### 6. Update Flake Inputs

```bash
nix flake update
```

### 7. Linting & formatting

| Tool      | Command   | Notes                        |
| --------- | --------- | ---------------------------- |
| `treefmt` | `treefmt` | Formats and lints all files. |

### 8. Run tests for a single check

Use `nix build .#checks.<system>.<name>` to run individual checks, or use
`nix test .#check.<system>.<name>` to run tests in a sandboxed environment.

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

### 9. Building a specific package

Individual packages can be built with the `packages` attribute set. For example:

```bash
nix build .#packages.x86_64-linux.<package-name>
```

## Code‑Style Guidelines

The following rules are enforced by `treefmt`, and are expected to be followed by all contributors.

### Imports

- Group `lib`, `pkgs`, and custom modules at the top of each file, one per line.
- Do not import sub‑packages unless necessary.

### Format & Style

- `treefmt` will automatically format all files. Run `treefmt` manually if needed.
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

- Use `assert` for runtime checks; avoid `throw` and `builtins.abort`.
- When writing shell scripts, use `set -euo pipefail`.

### Testing

- All checks should be written in `flake-commons` and invoked via `nix flake check`.
- Add a new check by creating a derivation inside `flake-commons` and exposing it through the
  `checks` attribute.
- Keep the test suites independent from user‑specific secrets.

## CI Workflow

The project runs weekly automated updates via GitHub Actions (`.github/workflows/update.yml`) that:

- Update flake inputs using `nix flake update`
- Commit changes if CI passes

## Apps

The flake provides these buildable applications:

- `setup` - Setup script for applying configuration
- `disko-install` - Full installation with disk partitioning

## Utilities

Built-in utility functions from `nixcfgLib`:

- `mkApp` - Create flake app
- `mkDevShell` - Create dev shell
- `mkHome` - Create home configuration
- `mkNixos` - Create NixOS configuration
- `mkNixDarwin` - Create Darwin configuration
- `mkNixOnDroid` - Create NixOnDroid configuration
- `mkForEachSystem` - Create for each system

## Development Workflow

1. Enter the development shell:
   ```bash
   nix develop
   ```
2. Run `treefmt` to format/lint files (available in the dev shell).
3. Build or test changes with one of the commands above.
4. Commit and push.

Feel free to ask an agent for help with any of the commands listed here or for further explanations.

## Editing Conventions

These rules capture the editing discipline of this flake. `nixcfg` is the core library — downstream
flavor flakes (`nixcfg-home`, `nixcfg-work`) extend it via `recursiveUpdate`, so changes here often
propagate to other repositories.

### Two key invariants

1. **`default.nix` files are auto-imported.** `lib/customLib.nix` exports
   `getRecursiveDefaultNixFileList`, which recursively collects every `default.nix` under `nixos/`
   and `home/` (in both this flake and any consuming flake). To add a new module, drop a
   `default.nix` in a sensibly-named directory — it is picked up automatically. Do not edit a parent
   module's `imports` to "register" a new file. Non-`default.nix` files (e.g.
   `hardware-configuration.nix`, helper `.nix` files) are _not_ auto-imported and must be imported
   explicitly.
2. **Enabling a module pulls its packages in implicitly.** NixOS and Home Manager modules install
   the packages they need when `enable` is set. Do not search nixpkgs or add the same package to
   `environment.systemPackages` / `home.packages` if a module already wires it up. Only add packages
   explicitly when there is no module providing them.

### Decision tree: where do my changes go?

Walk this list in order and stop at the first match:

1. **Is there a `custom.*` option that already does this?** Use it. Examples: `custom.base.users`,
   `custom.base.system.btrfs.enable`, `custom.roles.nas.ai.enable`. Read the relevant role file in
   `nixos/roles/<name>/` before adding anything — the option you need probably exists.
2. **Does the change belong in an existing role?** Extend that role. Each role file defines
   `options.custom.roles.<name>` via `mkEnableOption` and guards `config` with `mkIf cfg.enable`.
3. **Is the change trivially small and host-specific?** Put it directly in
   `hosts/<type>/<host>/default.nix` or `home-<user>.nix`.
4. **Otherwise, create a new custom role.**

### New role template

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.roles.myrole;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom.roles.myrole = {
    enable = mkEnableOption "My role";
  };

  config = mkIf cfg.enable {
    # actual configuration
  };
}
```

Place at `nixos/roles/myrole/default.nix` or `home/roles/myrole/default.nix` (auto-imported). Hosts
enable it with `custom.roles.myrole.enable = true;`.

### Where does code go? Quick reference

| Request                                    | Edit                                                                                     |
| ------------------------------------------ | ---------------------------------------------------------------------------------------- |
| Add a NixOS module / role                  | `nixos/<area>/<name>/default.nix`                                                        |
| Add a Home Manager module / role           | `home/<area>/<name>/default.nix`                                                         |
| Add a host-only one-liner                  | `hosts/<type>/<host>/default.nix`                                                        |
| Add per-user Home Manager config on a host | `hosts/<type>/<host>/home-<user>.nix`                                                    |
| Add a package not in nixpkgs               | `pkgs/<name>/`                                                                           |
| Add a shared helper / option type          | `lib/customLib.nix`                                                                      |
| Wire a new flake input                     | `flake.nix` inputs + (if it ships a module) `lib/default.nix` or `lib/builders/modules/` |

`hosts/` is grouped by configuration type: `hosts/nixos/`, `hosts/macos/`, `hosts/nix-on-droid/`,
`hosts/non-nixos/`. Downstream flavor flakes target a single OS type and use a flat `hosts/<host>/`
layout instead.

### Propagating changes downstream

A breaking change here will fail in `nixcfg-home` / `nixcfg-work` at lock time. Before pushing:

1. Commit locally (do not push yet).
2. In the consuming flake, temporarily set `nixcfg.url = "path:/home/chr/code/nixcfg";`.
3. `nix flake update nixcfg && nix flake check` — fix and amend if it breaks.
4. On green: push `nixcfg`, restore `nixcfg.url = "github:rake5k/nixcfg";`, relock, commit, push.

### Common pitfalls

- **Adding a package that a module already installs.** Check the module first; if `enable` is on,
  the package is already there.
- **Adding to an `imports` list.** Almost never needed — drop a `default.nix` in the right directory
  instead.
- **Putting downstream-specific config in core.** This flake is consumed by `nixcfg-home` and
  `nixcfg-work`; keep machine-specific or user-specific defaults out of `nixos/` and `home/` here.
- **Hardcoding paths to secrets.** Use `custom.base.agenix.secrets.<name>.path` (or the homeage
  equivalent) — the path is generated.

---

_The file is intentionally verbose to aid readability for both humans and bots._
