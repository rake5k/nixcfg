{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.sound;

in

{
  options = {
    custom.roles.sound = {
      enable = mkEnableOption "Audio config";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pavucontrol ];
    hardware.bluetooth.enable = true;
    security.rtkit.enable = lib.mkDefault config.services.pipewire.enable;
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };
  };
}
