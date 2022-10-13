{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.ranger;

in

{
  options = {
    custom.programs.ranger = {
      enable = mkEnableOption "Ranger";

      bookmarks = mkOption {
        type = types.lines;
        default = "";
        description = "Bookmarks to be added";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        ranger

        # dependencies
        _7zz
        atool
        catdoc
        exiftool
        ffmpeg
        ffmpegthumbnailer
        imagemagick
        mediainfo
        odt2txt
        pandoc
        transmission
        trash-cli
        ueberzug
        unrar
        w3m
        xlsx2csv
        #xpdf # insecure
      ];

      sessionVariables = {
        RANGERCD = true;
      };
    };

    xdg = {
      configFile = {
        "ranger/commands.py".source = ./config/commands.py;
        "ranger/rc.conf".text = import ./config/rc.conf.nix { inherit config pkgs; };
        "ranger/rifle.conf".source = ./config/rifle.conf;
        "ranger/scope.sh" = {
          executable = true;
          source = ./config/scope.sh;
        };
      };

      dataFile."ranger/bookmarks".text = cfg.bookmarks;
    };
  };
}
