{ config, lib, ... }:

with lib;

let

  cfg = config.custom.nix.autoUpgrade;

  inherit (config.lib.custom) mkNtfyCommand ntfyTokenSecret ntfyUrlSecret;
  inherit (lib) toUpper;

  prettyHostname = "${toUpper config.custom.base.hostname}";

in

{
  options.custom.nix.autoUpgrade = {
    enable = mkEnableOption "Enable automatic upgrades";
    flake = mkOption {
      type = types.str;
      default = "github:rake5k/nixcfg";
      description = "Flake URI of the NixOS configuration to build.";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base = {
        agenix.secrets = [
          ntfyTokenSecret
          ntfyUrlSecret
        ];
      };
    };

    system.autoUpgrade = {
      inherit (cfg) flake;
      enable = true;
      allowReboot = false;
      dates = "4:40";
    };

    systemd.services.nixos-upgrade = {
      preStart = ''
        ${mkNtfyCommand config.age.secrets {
          title = "${prettyHostname} is starting to upgrade NixOS...";
          message = "Let's have a refresh!";
          tags = [ "dizzy" ];
        }}
      '';
    };
  };
}
