{ config, lib, pkgs, ... }:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  xCfg = desktopCfg.xserver;
  cfg = xCfg.grobi;

in

{
  options = {
    custom.roles.desktop.xserver.grobi = {
      enable = mkEnableOption "Grobi config";

      rules = mkOption {
        type = with types; listOf attrs;
        default = [ ];
        description = "Grobi rules";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grobi
      xorg.xrandr
    ];

    programs.feh.enable = true;

    services.grobi = {
      inherit (cfg) rules;
      enable = true;
      executeAfter = [
        "${lib.getExe pkgs.feh} --no-fehbg --bg-fill --randomize ${desktopCfg.wallpapersDir}"
        "${pkgs.polybar}/bin/polybar-msg cmd restart"
      ];
    };
  };
}
