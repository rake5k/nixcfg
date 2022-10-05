{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.ops;

in

{
  options = {
    custom.roles.ops = {
      enable = mkEnableOption "Operations";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.lnav
    ];
  };
}
