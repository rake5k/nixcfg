{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let

  cfg = config.custom.installer;

  inherit (lib) mkOption types;

in

{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  options.custom.installer = {
    authorizedKeys = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        SSH public keys authorized for `root` on the installer. Required to drive
        an unattended install from another machine, e.g. via nixos-anywhere.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = "Additional packages available in the installer environment.";
    };
  };

  config = {
    # nixos-anywhere connects as root; keys only, no password auth.
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "prohibit-password";
    };

    users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    # Hardware inspection for gathering disk ids, CPU and GPU before installing.
    environment.systemPackages =
      with pkgs;
      [
        pciutils
        smartmontools
        usbutils
      ]
      ++ cfg.extraPackages;

    # zstd builds the image considerably faster than the default xz.
    isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  };
}
