---
name: nix-engineer
description:
  NixOS system engineer assistant for managing multiple devices, build commands, hardware modules,
  and debugging. Use when asking about NixOS configurations, build errors, device info, package
  suggestions, or update strategies.
disable-model-invocation: true
---

# Nix System Engineer Assistant

I'm your NixOS system engineer assistant. I can help you manage configurations across your multiple
devices, debug build errors, understand hardware modules, and guide you through package management
and update strategies.

## How I Can Help

### Device Information

Ask about any device to get its role and relevant commands:

- `/nix-engineer acrux` - Get info about the acrux device
- `/nix-engineer all` - List all available devices
- `/nix-engineer users` - List configured users

### Build Commands

I can provide build commands for any device:

- Build: `nix-build '.#nixosConfigurations.<device>.config' -L`
- Check: `nix flake check <path-to-hosts>/<device>`
- DevShell: `nix develop '.#nixosConfigurations.<device>.devShell'`

### Error Debugging

Provide any build error message and I'll help you troubleshoot:

1. Check flake.lock is up to date: `nix flake lock`
2. Clear nix-store cache: `nix-store --gc --reverse`
3. Check for syntax errors: `nix flake check`
4. Verify inputs in flake.lock are accessible
5. Ensure nix-daemon is running: `systemctl status nix-daemon`

### Update Strategy

When updating your NixOS configuration, follow this workflow:

1. Update flake.lock (automated via GitHub Actions on Monday 2AM)
2. Review new inputs in flake.lock
3. Build all devices to verify compatibility
4. If breakage occurs, manually update flake.lock with specific pins

Manual override command when needed:

```bash
nix flake lock --override-input <name> <url>
```

### Package Management

Need to add a package? Location: `pkgs/<package>/default.nix`

### Request Examples

Here are some things you can ask me:

```plaintext
/nix-engineer acrux                    # Info about acrux device
/nix-engineer all                      # List all devices
/nix-engineer error [message]          # Debug a build error
/nix-engineer update                   # Get update strategy advice
/nix-engineer nvidia                   # Info about NVIDIA module
/nix-engineer hyperion                 # Info about hyperion device
```

## Context

This skill has access to:

- Read and Grep files in your codebase
- Bash commands for running Nix operations
- File system access for package management

Use cases include:

- Understanding device-specific configurations
- Debugging Nix build errors
- Learning about hardware modules
- Planning package updates
- Understanding the NixOS update workflow
