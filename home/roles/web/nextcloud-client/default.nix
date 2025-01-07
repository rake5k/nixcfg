{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.web.nextcloud-client;
  pkg = config.lib.nixGL.wrap pkgs.nextcloud-client;

in

{
  options = {
    custom.roles.web.nextcloud-client = {
      enable = mkEnableOption "Nextcloud client";
    };
  };

  config = mkIf cfg.enable {
    gtk.gtk3.bookmarks = [
      "file://${config.home.homeDirectory}/Nextcloud"
    ];

    home.packages = [ pkg ];

    services.nextcloud-client = {
      enable = true;
      package = pkg;
      startInBackground = true;
    };
  };
}
