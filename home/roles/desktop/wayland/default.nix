{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.desktop.wayland;

  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options = {
    custom.roles.desktop.wayland = {
      enable = mkEnableOption "Wayland config";

      autoruns = mkOption {
        type = types.listOf config.lib.custom.autorunType;
        default = [ ];
        description = ''
          Applications to be launched in a workspace of choice.
        '';
        example = literalExpression ''
          [
            { command = "firefox"; workspace = 1; }
            { command = "slack"; workspace = 2; }
            { command = "spotify"; workspace= 3; }
          ]
        '';
      };

      wallpapersDir = mkOption {
        type = types.path;
        description = "Path to the wallpaper images";
      };
    };
  };

  config = mkIf cfg.enable {
    custom.roles.desktop.wayland = {
      kanshi.enable = true;
      river = {
        enable = true;
        inherit (cfg) autoruns wallpapersDir;

        lockerCfg = {
          package = pkgs.swaylock;

          # On NixOS: add `security.pam.services.swaylock = {};` to the system configuration.
          # On non-NixOS: install `swaylock` from the distribution's repository.
          # See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.swaylock.enable
          lockerCmd = "swaylock -f";
        };
      };
    };

    home.packages = with pkgs; [
      wl-clipboard
      wlr-randr
    ];

    xsession.enable = true;
  };
}
