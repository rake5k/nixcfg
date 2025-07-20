{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.multimedia.music;

in

{
  options = {
    custom.roles.multimedia.music = {
      enable = mkEnableOption "Music";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        easyeffects
        spotifywm
      ];
    };

    services.easyeffects.enable = true;
  };
}
