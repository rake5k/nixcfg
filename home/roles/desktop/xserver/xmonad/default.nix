{ config, lib, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  xCfg = desktopCfg.xserver;
  cfg = xCfg.xmonad;

in

{
  options = {
    custom.roles.desktop.xserver.xmonad = {
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
          inherit (xCfg) colorScheme;
          font = {
            inherit (desktopCfg.font) package;
            config = desktopCfg.font.xft;
          };
          height = 20;
          monitors.battery = desktopCfg.mobile.enable;
        };

        xmonad = {
          inherit (xCfg) colorScheme locker;

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
}
