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
    custom.base.system.btrfs.impermanence.extraDirectories = [
      cfg.snapshotDir
    ];

    services.btrbk.instances.home = {
      onCalendar = "hourly";
      settings = {
        snapshot_preserve = "7d 4w";
        snapshot_preserve_min = "2d";
        snapshot_dir = cfg.snapshotDir;
        subvolume = "/home";
      };
    };
  };
}
