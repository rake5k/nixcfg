{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.multimedia.converters;

  inherit (lib) mkEnableOption mkIf;

  mp3conv = pkgs.writeShellApplication {
    name = "mp3conv";
    runtimeInputs = with pkgs; [
      abcde
      lame
      ffmpeg_6
    ];
    text = builtins.readFile ./scripts/mp3conv.sh;
  };

  ripdvd-mp4 = pkgs.writeShellApplication {
    name = "ripdvd-mp4";
    runtimeInputs = with pkgs; [
      handbrake
      ffmpeg_6
    ];
    text = builtins.readFile ./scripts/ripdvd-mp4.sh;
  };

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
        mp3conv
        ripdvd-mp4
        (writeShellApplication {
          name = "ripdvd-bulk";
          runtimeInputs = [ ripdvd-mp4 ];
          text = ''
            for title in $1;
            do
              ripdvd-mp4 "$title"
            done
          '';
        })
      ];

      shellAliases = {
        ripcd-mp3 = "abcde -c ~/.config/abcde/abcde_mp3_lame.conf";
        ripcd-flac = "abcde -c ~/.config/abcde/abcde_lossless_flac.conf";
      };
    };
  };
}
