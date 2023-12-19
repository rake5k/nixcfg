{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.containers;
  baseCfg = config.custom.base;

in

{
  options = {
    custom.roles.containers = {
      enable = mkEnableOption "Container runtime";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
    };

    users.users = genAttrs baseCfg.users (u: { extraGroups = [ "docker" ]; });
  };
}
