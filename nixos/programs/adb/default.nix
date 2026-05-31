{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.programs.adb;

in

{
  options = {
    custom.programs.adb = {
      enable = mkEnableOption "Android Debug Bridge";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-tools
      signify
    ];
  };
}
