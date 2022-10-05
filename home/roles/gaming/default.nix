{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.gaming;

in

{
  options = {
    custom.roles.gaming = {
      enable = mkEnableOption "Gaming";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Comms
      discord
      teamspeak_client

      # Game libs
      lutris
      steam

      # Runtimes
      wine

      # Games
      superTux
      superTuxKart
      wesnoth
      zeroad
    ];
  };
}
