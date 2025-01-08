{ config, lib, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  xCfg = desktopCfg.xserver;
  cfg = xCfg.spectrwm;

in

{
  options = {
    custom.roles.desktop.xserver.spectrwm = {
      enable = mkEnableOption "Spectrwm window manager";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.spectrwm = {
      autoruns = {
        "kitty" = 1;
      };
      font = {
        inherit (desktopCfg.font) package xft;
      };
    };
  };
}
