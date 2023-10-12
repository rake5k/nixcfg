{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.mobile;
  username = "nix-on-droid";

in

{
  options = {
    custom.roles.mobile = {
      enable = mkEnableOption "Mobile";
    };
  };

  config = mkIf cfg.enable {
    home = {
      inherit username;
    };

    custom.base.non-nixos = {
      enable = true;
      installNix = false;
    };
  };
}
