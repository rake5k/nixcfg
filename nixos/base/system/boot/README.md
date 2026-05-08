# Boot Configuration

This directory contains boot-related NixOS configuration modules.

## Plymouth Boot Screen

Plymouth provides a graphical splash screen during boot. By default, it is enabled in the base
configuration:

```nix
boot.plymouth.enable = true;
```

### References

- [NixOS Option: boot.plymouth](https://nixos.org/manual/nixos/stable/options#opt-boot.plymouth.enable)
