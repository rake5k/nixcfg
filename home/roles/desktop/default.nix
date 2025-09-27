{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optionals
    types
    ;
  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerd-fonts.monofur;
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "Monofur Nerd Font";
          description = "Font family";
        };

        pango = mkOption {
          type = types.str;
          default = "Monofur Nerd Font Bold 10";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "Monofur Nerd Font:style=Bold:size=10:antialias=true";
          description = "Font config";
        };
      };
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; optionals isLinux [ seahorse ];

    services.gnome-keyring.enable = isLinux;

    xdg.userDirs = lib.mkIf isLinux {
      enable = true;
      createDirectories = true;
    };
  };
}
