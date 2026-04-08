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

        # Shell apps for ripping
        (writeShellApplication {
          name = "mp3conv";
          runtimeInputs = with pkgs; [
            abcde
            lame
            ffmpeg_6
          ];
          text = builtins.readFile ./scripts/mp3conv.sh;
        })
        (writeShellApplication {
          name = "ripdvd-mp4";
          runtimeInputs = with pkgs; [
            handbrake
            ffmpeg_6
          ];
          text = builtins.readFile ./scripts/ripdvd-mp4.sh;
        })
      ];

      shellAliases = {
        ripcd-mp3 = "abcde -c ~/.config/abcde/abcde_mp3_lame.conf";
        ripcd-flac = "abcde -c ~/.config/abcde/abcde_lossless_flac.conf";
      };
    };
  };
}
