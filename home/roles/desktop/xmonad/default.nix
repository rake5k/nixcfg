{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xmonad;

in

{
  options = {
    custom.roles.desktop.xmonad = {
      enable = mkEnableOption "Xmonad window manager";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs = {
        dmenu = {
          enable = true;
          font = {
            inherit (desktopCfg.font) package;
          };
        };

        dunst = {
          enable = true;
          font = {
            inherit (desktopCfg.font) package family;
          };
        };

        picom.enable = true;

        polybar = {
          enable = true;
          inherit (desktopCfg) colorScheme;
          font = {
            inherit (desktopCfg.font) package;
            config = desktopCfg.font.xft;
          };
          height = 20;
          monitors.battery = desktopCfg.mobile.enable;
        };

        xmonad = {
          inherit (desktopCfg) colorScheme locker terminalCmd;

          enable = true;
          autoruns = {
            "${desktopCfg.terminalCmd}" = 1;
            "blueberry-tray" = 1;
            "nm-applet" = 1;
            "parcellite" = 1;
            "steam -silent" = 8;
          };
          launcherCmd = "dmenu_run -c -i -fn \"${desktopCfg.font.family}:style=Bold:size=20:antialias=true\" -l 8 -nf \"#C5C8C6\" -sb \"#373B41\" -sf \"#C5C8C6\" -p \"run:\"";
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
}
