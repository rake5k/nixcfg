{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.trayer;

in

{
  options = {
    custom.programs.trayer = {
      enable = mkEnableOption "Trayer";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      networkmanagerapplet
      trayer
    ];
  };
}

