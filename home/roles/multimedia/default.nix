{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.multimedia;

in

{
  options = {
    custom.roles.multimedia = {
      enable = mkEnableOption "Multimedia";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        blueberry
        easyeffects
        plex-media-player
        spotifywm
      ];
    };

    custom.roles.multimedia.mpv.enable = true;

    services.easyeffects.enable = true;
  };
}
