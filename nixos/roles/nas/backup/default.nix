{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.backup;

  inherit (lib) mkEnableOption mkIf;

  inherit (config.custom.base.system.btrfs.btrbk) snapshotDir;
  inherit (config.custom.base) hostname;

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

    # Make sure a USB disk is available as `/dev/disk/by-label/btrbkusb`
    # see: https://wiki.nixos.org/wiki/Full_Disk_Encryption#Unlocking_secondary_drives
    fileSystems."/mnt/btrbkusb" = {
      device = "/dev/disk/by-label/btrbkusb";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
      ];
    };

    services.btrbk.instances = {
      # Remote root state backup to SSH (TODO)
      persist = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = snapshotDir;
          subvolume = "/persist";
        };
      };

      # Remote data backup to SSH (TODO)
      data-remote = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";

          volume."/data" = {
            subvolume = {
              "home" = { };
            };
          };
        };
      };

      # Local backup to external disk
      data-local = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";

          target_preserve = "20d 10w 6m";
          target_preserve_min = "no";

          volume."/data" = {
            target = "/mnt/btrbkusb/${hostname}";
            subvolume = {
              "container" = { };
              "plex" = { };
              "syncthing" = { };
            };
          };
        };
      };
    };

    # Btrbk does not create snapshot directories automatically, so create one here.
    systemd.tmpfiles.rules = [
      "d ${snapshotDir} 0755 root root"
    ];
  };
}
