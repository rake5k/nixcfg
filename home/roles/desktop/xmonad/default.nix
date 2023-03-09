{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xmonad;

  dmenuPatched = pkgs.dmenu.override {
    patches = builtins.map builtins.fetchurl [
      {
        url = "https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.2.diff";
        sha256 = "0jabb2ycfn3xw0k2d2rv7nyas5cwjr6zvwaffdn9jawh62c50qy5";
      }
    ];
  };

in

{
  options = {
    custom.roles.desktop.xmonad = {
      enable = mkEnableOption "Xmonad window manager";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.xmonad = {
      enable = true;

      inherit (desktopCfg) locker terminalCmd;

      autoruns = {
        "nm-applet" = 1;
        "${desktopCfg.terminalCmd}" = 1;
      };
      dmenu = {
        package = dmenuPatched;
        runCmd = "dmenu_run -fn \"${desktopCfg.font.xft}\" -h 22";
      };
      font = {
        inherit (desktopCfg.font) package pango;
      };
      passwordManager = {
        command = mkDefault "1password";
        wmClassName = mkDefault "1Password";
      };
      xmobar = {
        enable = true;
        mobile = desktopCfg.mobile.enable;
      };
    };
  };
}
