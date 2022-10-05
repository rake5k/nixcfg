{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.xmonad;

  dmenuPatched = pkgs.dmenu.override {
    patches = builtins.map builtins.fetchurl [
      {
        url = "https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.0.diff";
        sha256 = "1dllfy9yznjcq65ivwkd77377ccfry72jmy3m77ms6ns62x891by";
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

      inherit (desktopCfg) locker;

      autoruns = {
        "alacritty" = 1;
      };
      font = {
        inherit (desktopCfg.font) package xft;
      };
      dmenu = {
        package = dmenuPatched;
        runCmd = "dmenu_run -fn \"${desktopCfg.font.xft}\" -h 22";
      };
      xmobar = {
        enable = true;
        mobile = desktopCfg.mobile.enable;
      };
    };
  };
}
