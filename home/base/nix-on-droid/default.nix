{ config, lib, ... }:

let

  cfg = config.custom.base.nix-on-droid;
  flakeBaseDir = config.home.homeDirectory + "/.nix-config";

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.base.nix-on-droid = {
      enable = mkEnableOption "Nix-on-Droid";
    };
  };

  config = mkIf cfg.enable {
    custom.base.non-nixos.enable = true;

    home = {
      shellAliases = {
        nod-switch = "nix-on-droid switch --flake '${flakeBaseDir}'";
      };
    };
  };
}
