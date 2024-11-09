{
  config,
  lib,
  pkgs,
  ...
}:

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

    # Necessary for easyeffects
    programs.dconf.enable = true;

    security.rtkit.enable = config.services.pipewire.enable;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
}
