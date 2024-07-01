{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      colorScheme = {
        foreground = mkOption {
          type = types.str;
          default = "#BBBBBB";
        };

        background = mkOption {
          type = types.str;
          default = "#000000";
        };

        base = mkOption {
          type = types.str;
          default = "#6586c8";
        };

        accent = mkOption {
          type = types.str;
          default = "#FF7F00";
        };

        warn = mkOption {
          type = types.str;
          default = "#FF5555";
        };
      };

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts.override { fonts = [ "VictorMono" ]; };
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font";
          description = "Font family";
        };

        familyMono = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Mono";
          description = "Mono Font family";
        };

        pango = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Bold 9";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font:style=Bold:size=9:antialias=true";
          description = "Font config";
        };
      };

      terminalCmd = mkOption {
        type = types.str;
        default = "${cfg.terminal.spawnCmd}";
        description = "Command to spawn the default terminal emulator";
      };

      wallpapersDir = mkOption {
        type = types.path;
        default = config.home.homeDirectory + "/Pictures/wallpapers";
        description = "Directory containing wallpapers";
      };
    };
  };

  config = mkIf cfg.enable {

    custom = {
      programs = {
        logseq.enable = true;
        syncthing.enable = true;
      };
      roles = {
        desktop = {
          cursors.enable = true;
          grobi.enable = true;
          gtk.enable = true;
          redshift.enable = true;
          terminal.enable = true;
          xmonad.enable = true;
        };
      };
    };

    home.packages = with pkgs; [
      gnome.gnome-characters
      gnome.nautilus
      gnome.pomodoro
      gnome.seahorse
      mupdf
      peek
      gifski
      parcellite
      xclip
      xzoom
    ];

    services.gnome-keyring.enable = true;

    xdg = {
      mime.enable = true;
      mimeApps.defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };

    xsession = {
      enable = true;
      initExtra = ''
        ${lib.getBin pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
      '';
      numlock.enable = true;
    };
  };
}
