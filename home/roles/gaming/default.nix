{
  config,
  lib,
  pkgs,
  ...
}:

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
    custom.roles.gaming = {
      comms.enable = true;
      mangohud.enable = true;
    };

    home.packages = with pkgs; [
      # Game libs
      heroic
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
