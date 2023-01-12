{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.web.nextcloud-client;
  pkg =
    if config.custom.base.non-nixos.enable
    then (config.lib.custom.nixGLWrap pkgs.nextcloud-client)
    else pkgs.nextcloud-client;

in

{
  options = {
    custom.roles.web.nextcloud-client = {
      enable = mkEnableOption "Nextcloud client";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkg ];

    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
