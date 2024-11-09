{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.cursors;

in

{
  options = {
    custom.roles.desktop.xserver.cursors = {
      enable = mkEnableOption "Cursors config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.dconf ];

      pointerCursor = {
        name = "volantes_cursors";
        package = pkgs.volantes-cursors;
        size = 22;

        gtk.enable = true;
        x11.enable = true;
      };
    };

    gtk.enable = true;
    xsession.enable = true;
  };
}
