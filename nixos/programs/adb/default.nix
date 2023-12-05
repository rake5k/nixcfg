{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.adb;
  baseCfg = config.custom.base;

in

{
  options = {
    custom.programs.adb = {
      enable = mkEnableOption "Android Debug Bridge";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      signify
    ];

    programs.adb.enable = true;

    users.users = genAttrs baseCfg.users (u: { extraGroups = [ "adbusers" ]; });
  };
}
