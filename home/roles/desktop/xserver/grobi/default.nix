{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.xserver.grobi;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  mkEachSingleOutput =
    outputs:
    map (output: {
      name = output;
      outputs_connected = [ output ];
      outputs_disconnected = lib.remove output outputs;
      configure_single = output;
      primary = output;
      atomic = false;
    }) outputs;

in

{
  options = {
    custom.roles.desktop.xserver.grobi = {
      enable = mkEnableOption "Grobi config";

      availableOutputs = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "List of all outputs to be managed by grobi";
      };

      rules = mkOption {
        type = with types; listOf attrs;
        default = [ ];
        description = "Grobi rules";
      };

      wallpaperCmd = mkOption {
        type = types.str;
        description = "Command to set the wallpaper";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grobi
    ];

    programs.feh.enable = true;

    services.grobi = {
      enable = true;
      rules = cfg.rules ++ mkEachSingleOutput cfg.availableOutputs;
      executeAfter = [
        cfg.wallpaperCmd
        "${pkgs.polybar}/bin/polybar-msg cmd restart"
      ];
    };
  };
}
