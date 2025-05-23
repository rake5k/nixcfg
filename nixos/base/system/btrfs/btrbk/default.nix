{ config, lib, ... }:

let

  btrfsCfg = config.custom.base.system.btrfs;
  cfg = btrfsCfg.btrbk;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

in

{
  options.custom.base.system.btrfs.btrbk = {
    enable = mkEnableOption "btrbk";

    snapshotDir = mkOption {
      description = "Path to Btrbk's snapshot directory.";
      default = "/snapshots";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    services.btrbk.instances.home = {
      onCalendar = "hourly";
      settings = {
        snapshot_preserve = "7d 4w";
        snapshot_preserve_min = "2d";
        snapshot_dir = cfg.snapshotDir;
        subvolume = "/home";
      };
    };

    # Btrbk does not create snapshot directories automatically
    systemd.tmpfiles.rules = [
      "d ${cfg.snapshotDir} 0755 root root"
    ];
  };
}
