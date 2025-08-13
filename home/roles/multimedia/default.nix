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
      ];
    };

    custom.roles.multimedia = {
      books.enable = true;
      music.enable = true;
      video.enable = true;
    };
  };
}
