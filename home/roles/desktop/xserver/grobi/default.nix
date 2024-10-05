{ config, lib, inputs, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.grobi;

  fallbackRule = {
    name = "Fallback";
    configure_single = cfg.fallbackOutput;
  };

in

{
  options = {
    custom.roles.desktop.xserver.grobi = {
      enable = mkEnableOption "Grobi config";

      fallbackOutput = mkOption {
        type = types.str;
        description = "Fallback output if no rule matches";
      };

      rules = mkOption {
        type = with types; listOf attrs;
        default = [
          fallbackRule
        ];
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
      enable = true;
      rules = cfg.rules ++ [ fallbackRule ];
      executeAfter = [
        "${lib.getExe pkgs.feh} --no-fehbg --bg-fill --randomize ${inputs.wallpapers}"
        "${pkgs.polybar}/bin/polybar-msg cmd restart"
      ];
    };
  };
}
