{
  config,
  lib,
  ...
}:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.multimedia.video;

in

{
  options = {
    custom.roles.multimedia.video = {
      enable = mkEnableOption "Video";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.multimedia.video.mpv.enable = true;
  };
}
