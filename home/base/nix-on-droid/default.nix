{ config, lib, ... }:

with lib;

let

  cfg = config.custom.base.nix-on-droid;

in

{
  options = {
    custom.base.nix-on-droid = {
      enable = mkEnableOption "NixOnDroid";
    };
  };

  config = mkIf cfg.enable {
    custom.base = {
      nix.enableStoreOptimization = false;
      non-nixos = {
        enable = true;
        installNix = false;
      };
    };
  };
}
