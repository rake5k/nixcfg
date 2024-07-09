{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.xserver.redshift;

in

{
  options = {
    custom.roles.desktop.xserver.redshift = {
      enable = mkEnableOption "Redshift";
    };
  };

  config = mkIf cfg.enable {
    services.redshift = {
      enable = true;
      latitude = 47.5;
      longitude = 8.75;
      settings.redshift.brightness-night = "0.8";
      temperature.night = 3500;
    };
  };
}
