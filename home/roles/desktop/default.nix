{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts.override { fonts = [ "VictorMono" ]; };
          description = "Font derivation";
        };

        family = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font";
          description = "Font family";
        };

        familyMono = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Mono";
          description = "Mono Font family";
        };

        pango = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font Bold 9";
          description = "Font config";
        };

        xft = mkOption {
          type = types.str;
          default = "VictorMono Nerd Font:style=Bold:size=9:antialias=true";
          description = "Font config";
        };
      };
    };
  };

  config = mkIf cfg.enable {

    custom = {
      roles = {
        desktop = {
          gtk.enable = true;
          passwordManager.enable = true;
          terminal.enable = true;
          wiki.enable = true;
        };
      };
    };

    home.packages = with pkgs; [
      gnome.gnome-characters
      gnome.nautilus
      gnome.pomodoro
      gnome.seahorse
      psensor
    ];

    services.gnome-keyring.enable = true;
  };
}
