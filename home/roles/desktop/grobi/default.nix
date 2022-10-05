{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.grobi;

in

{
  options = {
    custom.roles.desktop.grobi = {
      enable = mkEnableOption "Grobi config";

      rules = mkOption {
        type = with types; listOf attrs;
        default = [ ];
        description = "Grobi rules";
      };

      wallpapersDir = mkOption {
        type = types.path;
        default = config.home.homeDirectory + "/Pictures/wallpapers";
        description = "Directory containing wallpapers";
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
        "${pkgs.feh}/bin/feh --no-fehbg --bg-fill --randomize ${cfg.wallpapersDir}"
      ];
    };
  };
}
