{ config, lib, ... }:

with lib;

let

  cfg = config.custom.nix.autoUpgrade;

in

{
  options.custom.nix.autoUpgrade = {
    enable = mkEnableOption "Enable automatic upgrades";
    flake = mkOption {
      type = types.str;
      default = "github:christianharke/nixcfg";
      description = "Flake URI of the NixOS configuration to build.";
    };
  };

  config = mkIf cfg.enable {
    system.autoUpgrade = {
      inherit (cfg) flake;
      enable = true;
      allowReboot = false;
      dates = "4:40";
    };
  };
}
