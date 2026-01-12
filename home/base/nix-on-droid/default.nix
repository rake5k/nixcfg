{ config, lib, ... }:

let

  cfg = config.custom.base.nix-on-droid;

  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.base.nix-on-droid = {
      enable = mkEnableOption "Nix-on-Droid";

      flake = mkOption {
        type = types.str;
        default = "github:rake5k/nixcfg";
        description = "Flake URI of the Nix-on-Droid configuration to build.";
      };
    };
  };

  config = mkIf cfg.enable {
    custom.base.non-nixos.enable = true;

    home = {
      shellAliases = {
        nod-switch = "nix-on-droid switch --flake '${cfg.flake}'";
      };
    };

    targets.genericLinux.gpu.enable = mkForce false;
  };
}
