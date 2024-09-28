{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xserver;

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
            locker.enable = true;
            redshift.enable = true;

            xmonad = {
              inherit (cfg) colorScheme;

              enable = true;
              autoruns = {
                "${desktopCfg.terminal.spawnCmd}" = 1;
                "blueberry-tray" = 1;
                "nm-applet" = 1;
                "parcellite" = 1;
                "steam -silent" = 8;
              };
              launcherCmd = "dmenu_run -c -i -fn \"${desktopCfg.font.family}:style=Bold:size=20:antialias=true\" -l 8 -nf \"#C5C8C6\" -sb \"#373B41\" -sf \"#C5C8C6\" -p \"run:\"";
              terminalCmd = mkDefault desktopCfg.terminal.spawnCmd;
              passwordManager = {
                command = mkDefault "1password";
                wmClassName = mkDefault "1Password";
              };
              wiki = {
                command = mkDefault "logseq";
                wmClassName = mkDefault "Logseq";
              };
            };
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
