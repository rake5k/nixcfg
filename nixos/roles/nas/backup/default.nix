{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.backup;

  inherit (lib) mkEnableOption mkIf;

  inherit (config.custom.base.system.btrfs.btrbk) snapshotDir;
  inherit (config.custom.base) hostname;

  backupId = "id_ed25519_backup";

in

{
  options = {
    custom.roles.nas.backup = {
      enable = mkEnableOption "NAS backup";
    };
  };

  config = mkIf cfg.enable {

    custom = {
      base.agenix.secrets = [ backupId ];
      roles.backup.rsync = {
        enable = true;
        jobs.backup = {
          identityFile = config.age.secrets.${backupId}.path;
          paths = [
            "/home"
            "/data/container"
            "/data/home"
            "/data/library"
            "/data/photo"
            "/data/share"
            "/data/syncthing"
          ];
          excludes = [
            "/data/container/steam-headless/games"
            "/data/container/steam-headless/home/*/.thumbnails/*"
            "/data/container/steam-headless/home/*/.cache/*"
            "/data/container/steam-headless/home/*/.local/share/Trash/*"
          ];
          target = "backup@sv-syno-01.lan.harke.ch:/volume1/NetBackup/${hostname}";
        };
      };
    };

    # Make sure a USB disk is available as `/dev/disk/by-label/btrbkusbn`
    # see: https://wiki.nixos.org/wiki/Full_Disk_Encryption#Unlocking_secondary_drives
    fileSystems."/mnt/btrbkusb" = {
      device = "/dev/disk/by-label/btrbkusb1";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
      ];
    };

    services.btrbk.instances = {
      # Remote root state backup to SSH
      root-remote = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w";
          snapshot_preserve_min = "2d";
          snapshot_dir = snapshotDir;

          volume."/" = {
            subvolume = {
              home = { };
              persist = { };
            };
          };
        };
      };

      # Local data snapshots only
      data-local = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";

          volume."/data" = {
            subvolume = {
              "container" = { };
              "home" = { };
              "library" = { };
              "photo" = { };
              "share" = { };
              "syncthing" = { };
            };
          };
        };
      };

      # Local backup to external disk
      data-external = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";

          target_preserve = "7d 4w 6m 10y";
          target_preserve_min = "no";

          volume."/data" = {
            target = "/mnt/btrbkusb/${hostname}";
            subvolume = {
              "plex" = { };
            };
          };
        };
      };
    };

    # Btrbk does not create snapshot directories automatically
    systemd.tmpfiles.rules = [
      "d ${snapshotDir} 0755 root root"
      "d /data${snapshotDir} 0755 root root"
    ];
  };
}
