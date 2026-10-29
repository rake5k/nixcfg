# AGENTS.md

## Secrets Management

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

### 1. Build

```bash
nix flake check                                   # build all outputs + run all checks
nix build .#packages.x86_64-linux.nixos           # demo NixOS host
nix build .#packages.x86_64-linux.non-nixos-demo  # demo Home Manager activation package
nix build .#checks.x86_64-linux.<name>            # single check from flake-commons
```

### 2. Rebuild configurations

This is a base flake and defines **no real hosts**. Never apply a config from here — building
`nixcfg#<host>` fails with "host not defined". Real hosts live in downstream flakes (`nixcfg-home`,
`nixcfg-work`) whose `nixcfg.url = "github:rake5k/nixcfg"`. Find the one that owns a host with
`grep -rln <hostname> ~/code/*/flake.nix` (excluding this repo), then apply from there.

To apply an **unpushed** change from here, rebuild the downstream host with the input overridden to
this local checkout:

```bash
sudo nixos-rebuild switch --flake ~/code/nixcfg-home#<host> \
  --override-input nixcfg ~/code/nixcfg
```

Prefer `nixos-rebuild test` (no boot entry) over `switch` while iterating; `switch` once confirmed
good. On non-NixOS use `hm-switch`; on Nix-on-Droid `nix-on-droid switch --flake .#<hostname>`.

### 3. Setup (first-time configuration)

```bash
# Apply system configuration
nix run github:rake5k/nixcfg#setup -- <flake-url>

# Fresh NixOS install with disk partitioning
nix run $FLAKE#disko-install -- <hostname> $FLAKE
```

### 4. Linting & formatting

Run `treefmt` (available in the dev shell, `nix develop`).

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

No hosted CI builds the flake outputs. Run `nix flake check` locally before pushing.

Dependabot (`.github/dependabot.yml`) opens weekly pull requests updating the flake inputs.

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

### Default applications

`custom.roles.desktop` enables `xdg.mimeApps` and owns `mimeapps.list` (`force = true`), so
associations set through a file manager do not persist. Each module that installs an application
maps that application's MIME types and URL schemes in `xdg.mimeApps.defaultApplications`, e.g. the
mpv module maps audio and video, `users/christian/vim` maps text and code. List the canonical
[shared-mime-info](https://gitlab.freedesktop.org/xdg/shared-mime-info) types (GIO, used by Nemo)
plus the libmagic variants (`file --mime-type`) that `xdg-open` reports outside GNOME and Cinnamon
where File::MimeInfo is missing. Where one extension stands for several formats (`.ts`), the
secondary application goes into `xdg.mimeApps.associations.added`. Applications that alone register
a URL scheme need no entry. A module that takes over a type another module maps sets it with
`mkForce`, e.g. `custom.roles.ops` maps `text/x-log` to lnav over nvim, through an
`xdg.desktopEntries` entry since lnav ships none. `custom.roles.desktop.terminal` routes
`Terminal=true` desktop entries to the configured terminal through `xdg.terminal-exec`. yazi
bypasses `mimeapps.list` for `text/*` and opens it with `$EDITOR`, so a module that maps a text type
also adds a `programs.yazi.settings.open.prepend_rules` entry, as the ops role does.

### Common pitfalls

- **Adding a package that a module already installs.** Check the module first; if `enable` is on,
  the package is already there.
- **Adding to an `imports` list.** Almost never needed — drop a `default.nix` in the right directory
  instead.
- **Putting downstream-specific config in core.** This flake is consumed by `nixcfg-home` and
  `nixcfg-work`; keep machine-specific or user-specific defaults out of `nixos/` and `home/` here.
- **Hardcoding paths to secrets.** Use `custom.base.agenix.secrets.<name>.path` (or the homeage
  equivalent) — the path is generated.
