{ config, pkgs, ... }:

{
  imports = [ ./hardware ];

  custom = {
    base.users = [ "demo" "christian" ];
    roles = {
      android.enable = true;
      desktop.enable = true;
      gaming.enable = true;
      printing.enable = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = import ./state-version.nix;
}
