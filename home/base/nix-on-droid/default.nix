{ config, lib, ... }:

with lib;

let

  cfg = config.custom.base.nix-on-droid;
  flakeBaseDir = config.home.homeDirectory + "/.nix-config";

in

{
  options = {
    custom.base.nix-on-droid = {
      enable = mkEnableOption "NixOnDroid";
    };
  };

  config = mkIf cfg.enable {
    custom.base.non-nixos = {
      enable = true;
      installNix = false;
    };

    home = {
      shellAliases = {
        nod-switch = "nix-on-droid switch --flake '${flakeBaseDir}'";
      };
    };
  };
}
