{ config, lib, ... }:

let

  cfg = config.custom.roles.nas.backup;

  inherit (lib) mkEnableOption mkForce mkIf;

  inherit (config.custom.base.system.btrfs.btrbk) snapshotDir;
  inherit (config.custom.base) hostname;

  btrbkId = "id_ed25519_btrbk";

in

{
  options = {
    custom.roles.nas.backup = {
      enable = mkEnableOption "NAS backup";
    };
  };

  config = mkIf cfg.enable {

    # Allow btrbk user to read ssh key file
    age.secrets."${btrbkId}" = {
      owner = mkForce "btrbk";
      mode = mkForce "400";
    };

    custom.base.agenix.secrets = [ btrbkId ];

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
      persist = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m 1y";
          snapshot_preserve_min = "2d";
          snapshot_dir = snapshotDir;

          target_preserve = "20d 10w 6m";
          target_preserve_min = "no";
          target = "ssh://sv-syno-01.home.local/volume1/btrbk/${hostname}";

          ssh_identity = config.age.secrets."${btrbkId}".path;
          ssh_user = "btrbk";

          # Synology Hack (https://github.com/digint/btrbk/issues/383#issuecomment-823808283)
          compat = "ignore_receive_errors";

          volume."/" = {
            subvolume = {
              persist = { };
            };
          };
        };
      };

      # Remote data backup to SSH
      data-remote = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve = "7d 4w 6m";
          snapshot_preserve_min = "2d";
          snapshot_dir = "/data${snapshotDir}";

          target_preserve = "20d 10w 6m 1y";
          target_preserve_min = "no";
          target = "ssh://sv-syno-01.home.local/volume1/btrbk/${hostname}";

          ssh_identity = config.age.secrets."${btrbkId}".path;
          ssh_user = "btrbk";

          # Synology Hack (https://github.com/digint/btrbk/issues/383#issuecomment-823808283)
          compat = "ignore_receive_errors";

          volume."/data" = {
            subvolume = {
              "container" = { };
              "home" = { };
              "photo" = { };
              "share" = { };
              "syncthing" = { };
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

          target_preserve = "7d";
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
      "d /data${snapshotDir} 0755 root root"
    ];
  };
}
