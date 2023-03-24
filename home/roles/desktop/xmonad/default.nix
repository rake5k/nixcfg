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
          font = {
            inherit (desktopCfg.font) package;
            config = desktopCfg.font.xft;
          };
          height = statusbarHeight;
          monitors.battery = desktopCfg.mobile.enable;
        };

        xmonad = {
          inherit (desktopCfg) locker terminalCmd;

          enable = true;
          autoruns = {
            "nm-applet" = 1;
            "${desktopCfg.terminalCmd}" = 1;
          };
          launcherCmd = "dmenu_run -i -fn \"${desktopCfg.font.xft}\" -h ${toString statusbarHeight}";
          passwordManager = {
            command = mkDefault "1password";
            wmClassName = mkDefault "1Password";
          };
        };
      };
    };
  };
}
