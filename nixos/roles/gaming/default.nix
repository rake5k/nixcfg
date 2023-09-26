{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.gaming;

in

{
  options = {
    custom.roles.gaming = {
      enable = mkEnableOption "Gaming computer config";
    };
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      dedicatedServer.openFirewall = true;
      remotePlay.openFirewall = true;
    };

    # Xbox controller
    hardware.xpadneo.enable = true;
  };
}
