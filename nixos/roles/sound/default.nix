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
    sound.enable = true;
    hardware = {
      bluetooth.enable = true;
      pulseaudio = {
        enable = true;
        package = pkgs.pulseaudioFull;
      };
    };
    environment.systemPackages = [ pkgs.pavucontrol ];
  };
}
