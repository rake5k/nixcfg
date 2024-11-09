{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.multimedia.converters;

in

{
  options = {
    custom.roles.multimedia.converters = {
      enable = mkEnableOption "Enable converting tools";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.abcde.enable = true;

    home = {
      packages = with pkgs; [
        handbrake
        ffmpeg_6
        picard
      ];

      file = {
        "bin/mp3conv" = {
          executable = true;
          source = ./scripts/mp3conv;
        };
        "bin/ripdvd-mp4" = {
          executable = true;
          source = ./scripts/ripdvd-mp4;
        };
      };

      shellAliases = {
        ripcd-mp3 = "abcde -c ~/.config/abcde/abcde_mp3_lame.conf";
        ripcd-flac = "abcde -c ~/.config/abcde/abcde_lossless_flac.conf";
      };
    };
  };
}
