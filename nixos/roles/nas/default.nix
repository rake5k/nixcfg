{ config, lib, ... }:

let

  inherit (lib) mkEnableOption mkIf;

  cfg = config.custom.roles.nas;

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
        btrfs.impermanence.enable = true;
        luks.remoteUnlock = true;
        network.wol.enable = true;
      };

      roles.nas = {
        plex.enable = true;
        syncthing.enable = true;
      };
    };

    services.glances = {
      enable = true;
      openFirewall = true;
    };
  };
}
