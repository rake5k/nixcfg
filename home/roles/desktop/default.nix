{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop;

  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.roles.desktop = {
      enable = mkEnableOption "Desktop";

      font = {
        package = mkOption {
          type = types.package;
          default = pkgs.nerdfonts.override { fonts = [ "Monofur" ]; };
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

    custom = {
      roles = {
        desktop = {
          gtk.enable = isLinux;
          passwordManager.enable = isLinux;
          terminal.enable = true;
          wiki.enable = true;
        };
      };
    };

    home.packages =
      with pkgs;
      optionals isLinux [
        gnome-characters
        gnome-pomodoro
        nautilus
        quickemu
        seahorse
      ];

    services.gnome-keyring.enable = isLinux;

    xdg.userDirs = lib.mkIf isLinux {
      enable = true;
      createDirectories = true;
    };
  };
}
