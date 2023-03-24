{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xmonad;

  statusbarHeight = 20;

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
          height = statusbarHeight;
          monitors.battery = desktopCfg.mobile.enable;
        };

        xmonad = {
          inherit (desktopCfg) colorScheme locker terminalCmd;

          enable = true;
          autoruns = {
            "nm-applet" = 1;
            "${desktopCfg.terminalCmd}" = 1;
          };
          launcherCmd = "dmenu_run -c -i -fn \"${desktopCfg.font.family}:style=Bold:size=20:antialias=true\" -l 8 -p \"run:\"";
          passwordManager = {
            command = mkDefault "1password";
            wmClassName = mkDefault "1Password";
          };
        };
      };
    };
  };
}
