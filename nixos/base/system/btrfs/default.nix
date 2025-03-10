{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.custom.base.system.btrfs;

in

{
  options = {
    custom.base.system.btrfs = {
      enable = mkEnableOption "Enable BTRFS config";
    };
  };

  config = mkIf cfg.enable {
    custom.base.system.btrfs.btrbk.enable = true;

    environment.systemPackages = [ pkgs.compsize ];

    services.btrfs.autoScrub = {
      enable = mkDefault true;
      fileSystems = [ "/" ];
    };
  };
}
