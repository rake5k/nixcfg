{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.multimedia.video;

  plex = config.lib.nixGL.wrap pkgs.plex-media-player;

in

{
  options = {
    custom.roles.multimedia.video = {
      enable = mkEnableOption "Video";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        plex
      ];
    };

    custom.roles.multimedia.video.mpv.enable = true;
  };
}
