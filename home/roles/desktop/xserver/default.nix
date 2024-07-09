{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.xserver;

in

{
  options = {
    custom.roles.desktop.xserver = {
      enable = mkEnableOption "X Server";

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
    };
  };

  config = mkIf cfg.enable {

    custom = {
      roles = {
        desktop = {
          xserver = {
            cursors.enable = true;
            grobi.enable = true;
            redshift.enable = true;
            xmonad.enable = true;
          };
        };
      };
    };

    home.packages = with pkgs; [
      peek
      gifski
      mupdf
      parcellite
      xclip
      xzoom
    ];

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
