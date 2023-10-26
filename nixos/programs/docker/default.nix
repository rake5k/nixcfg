{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.docker;
  baseCfg = config.custom.base;

in

{
  options = {
    custom.programs.docker = {
      enable = mkEnableOption "Docker";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dive
      docker-compose
      skopeo
    ];

    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
    };

    users.users = genAttrs baseCfg.users (u: { extraGroups = [ "docker" ]; });
  };
}
