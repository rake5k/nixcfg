{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.web.messengers;

in

{
  options = {
    custom.roles.web.messengers = {
      enable = mkEnableOption "Messengers";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      element-desktop
      signal-desktop
      threema-desktop
    ];
  };
}
