{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.wayland.kanshi;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop.wayland.kanshi = {
      enable = mkEnableOption "Kanshi config";

      settings = mkOption {
        type = with types; listOf attrs;
        default = [ ];
        description = "Kanshi settings";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kanshi
    ];

    services.kanshi = {
      enable = true;
      inherit (cfg) settings;
    };
  };
}
