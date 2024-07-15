{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.android;

in

{
  options = {
    custom.roles.android = {
      enable = mkEnableOption "Android tooling";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.adb.enable = true;
  };
}
