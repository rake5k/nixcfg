{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.nas.backup;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    ;

  inherit (config.custom.base.system.btrfs.btrbk) snapshotDir;
  inherit (config.custom.base) hostname;

  borgId = "id_ed25519_borg";

in

{
  options = {
    custom.roles.nas.backup = {
      enable = mkEnableOption "NAS backup";
    };
  };

  config = mkIf cfg.enable {

    custom.base.agenix.secrets = [ borgId ];

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

    services = {
      borgmatic = {
        enable = true;
        settings = {
          exclude_patterns = [
            "/home/*/.cache"
            "*/.vim*.tmp"
          ];
          exclude_if_present = [ ".nobackup" ];
          keep_daily = 7;
          keep_weekly = 4;
          keep_monthly = 6;
          keep_yearly = 1;
          remote_path = "/usr/local/bin/borg";
          ssh_command = "${getExe pkgs.openssh} -i ${config.age.secrets.${borgId}.path}";
          unknown_unencrypted_repo_access_is_ok = true;
          source_directories = [
            "/home"
            "/persist"
            "/data/container"
            "/data/home"
            "/data/library"
            "/data/photo"
            "/data/share"
            "/data/syncthing"
          ];
          repositories = [
            {
              label = "syno";
              path = "ssh://borg@sv-syno-01.home.local/volume1/borg/hyperion";
            }
          ];
        };
      };

      btrbk.instances = {
        # Remote root state backup to SSH
        root-remote = {
          onCalendar = "hourly";
          settings = {
            snapshot_preserve = "7d 4w 6m 1y";
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
            snapshot_preserve = "7d 4w 6m";
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
    };

    # Btrbk does not create snapshot directories automatically
    systemd.tmpfiles.rules = [
      "d ${snapshotDir} 0755 root root"
      "d /data${snapshotDir} 0755 root root"
    ];
  };
}
