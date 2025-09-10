{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let

  cfg = config.custom.roles.desktop;

  inherit (lib)
    literalExpression
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

      autoruns = mkOption {
        type = with types; attrsOf int;
        default = { };
        description = ''
          Applications to be launched in a workspace of choice.
        '';
        example = literalExpression ''
          {
            "firefox" = 1;
            "slack" = 2;
            "spotify" = 3;
          }
        '';
      };

      wallpapersDir = mkOption {
        type = types.path;
        default = inputs.wallpapers;
        description = "Path to the wallpaper images";
      };
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; optionals isLinux [ seahorse ];

    services.gnome-keyring.enable = isLinux;

    xdg.userDirs = mkIf isLinux {
      enable = true;
      createDirectories = true;
    };
  };
}
