{ config, lib, ... }:

let

  cfg = config.custom.roles.nas;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.nas = {
      enable = mkEnableOption "NAS config";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.system = {
        boot.secureBoot = true;
        btrfs = {
          enable = true;
          impermanence.enable = true;
        };
        luks.remoteUnlock = true;
        network.wol.enable = true;
      };

      roles.nas = {
        backup.enable = true;
        glances.enable = true;
        power-notification.enable = true;
        plex.enable = true;
        syncthing.enable = true;
        tls.enable = true;
      };
    };

    powerManagement.powertop.enable = true;
  };
}
