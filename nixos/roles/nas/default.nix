{
  config,
  lib,
  pkgs,
  ...
}:

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
        ai.enable = true;
        backup.enable = true;
        glances.enable = true;
        library.enable = true;
        photos.enable = true;
        plex.enable = true;
        power-notification.enable = true;
        samba.enable = true;
        steam-headless = {
          enable = true;
          services.steam-headless.port = 8084;
        };
        syncthing.enable = true;
        tls.enable = true;
      };
    };

    powerManagement.powertop.enable = true;

    environment.systemPackages = with pkgs; [
      yazi
    ];
  };
}
