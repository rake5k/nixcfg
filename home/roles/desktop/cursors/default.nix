{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.cursors;

in

{
  options = {
    custom.roles.desktop.cursors = {
      enable = mkEnableOption "Cursors config";

      pointerCursorName = mkOption {
        type = types.str;
        default = "Bibata-Modern-DodgerBlue";
        description = "Pointer cursors to use from the Bibata cursors package";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.dconf
      ];

      pointerCursor = {
        name = cfg.pointerCursorName;
        package = pkgs.bibata-extra-cursors;
        size = 22;
      };
    };

    gtk.enable = true;

    xsession.enable = true;
  };
}
