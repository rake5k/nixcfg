{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.desktop.mobile;

in

{
  options = {
    custom.roles.desktop.mobile = {
      enable = mkEnableOption "Mobile computer settings";
    };
  };

  config = mkIf cfg.enable { services.poweralertd.enable = true; };
}
