{ config, lib, ... }:

let

  cfg = config.custom.roles.web.nextcloud-client;

  inherit (lib) mkEnableOption mkIf;

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

    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
