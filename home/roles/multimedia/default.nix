{ config, lib, pkgs, ... }:

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
        abcde
        easytag
        ffmpeg
        handbrake
        id3lib
        spotifywm
      ];

      file."bin/mp3conv" = {
        executable = true;
        source = ./scripts/mp3conv;
      };
    };

    programs.mpv.enable = true;
  };
}
