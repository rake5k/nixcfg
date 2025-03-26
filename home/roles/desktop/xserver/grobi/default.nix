{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.xserver.grobi;

  inherit (lib)
    getExe
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
      rules = cfg.rules ++ mkEachSingleOutput cfg.availableOutputs;
      executeAfter = [
        "${getExe pkgs.feh} --no-fehbg --bg-fill --randomize ${inputs.wallpapers}"
        "${pkgs.polybar}/bin/polybar-msg cmd restart"
      ];
    };
  };
}
