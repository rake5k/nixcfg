{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.backup;

  inherit (lib) mkEnableOption mkIf;

  inherit (config.custom.base.system.btrfs.btrbk) snapshotDir;

in

{
  options = {
    custom.roles.nas.backup = {
      enable = mkEnableOption "NAS backup";
    };
  };

  config = mkIf cfg.enable {
    custom.base.system.btrfs = {
      btrbk.enable = true;
      impermanence.extraDirectories = [ snapshotDir ];
    };

    services.btrbk.instances = {
      data = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";
          volume."/data" = {
            subvolume = {
              "container" = { };
              "home" = { };
              "plex" = { };
              "syncthing" = { };
            };
          };
        };
      };

      persist = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = snapshotDir;
          subvolume = "/persist";
        };
      };
    };

    # Btrbk does not create snapshot directories automatically, so create one here.
    systemd.tmpfiles.rules = [
      "d ${snapshotDir} 0755 root root"
    ];
  };
}
