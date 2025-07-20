{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.multimedia.video;

in

{
  options = {
    custom.roles.multimedia.video = {
      enable = mkEnableOption "Video";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        plex-media-player
      ];
    };

    custom.roles.multimedia.video.mpv.enable = true;
  };
}
